module Frontend exposing (app, init, update, updateFromBackend, view)

import AssocList as Dict
import Browser exposing (UrlRequest(..))
import Description
import Element exposing (Element)
import Element.Background
import Element.Border
import Element.Font
import Element.Region
import FrontendEffect exposing (FrontendEffect)
import FrontendGroup
import GroupForm
import GroupName
import Lamdera
import LoginForm
import Name
import ProfileForm
import ProfileImage
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
        , subscriptions = \_ -> FrontendEffect.martinsstewart_crop_image_from_js CroppedImage
        , view = view
        }


init : Url -> NavigationKey -> ( FrontendModel, FrontendEffect )
init url key =
    ( Url.Parser.parse Route.decode url |> Maybe.withDefault ( HomepageRoute, Route.NoToken ) |> Loading key
    , FrontendEffect.getTime GotTime
    )


initLoadedFrontend :
    NavigationKey
    -> Route
    -> Route.Token
    -> Time.Posix
    -> ( LoadedFrontend, FrontendEffect )
initLoadedFrontend navigationKey route maybeLoginToken time =
    let
        login =
            case maybeLoginToken of
                Route.LoginToken loginToken ->
                    LoginWithTokenRequest loginToken

                Route.DeleteUserToken deleteUserToken ->
                    DeleteUserRequest deleteUserToken

                Route.NoToken ->
                    CheckLoginRequest
    in
    ( { navigationKey = navigationKey
      , loginStatus = LoginStatusPending
      , route = route
      , cachedGroups = Dict.empty
      , time = time
      , lastConnectionCheck = time
      , loginForm =
            { email = ""
            , pressedSubmitEmail = False
            , emailSent = Nothing
            }
      , logs = Nothing
      , hasLoginError = False
      , groupForm = GroupForm.init
      , groupCreated = False
      , accountDeletedResult = Nothing
      }
    , FrontendEffect.batch
        [ FrontendEffect.manyToBackend login
            (case route of
                HomepageRoute ->
                    []

                GroupRoute groupId _ ->
                    [ GetGroupRequest groupId ]

                AdminRoute ->
                    [ GetAdminDataRequest ]

                CreateGroupRoute ->
                    []

                MyGroupsRoute ->
                    []

                MyProfileRoute ->
                    []
            )
        , FrontendEffect.navigationReplaceUrl navigationKey (Route.encode route Route.NoToken)
        ]
    )


update : FrontendMsg -> FrontendModel -> ( FrontendModel, FrontendEffect )
update msg model =
    case model of
        Loading key ( route, token ) ->
            case msg of
                GotTime time ->
                    initLoadedFrontend key route token time |> Tuple.mapFirst Loaded

                _ ->
                    ( model, FrontendEffect.none )

        Loaded loaded ->
            updateLoaded msg loaded |> Tuple.mapFirst Loaded


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
                    , FrontendEffect.navigationPushUrl model.navigationKey (Route.encode route Route.NoToken)
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
            , FrontendEffect.none
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

        PressedMyGroups ->
            ( model
            , FrontendEffect.batch
                [ FrontendEffect.sendToBackend GetMyGroupsRequest
                , FrontendEffect.navigationPushRoute model.navigationKey MyGroupsRoute
                ]
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
                    GroupForm.update groupFormMsg model.groupForm
                        |> Tuple.mapFirst (\a -> { model | groupForm = a })
            in
            case outMsg of
                GroupForm.Submitted submitted ->
                    ( newModel
                    , CreateGroupRequest
                        (Untrusted.untrust submitted.name)
                        (Untrusted.untrust submitted.description)
                        submitted.visibility
                        |> FrontendEffect.sendToBackend
                    )

                GroupForm.NoChange ->
                    ( newModel, FrontendEffect.none )

        PressedMyProfile ->
            ( model, FrontendEffect.navigationPushRoute model.navigationKey MyProfileRoute )

        ProfileFormMsg profileFormMsg ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    let
                        ( newModel, effects ) =
                            ProfileForm.update
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
                                    \getElementMsg id ->
                                        FrontendEffect.getElement (getElementMsg >> ProfileFormMsg) id
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


updateFromBackend : ToFrontend -> FrontendModel -> ( FrontendModel, FrontendEffect )
updateFromBackend msg model =
    case model of
        Loading _ _ ->
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
                        (GroupRoute groupId (FrontendGroup.name groupData))

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
                LoggedIn loggedIn ->
                    case result of
                        Ok ( groupId, groupData ) ->
                            ( { model
                                | cachedGroups =
                                    Dict.insert
                                        groupId
                                        (Types.groupToFrontend loggedIn.user groupData |> GroupFound)
                                        model.cachedGroups
                                , groupForm = GroupForm.init
                              }
                            , FrontendEffect.navigationPushRoute model.navigationKey (GroupRoute groupId groupData.name)
                            )

                        Err error ->
                            ( { model | groupForm = GroupForm.submitFailed error model.groupForm }
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
                    ( { model | accountDeletedResult = Just result }
                    , FrontendEffect.none
                    )

        ChangeProfileImageResponse profileImage ->
            ( updateUser (\user -> { user | profileImage = profileImage }) model, FrontendEffect.none )

        GetMyGroupsResponse myGroups ->
            ( case model.loginStatus of
                LoggedIn loggedIn ->
                    { model | loginStatus = LoggedIn { loggedIn | myGroups = Just (Dict.fromList myGroups) } }

                NotLoggedIn _ ->
                    model

                LoginStatusPending ->
                    model
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
        [ Element.layout
            []
            (case model of
                Loading _ _ ->
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
                header (isLoggedIn model) model.route
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
                    let
                        section title content =
                            Element.column
                                [ Element.spacing 8
                                , Element.padding 8
                                , Element.Border.rounded 4
                                , Ui.inputBackground False
                                ]
                                [ Element.paragraph [ Element.Font.bold ] [ Element.text title ]
                                , content
                                ]

                        { pastEvents, futureEvents } =
                            FrontendGroup.events model.time group
                    in
                    Element.column
                        [ Element.spacing 8, Element.padding 8, Element.width Element.fill ]
                        [ Element.row
                            [ Element.width Element.fill ]
                            [ group
                                |> FrontendGroup.name
                                |> GroupName.toString
                                |> Ui.title
                                |> Element.el [ Element.alignTop, Element.width Element.fill ]
                            , section "Organizer"
                                (Element.row
                                    [ Element.spacing 16 ]
                                    [ ProfileImage.smallImage (FrontendGroup.owner group).profileImage
                                    , Element.text (Name.toString (FrontendGroup.owner group).name)
                                    ]
                                )
                            ]
                        , section "Description"
                            (if Description.toString (FrontendGroup.description group) == "" then
                                Element.paragraph
                                    [ Element.Font.color <| Element.rgb 0.45 0.45 0.45
                                    , Element.Font.italic
                                    ]
                                    [ Element.text "No description provided" ]

                             else
                                Element.paragraph
                                    []
                                    [ group
                                        |> FrontendGroup.description
                                        |> Description.toString
                                        |> Element.text
                                    ]
                            )
                        , case futureEvents of
                            nextEvent :: _ ->
                                section "Next event"
                                    (Element.paragraph
                                        []
                                        [ Element.text "No more events have been planned yet." ]
                                    )

                            [] ->
                                section "Next event"
                                    (Element.paragraph
                                        []
                                        [ Element.text "No more events have been planned yet." ]
                                    )
                        ]

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
                    GroupForm.view model.groupForm
                        |> Element.el
                            [ Element.width <| Element.maximum 800 Element.fill
                            , Element.centerX
                            ]
                        |> Element.map GroupFormMsg
                )

        MyGroupsRoute ->
            loginRequiredPage
                model
                (\_ ->
                    Element.text ""
                )

        MyProfileRoute ->
            loginRequiredPage
                model
                (\loggedIn ->
                    ProfileForm.view loggedIn.user loggedIn.profileForm
                        |> Element.el
                            [ Element.width <| Element.maximum 800 Element.fill
                            , Element.centerX
                            ]
                        |> Element.map ProfileFormMsg
                )


isLoggedIn : LoadedFrontend -> Bool
isLoggedIn model =
    case model.loginStatus of
        LoggedIn _ ->
            True

        NotLoggedIn _ ->
            False

        LoginStatusPending ->
            False


header : Bool -> Route -> Element FrontendMsg
header isLoggedIn_ route =
    Element.row
        [ Element.width Element.fill
        , Element.Background.color <| Element.rgb 0.8 0.8 0.8
        ]
        [ Element.row
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
