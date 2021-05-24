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
import Html.Events
import Id exposing (GroupId, Id, UserId)
import Json.Decode
import Lamdera
import LoginForm
import Name
import Pixels exposing (Pixels)
import Process
import ProfileForm
import ProfileImage
import Quantity exposing (Quantity)
import Route exposing (Route(..))
import Task
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
        routeAndToken =
            Url.Parser.parse Route.decode url |> Maybe.withDefault ( HomepageRoute, Route.NoToken )
    in
    ( Loading key routeAndToken Nothing Nothing
    , FrontendEffect.batch
        [ FrontendEffect.getTime GotTime
        , FrontendEffect.getWindowSize GotWindowSize
        ]
    )


initLoadedFrontend :
    NavigationKey
    -> Quantity Int Pixels
    -> Quantity Int Pixels
    -> Route
    -> Route.Token
    -> Time.Posix
    -> ( LoadedFrontend, FrontendEffect )
initLoadedFrontend navigationKey windowWidth windowHeight route maybeLoginToken time =
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
            }
    in
    ( model
    , FrontendEffect.batch
        [ FrontendEffect.batch [ FrontendEffect.sendToBackend login, routeRequest route model ]
        , FrontendEffect.navigationReplaceUrl navigationKey (Route.encode route)
        ]
    )


update : FrontendMsg -> FrontendModel -> ( FrontendModel, FrontendEffect )
update msg model =
    case model of
        Loading key ( route, token ) maybeWindowSize maybeTime ->
            case msg of
                GotTime time ->
                    case maybeWindowSize of
                        Just ( windowWidth, windowHeight ) ->
                            initLoadedFrontend key windowWidth windowHeight route token time |> Tuple.mapFirst Loaded

                        Nothing ->
                            ( Loading key ( route, token ) maybeWindowSize (Just time), FrontendEffect.none )

                GotWindowSize width height ->
                    case maybeTime of
                        Just time ->
                            initLoadedFrontend key width height route token time |> Tuple.mapFirst Loaded

                        Nothing ->
                            ( Loading key ( route, token ) (Just ( width, height )) maybeTime, FrontendEffect.none )

                _ ->
                    ( model, FrontendEffect.none )

        Loaded loaded ->
            updateLoaded msg loaded |> Tuple.mapFirst Loaded


routeRequest : Route -> LoadedFrontend -> FrontendEffect
routeRequest route model =
    case route of
        MyGroupsRoute ->
            FrontendEffect.sendToBackend GetMyGroupsRequest

        GroupRoute groupId _ ->
            if Dict.member groupId model.cachedGroups then
                FrontendEffect.none

            else
                FrontendEffect.sendToBackend (GetGroupRequest groupId)

        HomepageRoute ->
            FrontendEffect.none

        AdminRoute ->
            FrontendEffect.none

        CreateGroupRoute ->
            FrontendEffect.none

        MyProfileRoute ->
            FrontendEffect.none

        SearchGroupsRoute searchText ->
            FrontendEffect.sendToBackend (SearchGroupsRequest searchText)


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
            ( { model | route = route }
            , routeRequest route model
            )

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
                    let
                        ( newModel, effects ) =
                            GroupPage.update
                                { none = FrontendEffect.none }
                                groupPageMsg
                                loggedIn.groupPage
                    in
                    ( { model | loginStatus = LoggedIn { loggedIn | groupPage = newModel } }
                    , effects
                    )

                NotLoggedIn _ ->
                    ( model, FrontendEffect.none )

                LoginStatusPending ->
                    ( model, FrontendEffect.none )

        GotWindowSize width height ->
            ( { model | windowWidth = width, windowHeight = height }, FrontendEffect.none )


updateFromBackend : ToFrontend -> FrontendModel -> ( FrontendModel, FrontendEffect )
updateFromBackend msg model =
    case model of
        Loading _ _ _ _ ->
            ( model, FrontendEffect.none )

        Loaded loaded ->
            updateLoadedFromBackend msg loaded |> Tuple.mapFirst Loaded


updateLoadedFromBackend : ToFrontend -> LoadedFrontend -> ( LoadedFrontend, FrontendEffect )
updateLoadedFromBackend msg model =
    case msg of
        GetGroupResponse groupId result ->
            ( { model | cachedGroups = Dict.insert groupId result model.cachedGroups }
            , case result of
                GroupFound groupData ->
                    FrontendEffect.navigationReplaceRoute
                        model.navigationKey
                        (GroupRoute groupId (Group.name groupData))

                GroupNotFoundOrIsPrivate ->
                    FrontendEffect.none
            )

        LoginWithTokenResponse result ->
            case result of
                Ok ( userId, user ) ->
                    ( { model
                        | loginStatus =
                            LoggedIn
                                { userId = userId
                                , user = user
                                , profileForm = ProfileForm.init
                                , myGroups = Nothing
                                , groupPage = GroupPage.init
                                }
                      }
                    , FrontendEffect.none
                    )

                Err () ->
                    ( { model | hasLoginError = True }, FrontendEffect.none )

        CheckLoginResponse loginStatus ->
            ( { model
                | loginStatus =
                    case loginStatus of
                        Just ( userId, user ) ->
                            LoggedIn
                                { userId = userId
                                , user = user
                                , profileForm = ProfileForm.init
                                , myGroups = Nothing
                                , groupPage = GroupPage.init
                                }

                        Nothing ->
                            NotLoggedIn { showLogin = False }
              }
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
                                | cachedGroups = Dict.insert groupId (GroupFound groupData) model.cachedGroups
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
            ( updateUser (\user -> { user | name = name }) model, FrontendEffect.none )

        ChangeDescriptionResponse description ->
            ( updateUser (\user -> { user | description = description }) model, FrontendEffect.none )

        ChangeEmailAddressResponse emailAddress ->
            ( updateUser (\user -> { user | emailAddress = emailAddress }) model, FrontendEffect.none )

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
            ( updateUser (\user -> { user | profileImage = profileImage }) model, FrontendEffect.none )

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


updateUser : (BackendUser -> BackendUser) -> LoadedFrontend -> LoadedFrontend
updateUser updateFunc model =
    case model.loginStatus of
        LoggedIn loggedIn ->
            { model | loginStatus = LoggedIn { loggedIn | user = updateFunc loggedIn.user } }

        NotLoggedIn _ ->
            model

        LoginStatusPending ->
            model


view : FrontendModel -> Browser.Document FrontendMsg
view model =
    { title = "Meetdown"
    , body =
        [ Ui.css
        , Element.layout
            []
            (case model of
                Loading _ _ _ _ ->
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
    case loadedFrontend.loginStatus of
        LoggedIn loggedIn ->
            if loggedIn.userId == userId then
                Types.userToFrontend loggedIn.user |> Just

            else
                Dict.get userId loadedFrontend.cachedUsers

        NotLoggedIn _ ->
            Dict.get userId loadedFrontend.cachedUsers

        LoginStatusPending ->
            Dict.get userId loadedFrontend.cachedUsers


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
                            GroupPage.view model.time
                                owner
                                group
                                (case model.loginStatus of
                                    LoggedIn loggedIn ->
                                        Just loggedIn.groupPage

                                    NotLoggedIn _ ->
                                        Nothing

                                    LoginStatusPending ->
                                        Nothing
                                )
                                |> Element.map GroupPageMsg

                        Nothing ->
                            Element.text "Loading group"

                Just GroupNotFoundOrIsPrivate ->
                    Element.text "Group not found or it is private"

                Nothing ->
                    Element.text "Loading group"

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
                    ProfileForm.view model loggedIn.user loggedIn.profileForm
                        |> Element.el
                            [ Element.width <| Element.maximum 800 Element.fill
                            , Element.centerX
                            ]
                        |> Element.map ProfileFormMsg
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

                            GroupNotFoundOrIsPrivate ->
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
