module Frontend exposing (app, init, update, updateFromBackend, view)

import AssocList as Dict
import AssocSet as Set
import Browser exposing (UrlRequest(..))
import Browser.Events
import CreateGroupForm
import Description
import Element exposing (Element)
import Element.Background
import Element.Border
import Element.Font
import Element.Input
import Element.Region
import FrontendEffect exposing (FrontendEffect)
import FrontendUser exposing (FrontendUser)
import Group exposing (Group)
import GroupName
import GroupPage
import Id exposing (GroupId, Id, UserId)
import Lamdera
import LoginForm
import Pixels exposing (Pixels)
import ProfileForm
import ProfileImage
import Quantity exposing (Quantity)
import Route exposing (Route(..))
import Time
import Types exposing (..)
import Ui
import Untrusted
import Url exposing (Url)
import Url.Parser exposing ((</>))


app =
    Lamdera.frontend
        { init = \url key -> init url (RealNavigationKey key) |> Tuple.mapSecond FrontendEffect.toCmd
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = \msg model -> update msg model |> Tuple.mapSecond FrontendEffect.toCmd
        , updateFromBackend = \msg model -> updateFromBackend msg model |> Tuple.mapSecond FrontendEffect.toCmd
        , subscriptions =
            \_ ->
                Sub.batch
                    [ FrontendEffect.martinsstewart_crop_image_from_js CroppedImage
                    , Browser.Events.onResize
                        (\width height -> GotWindowSize (Pixels.pixels width) (Pixels.pixels height))
                    ]
        , view = view
        }


init : Url -> NavigationKey -> ( FrontendModel, FrontendEffect )
init url key =
    let
        ( route, token ) =
            Url.Parser.parse Route.decode url |> Maybe.withDefault ( HomepageRoute, Route.NoToken )
    in
    ( Loading
        { navigationKey = key
        , route = route
        , routeToken = token
        , windowSize = Nothing
        , time = Nothing
        , timezone = Nothing
        }
    , FrontendEffect.batch
        [ FrontendEffect.getTime GotTime
        , FrontendEffect.getWindowSize GotWindowSize
        , FrontendEffect.getTimeZone GotTimeZone
        ]
    )


initLoadedFrontend :
    NavigationKey
    -> Quantity Int Pixels
    -> Quantity Int Pixels
    -> Route
    -> Route.Token
    -> Time.Posix
    -> Time.Zone
    -> ( LoadedFrontend, FrontendEffect )
initLoadedFrontend navigationKey windowWidth windowHeight route maybeLoginToken time timezone =
    let
        login =
            case maybeLoginToken of
                Route.LoginToken loginToken ->
                    LoginWithTokenRequest loginToken

                Route.DeleteUserToken deleteUserToken ->
                    DeleteUserRequest deleteUserToken

                Route.NoToken ->
                    CheckLoginRequest

        model : LoadedFrontend
        model =
            { navigationKey = navigationKey
            , loginStatus = LoginStatusPending
            , route = route
            , cachedGroups = Dict.empty
            , cachedUsers = Dict.empty
            , time = time
            , timezone = timezone
            , lastConnectionCheck = time
            , loginForm =
                { email = ""
                , pressedSubmitEmail = False
                , emailSent = Nothing
                }
            , logs = Nothing
            , hasLoginError = False
            , groupForm = CreateGroupForm.init
            , groupCreated = False
            , accountDeletedResult = Nothing
            , searchBox = ""
            , searchList = []
            , windowWidth = windowWidth
            , windowHeight = windowHeight
            , groupPage = Dict.empty
            }

        ( model2, cmd ) =
            routeRequest route model
    in
    ( model2
    , FrontendEffect.batch
        [ FrontendEffect.batch [ FrontendEffect.sendToBackend login, cmd ]
        , FrontendEffect.navigationReplaceUrl navigationKey (Route.encode route)
        ]
    )


tryInitLoadedFrontend : LoadingFrontend -> ( FrontendModel, FrontendEffect )
tryInitLoadedFrontend loading =
    Maybe.map3
        (\( windowWidth, windowHeight ) time zone ->
            initLoadedFrontend
                loading.navigationKey
                windowWidth
                windowHeight
                loading.route
                loading.routeToken
                time
                zone
                |> Tuple.mapFirst Loaded
        )
        loading.windowSize
        loading.time
        loading.timezone
        |> Maybe.withDefault ( Loading loading, FrontendEffect.none )


gotTimeZone : Result error ( a, Time.Zone ) -> { b | timezone : Maybe Time.Zone } -> { b | timezone : Maybe Time.Zone }
gotTimeZone result model =
    case result of
        Ok ( _, timezone ) ->
            { model | timezone = Just timezone }

        Err _ ->
            { model | timezone = Just Time.utc }


update : FrontendMsg -> FrontendModel -> ( FrontendModel, FrontendEffect )
update msg model =
    case model of
        Loading loading ->
            case msg of
                GotTime time ->
                    tryInitLoadedFrontend { loading | time = Just time }

                GotWindowSize width height ->
                    tryInitLoadedFrontend { loading | windowSize = Just ( width, height ) }

                GotTimeZone result ->
                    gotTimeZone result loading |> tryInitLoadedFrontend

                _ ->
                    ( model, FrontendEffect.none )

        Loaded loaded ->
            updateLoaded msg loaded |> Tuple.mapFirst Loaded


routeRequest : Route -> LoadedFrontend -> ( LoadedFrontend, FrontendEffect )
routeRequest route model =
    case route of
        MyGroupsRoute ->
            ( model, FrontendEffect.sendToBackend GetMyGroupsRequest )

        GroupRoute groupId _ ->
            if Dict.member groupId model.cachedGroups then
                ( model, FrontendEffect.none )

            else
                ( { model | cachedGroups = Dict.insert groupId GroupRequestPending model.cachedGroups }
                , FrontendEffect.sendToBackend (GetGroupRequest groupId)
                )

        HomepageRoute ->
            ( model, FrontendEffect.none )

        AdminRoute ->
            ( model, FrontendEffect.none )

        CreateGroupRoute ->
            ( model, FrontendEffect.none )

        MyProfileRoute ->
            ( model, FrontendEffect.none )

        SearchGroupsRoute searchText ->
            ( model, FrontendEffect.sendToBackend (SearchGroupsRequest searchText) )


updateLoaded : FrontendMsg -> LoadedFrontend -> ( LoadedFrontend, FrontendEffect )
updateLoaded msg model =
    case msg of
        UrlClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    let
                        route =
                            Url.Parser.parse Route.decode url
                                |> Maybe.map Tuple.first
                                |> Maybe.withDefault HomepageRoute
                    in
                    ( { model | route = route }
                    , FrontendEffect.navigationPushUrl model.navigationKey (Route.encode route)
                    )

                External url ->
                    ( model, FrontendEffect.navigationLoad url )

        UrlChanged url ->
            let
                route =
                    Url.Parser.parse Route.decode url
                        |> Maybe.map Tuple.first
                        |> Maybe.withDefault HomepageRoute
            in
            routeRequest route { model | route = route }

        GotTime time ->
            ( { model | time = time }, FrontendEffect.none )

        PressedLogin ->
            case model.loginStatus of
                LoginStatusPending ->
                    ( model, FrontendEffect.none )

                NotLoggedIn notLoggedIn ->
                    ( { model | loginStatus = NotLoggedIn { notLoggedIn | showLogin = True } }, FrontendEffect.none )

                LoggedIn _ ->
                    ( model, FrontendEffect.none )

        PressedLogout ->
            ( { model | loginStatus = NotLoggedIn { showLogin = False } }
            , FrontendEffect.sendToBackend LogoutRequest
            )

        TypedEmail text ->
            ( { model | loginForm = LoginForm.typedEmail text model.loginForm }, FrontendEffect.none )

        PressedSubmitEmail ->
            LoginForm.submitForm model.route model.loginForm
                |> Tuple.mapFirst (\a -> { model | loginForm = a })

        PressedCreateGroup ->
            ( model, FrontendEffect.navigationPushRoute model.navigationKey CreateGroupRoute )

        GroupFormMsg groupFormMsg ->
            let
                ( newModel, outMsg ) =
                    CreateGroupForm.update groupFormMsg model.groupForm
                        |> Tuple.mapFirst (\a -> { model | groupForm = a })
            in
            case outMsg of
                CreateGroupForm.Submitted submitted ->
                    ( newModel
                    , CreateGroupRequest
                        (Untrusted.untrust submitted.name)
                        (Untrusted.untrust submitted.description)
                        submitted.visibility
                        |> FrontendEffect.sendToBackend
                    )

                CreateGroupForm.NoChange ->
                    ( newModel, FrontendEffect.none )

        ProfileFormMsg profileFormMsg ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    let
                        ( newModel, effects ) =
                            ProfileForm.update
                                model
                                { wait = \duration waitMsg -> FrontendEffect.wait duration (ProfileFormMsg waitMsg)
                                , none = FrontendEffect.none
                                , changeName = ChangeNameRequest >> FrontendEffect.sendToBackend
                                , changeDescription = ChangeDescriptionRequest >> FrontendEffect.sendToBackend
                                , changeEmailAddress = ChangeEmailAddressRequest >> FrontendEffect.sendToBackend
                                , selectFile =
                                    \mimeTypes fileMsg ->
                                        FrontendEffect.selectFile mimeTypes (fileMsg >> ProfileFormMsg)
                                , getFileContents =
                                    \fileMsg file -> FrontendEffect.fileToBytes (fileMsg >> ProfileFormMsg) file
                                , setCanvasImage = FrontendEffect.cropImage
                                , sendDeleteAccountEmail = FrontendEffect.sendToBackend SendDeleteUserEmailRequest
                                , getElement =
                                    \getElementMsg id -> FrontendEffect.getElement (getElementMsg >> ProfileFormMsg) id
                                , batch = FrontendEffect.batch
                                }
                                profileFormMsg
                                loggedIn.profileForm
                    in
                    ( { model | loginStatus = LoggedIn { loggedIn | profileForm = newModel } }
                    , effects
                    )

                NotLoggedIn _ ->
                    ( model, FrontendEffect.none )

                LoginStatusPending ->
                    ( model, FrontendEffect.none )

        CroppedImage imageData ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    case ProfileImage.customImage imageData.croppedImageUrl of
                        Ok profileImage ->
                            let
                                newModel =
                                    ProfileForm.cropImageResponse imageData loggedIn.profileForm
                            in
                            ( { model | loginStatus = LoggedIn { loggedIn | profileForm = newModel } }
                            , Untrusted.untrust profileImage
                                |> ChangeProfileImageRequest
                                |> FrontendEffect.sendToBackend
                            )

                        Err _ ->
                            ( model, FrontendEffect.none )

                NotLoggedIn _ ->
                    ( model, FrontendEffect.none )

                LoginStatusPending ->
                    ( model, FrontendEffect.none )

        TypedSearchText searchText ->
            ( { model | searchBox = searchText }, FrontendEffect.none )

        SubmittedSearchBox ->
            ( model, FrontendEffect.navigationPushRoute model.navigationKey (SearchGroupsRoute model.searchBox) )

        GroupPageMsg groupPageMsg ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    case model.route of
                        GroupRoute groupId _ ->
                            case Dict.get groupId model.cachedGroups of
                                Just (GroupFound group) ->
                                    let
                                        ( newModel, effects ) =
                                            GroupPage.update
                                                { none = FrontendEffect.none
                                                , changeName =
                                                    ChangeGroupNameRequest groupId >> FrontendEffect.sendToBackend
                                                , changeDescription =
                                                    ChangeGroupDescriptionRequest groupId >> FrontendEffect.sendToBackend
                                                , createEvent =
                                                    \a b c d e -> CreateEventRequest groupId a b c d e |> FrontendEffect.sendToBackend
                                                }
                                                model
                                                group
                                                loggedIn.userId
                                                groupPageMsg
                                                (Dict.get groupId model.groupPage |> Maybe.withDefault GroupPage.init)
                                    in
                                    ( { model | groupPage = Dict.insert groupId newModel model.groupPage }, effects )

                                _ ->
                                    ( model, FrontendEffect.none )

                        _ ->
                            ( model, FrontendEffect.none )

                NotLoggedIn _ ->
                    ( model, FrontendEffect.none )

                LoginStatusPending ->
                    ( model, FrontendEffect.none )

        GotWindowSize width height ->
            ( { model | windowWidth = width, windowHeight = height }, FrontendEffect.none )

        GotTimeZone _ ->
            ( model, FrontendEffect.none )


updateFromBackend : ToFrontend -> FrontendModel -> ( FrontendModel, FrontendEffect )
updateFromBackend msg model =
    case model of
        Loading _ ->
            ( model, FrontendEffect.none )

        Loaded loaded ->
            updateLoadedFromBackend msg loaded |> Tuple.mapFirst Loaded


updateLoadedFromBackend : ToFrontend -> LoadedFrontend -> ( LoadedFrontend, FrontendEffect )
updateLoadedFromBackend msg model =
    case msg of
        GetGroupResponse groupId result ->
            ( { model
                | cachedGroups =
                    Dict.insert groupId
                        (case result of
                            GroupFound_ group _ ->
                                GroupFound group

                            GroupNotFound_ ->
                                GroupNotFound
                        )
                        model.cachedGroups
                , cachedUsers =
                    case result of
                        GroupFound_ _ users ->
                            Dict.union users model.cachedUsers

                        GroupNotFound_ ->
                            model.cachedUsers
              }
            , case result of
                GroupFound_ groupData _ ->
                    FrontendEffect.navigationReplaceRoute
                        model.navigationKey
                        (GroupRoute groupId (Group.name groupData))

                GroupNotFound_ ->
                    FrontendEffect.none
            )

        LoginWithTokenResponse result ->
            case result of
                Ok ( userId, user ) ->
                    ( { model
                        | loginStatus =
                            LoggedIn
                                { userId = userId
                                , emailAddress = user.emailAddress
                                , profileForm = ProfileForm.init
                                , myGroups = Nothing
                                }
                        , cachedUsers = Dict.insert userId (userToFrontend user) model.cachedUsers
                      }
                    , FrontendEffect.none
                    )

                Err () ->
                    ( { model | hasLoginError = True }, FrontendEffect.none )

        CheckLoginResponse loginStatus ->
            case loginStatus of
                Just ( userId, user ) ->
                    ( { model
                        | loginStatus =
                            LoggedIn
                                { userId = userId
                                , emailAddress = user.emailAddress
                                , profileForm = ProfileForm.init
                                , myGroups = Nothing
                                }
                        , cachedUsers = Dict.insert userId (userToFrontend user) model.cachedUsers
                      }
                    , FrontendEffect.none
                    )

                Nothing ->
                    ( { model | loginStatus = NotLoggedIn { showLogin = False } }
                    , FrontendEffect.none
                    )

        GetAdminDataResponse logs ->
            ( { model | logs = Just logs }, FrontendEffect.none )

        CreateGroupResponse result ->
            case model.loginStatus of
                LoggedIn _ ->
                    case result of
                        Ok ( groupId, groupData ) ->
                            ( { model
                                | cachedGroups =
                                    Dict.insert groupId (GroupFound groupData) model.cachedGroups
                                , groupForm = CreateGroupForm.init
                              }
                            , FrontendEffect.navigationReplaceRoute
                                model.navigationKey
                                (GroupRoute groupId (Group.name groupData))
                            )

                        Err error ->
                            ( { model | groupForm = CreateGroupForm.submitFailed error model.groupForm }
                            , FrontendEffect.none
                            )

                NotLoggedIn _ ->
                    ( model, FrontendEffect.none )

                LoginStatusPending ->
                    ( model, FrontendEffect.none )

        LogoutResponse ->
            ( { model | loginStatus = NotLoggedIn { showLogin = False } }, FrontendEffect.none )

        ChangeNameResponse name ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    ( { model
                        | cachedUsers =
                            Dict.update loggedIn.userId (Maybe.map (\a -> { a | name = name })) model.cachedUsers
                      }
                    , FrontendEffect.none
                    )

                LoginStatusPending ->
                    ( model, FrontendEffect.none )

                NotLoggedIn _ ->
                    ( model, FrontendEffect.none )

        ChangeDescriptionResponse description ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    ( { model
                        | cachedUsers =
                            Dict.update
                                loggedIn.userId
                                (Maybe.map (\a -> { a | description = description }))
                                model.cachedUsers
                      }
                    , FrontendEffect.none
                    )

                LoginStatusPending ->
                    ( model, FrontendEffect.none )

                NotLoggedIn _ ->
                    ( model, FrontendEffect.none )

        ChangeEmailAddressResponse emailAddress ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    ( { model | loginStatus = LoggedIn { loggedIn | emailAddress = emailAddress } }
                    , FrontendEffect.none
                    )

                LoginStatusPending ->
                    ( model, FrontendEffect.none )

                NotLoggedIn _ ->
                    ( model, FrontendEffect.none )

        DeleteUserResponse result ->
            case result of
                Ok () ->
                    ( { model
                        | loginStatus = NotLoggedIn { showLogin = False }
                        , accountDeletedResult = Just result
                      }
                    , FrontendEffect.none
                    )

                Err () ->
                    ( { model | accountDeletedResult = Just result }, FrontendEffect.none )

        ChangeProfileImageResponse profileImage ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    ( { model
                        | cachedUsers =
                            Dict.update
                                loggedIn.userId
                                (Maybe.map (\a -> { a | profileImage = profileImage }))
                                model.cachedUsers
                      }
                    , FrontendEffect.none
                    )

                LoginStatusPending ->
                    ( model, FrontendEffect.none )

                NotLoggedIn _ ->
                    ( model, FrontendEffect.none )

        GetMyGroupsResponse myGroups ->
            ( case model.loginStatus of
                LoggedIn loggedIn ->
                    { model
                        | loginStatus =
                            LoggedIn { loggedIn | myGroups = List.map Tuple.first myGroups |> Set.fromList |> Just }
                        , cachedGroups =
                            List.foldl
                                (\( groupId, group ) cached ->
                                    Dict.insert groupId (GroupFound group) cached
                                )
                                model.cachedGroups
                                myGroups
                    }

                NotLoggedIn _ ->
                    model

                LoginStatusPending ->
                    model
            , FrontendEffect.none
            )

        SearchGroupsResponse _ groups ->
            ( { model
                | cachedGroups =
                    List.foldl
                        (\( groupId, group ) cached ->
                            Dict.insert groupId (GroupFound group) cached
                        )
                        model.cachedGroups
                        groups
                , searchList = List.map Tuple.first groups
              }
            , FrontendEffect.none
            )

        ChangeGroupNameResponse groupId groupName ->
            ( { model
                | cachedGroups =
                    Dict.update groupId
                        (Maybe.map
                            (\a ->
                                case a of
                                    GroupFound group ->
                                        Group.withName groupName group |> GroupFound

                                    GroupNotFound ->
                                        GroupNotFound

                                    GroupRequestPending ->
                                        GroupRequestPending
                            )
                        )
                        model.cachedGroups
                , groupPage = Dict.update groupId (Maybe.map GroupPage.savedName) model.groupPage
              }
            , FrontendEffect.none
            )

        ChangeGroupDescriptionResponse groupId description ->
            ( { model
                | cachedGroups =
                    Dict.update groupId
                        (Maybe.map
                            (\a ->
                                case a of
                                    GroupFound group ->
                                        Group.withDescription description group |> GroupFound

                                    GroupNotFound ->
                                        GroupNotFound

                                    GroupRequestPending ->
                                        GroupRequestPending
                            )
                        )
                        model.cachedGroups
                , groupPage = Dict.update groupId (Maybe.map GroupPage.savedDescription) model.groupPage
              }
            , FrontendEffect.none
            )

        CreateEventResponse groupId result ->
            ( { model
                | cachedGroups =
                    case result of
                        Ok event ->
                            Dict.update groupId
                                (Maybe.map
                                    (\a ->
                                        case a of
                                            GroupFound group ->
                                                Group.addEvent event group
                                                    |> Result.withDefault group
                                                    |> GroupFound

                                            GroupNotFound ->
                                                GroupNotFound

                                            GroupRequestPending ->
                                                GroupRequestPending
                                    )
                                )
                                model.cachedGroups

                        Err _ ->
                            model.cachedGroups
                , groupPage = Dict.update groupId (Maybe.map (GroupPage.addedNewEvent result)) model.groupPage
              }
            , FrontendEffect.none
            )


view : FrontendModel -> Browser.Document FrontendMsg
view model =
    { title = "Meetdown"
    , body =
        [ Ui.css
        , Element.layout
            []
            (case model of
                Loading _ ->
                    Element.none

                Loaded loaded ->
                    viewLoaded loaded
            )
        ]
    }


viewLoaded : LoadedFrontend -> Element FrontendMsg
viewLoaded model =
    Element.column
        [ Element.width Element.fill
        , Element.height Element.fill
        , Element.inFront
            (if model.hasLoginError then
                Element.el
                    [ Element.width Element.fill
                    , Element.height Element.fill
                    , Element.Background.color <| Element.rgb 1 1 1
                    ]
                    (Element.text "Sorry, the link you used is either invalid or has expired.")

             else
                Element.none
            )
        ]
        [ case model.loginStatus of
            LoginStatusPending ->
                Element.none

            _ ->
                header (isLoggedIn model) model.route model.searchBox
        , case model.loginStatus of
            NotLoggedIn { showLogin } ->
                if showLogin then
                    LoginForm.view model.loginForm

                else
                    viewPage model

            LoggedIn _ ->
                viewPage model

            LoginStatusPending ->
                Element.none
        ]


loginRequiredPage : LoadedFrontend -> (LoggedIn_ -> Element FrontendMsg) -> Element FrontendMsg
loginRequiredPage model pageView =
    case model.loginStatus of
        LoggedIn loggedIn ->
            pageView loggedIn

        NotLoggedIn _ ->
            LoginForm.view model.loginForm

        LoginStatusPending ->
            Element.none


getCachedUser : Id UserId -> LoadedFrontend -> Maybe FrontendUser
getCachedUser userId loadedFrontend =
    case Dict.get userId loadedFrontend.cachedUsers of
        Just user ->
            Just user

        Nothing ->
            Nothing


viewPage : LoadedFrontend -> Element FrontendMsg
viewPage model =
    case model.route of
        HomepageRoute ->
            Element.paragraph
                [ Element.padding 8 ]
                [ Element.text "A place to find people with shared interests. We don't sell your data, we don't show ads, we don't charge money, and it's all open source." ]

        GroupRoute groupId _ ->
            case Dict.get groupId model.cachedGroups of
                Just (GroupFound group) ->
                    case getCachedUser (Group.ownerId group) model of
                        Just owner ->
                            GroupPage.view
                                model.time
                                model.timezone
                                owner
                                group
                                (Dict.get groupId model.groupPage |> Maybe.withDefault GroupPage.init)
                                (case model.loginStatus of
                                    LoggedIn loggedIn ->
                                        Just loggedIn.userId

                                    NotLoggedIn _ ->
                                        Nothing

                                    LoginStatusPending ->
                                        Nothing
                                )
                                |> Element.map GroupPageMsg

                        Nothing ->
                            Element.text "Error loading group owner"

                Just GroupNotFound ->
                    Element.text "Group not found"

                Just GroupRequestPending ->
                    Element.text "Loading group"

                Nothing ->
                    Element.none

        AdminRoute ->
            loginRequiredPage
                model
                (\_ -> Element.text "Admin panel")

        CreateGroupRoute ->
            loginRequiredPage
                model
                (\_ ->
                    CreateGroupForm.view model.groupForm
                        |> Element.el
                            [ Element.width <| Element.maximum 800 Element.fill
                            , Element.centerX
                            ]
                        |> Element.map GroupFormMsg
                )

        MyGroupsRoute ->
            loginRequiredPage model (myGroupsView model)

        MyProfileRoute ->
            loginRequiredPage
                model
                (\loggedIn ->
                    case Dict.get loggedIn.userId model.cachedUsers of
                        Just user ->
                            ProfileForm.view
                                model
                                { name = user.name
                                , description = user.description
                                , emailAddress = loggedIn.emailAddress
                                , profileImage = user.profileImage
                                }
                                loggedIn.profileForm
                                |> Element.el
                                    [ Element.width <| Element.maximum 800 Element.fill
                                    , Element.centerX
                                    ]
                                |> Element.map ProfileFormMsg

                        Nothing ->
                            Element.text "Failed to find user"
                )

        SearchGroupsRoute searchText ->
            searchGroupsView searchText model


searchGroupsView : String -> LoadedFrontend -> Element FrontendMsg
searchGroupsView searchText model =
    Element.column
        [ Element.padding 8
        , Element.width <| Element.maximum 800 Element.fill
        , Element.centerX
        , Element.spacing 8
        ]
        [ if searchText == "" then
            Element.none

          else
            Element.paragraph [] [ Element.text <| "Search results for \"" ++ searchText ++ "\"" ]
        , Element.column
            [ Element.width Element.fill, Element.spacing 8 ]
            (getGroupsFromIds model.searchList model
                |> List.map
                    (\( groupId, group ) ->
                        Element.link
                            [ Ui.inputBackground False
                            , Element.Border.rounded 4
                            , Element.Border.width 2
                            , Element.Border.color Ui.linkColor
                            , Element.padding 8
                            , Element.width Element.fill
                            , Ui.inputFocusClass
                            ]
                            { url = Route.encode (GroupRoute groupId (Group.name group))
                            , label =
                                Element.column
                                    [ Element.width Element.fill, Element.spacing 8 ]
                                    [ Group.name group
                                        |> GroupName.toString
                                        |> Element.text
                                        |> List.singleton
                                        |> Element.paragraph [ Element.Font.bold ]
                                    , Group.description group
                                        |> Description.toString
                                        |> Element.text
                                        |> List.singleton
                                        |> Element.paragraph []
                                    ]
                            }
                    )
            )
        ]


getGroupsFromIds : List GroupId -> LoadedFrontend -> List ( GroupId, Group )
getGroupsFromIds groups model =
    List.filterMap
        (\groupId ->
            Dict.get groupId model.cachedGroups
                |> Maybe.andThen
                    (\group ->
                        case group of
                            GroupFound groupFound ->
                                Just ( groupId, groupFound )

                            GroupNotFound ->
                                Nothing

                            GroupRequestPending ->
                                Nothing
                    )
        )
        groups


myGroupsView : LoadedFrontend -> LoggedIn_ -> Element FrontendMsg
myGroupsView model loggedIn =
    case loggedIn.myGroups of
        Just myGroups ->
            let
                myGroupsList =
                    getGroupsFromIds (Set.toList myGroups) model
                        |> List.map
                            (\( groupId, group ) ->
                                Element.row
                                    []
                                    [ Ui.routeLink
                                        (GroupRoute groupId (Group.name group))
                                        (Group.name group |> GroupName.toString)
                                    ]
                            )

                mySubscriptionsList =
                    []
            in
            Element.column
                [ Element.padding 8, Element.width Element.fill, Element.spacing 8 ]
                [ Ui.title "My groups"
                , if List.isEmpty myGroupsList && List.isEmpty mySubscriptionsList then
                    Element.paragraph
                        []
                        [ Element.text "You don't have any groups. Get started by "
                        , Ui.routeLink CreateGroupRoute "creating one"
                        , Element.text " or "
                        , Ui.routeLink (SearchGroupsRoute "") "joining one."
                        ]

                  else
                    Element.column
                        [ Element.width Element.fill, Element.spacing 8 ]
                        [ Ui.section "Groups I created"
                            (if List.isEmpty myGroupsList then
                                Element.paragraph []
                                    [ Element.text "You haven't created any groups. "
                                    , Ui.routeLink CreateGroupRoute "You can do that here."
                                    ]

                             else
                                Element.column [ Element.spacing 8 ] myGroupsList
                            )
                        , Ui.section "Groups I've joined"
                            (if List.isEmpty mySubscriptionsList then
                                Element.paragraph []
                                    [ Element.text "You haven't joined any groups. "
                                    , Ui.routeLink (SearchGroupsRoute "") "You can do that here."
                                    ]

                             else
                                Element.column [ Element.spacing 8 ] []
                            )
                        ]
                ]

        Nothing ->
            Element.paragraph [] [ Element.text "Loading..." ]


isLoggedIn : LoadedFrontend -> Bool
isLoggedIn model =
    case model.loginStatus of
        LoggedIn _ ->
            True

        NotLoggedIn _ ->
            False

        LoginStatusPending ->
            False


header : Bool -> Route -> String -> Element FrontendMsg
header isLoggedIn_ route searchText =
    Element.row
        [ Element.width Element.fill
        , Element.Background.color <| Element.rgb 0.8 0.8 0.8
        , Element.paddingEach { left = 4, right = 0, top = 0, bottom = 0 }
        ]
        [ Element.Input.text
            [ Element.width <| Element.maximum 400 Element.fill
            , Element.paddingEach { left = 32, right = 8, top = 4, bottom = 4 }
            , Ui.onEnter SubmittedSearchBox
            , Element.inFront
                (Element.el
                    [ Element.Font.size 16
                    , Element.moveDown 6
                    , Element.moveRight 4
                    , Element.alpha 0.8
                    ]
                    (Element.text "🔍")
                )
            ]
            { text = searchText
            , onChange = TypedSearchText
            , placeholder = Nothing
            , label = Element.Input.labelHidden "Search groups"
            }
        , Element.row
            [ Element.alignRight, Element.Region.navigation ]
            (if isLoggedIn_ then
                [ if route == CreateGroupRoute then
                    Element.none

                  else
                    Ui.headerLink
                        { route = CreateGroupRoute
                        , label = "Create group"
                        }
                , if route == MyGroupsRoute then
                    Element.none

                  else
                    Ui.headerLink
                        { route = MyGroupsRoute
                        , label = "My groups"
                        }
                , if route == MyProfileRoute then
                    Element.none

                  else
                    Ui.headerLink
                        { route = MyProfileRoute
                        , label = "Profile"
                        }
                , Ui.headerButton
                    { onPress = PressedLogout
                    , label = "Log out"
                    }
                ]

             else
                [ Ui.headerButton
                    { onPress = PressedLogin
                    , label = "Sign up/Login"
                    }
                ]
            )
        ]
