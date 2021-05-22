module Frontend exposing (app, init, update, updateFromBackend, view)

import Browser exposing (UrlRequest(..))
import Element exposing (Element)
import Element.Background
import Element.Font
import Element.Region
import FrontendEffect exposing (FrontendEffect)
import GroupForm
import GroupName
import Lamdera
import LoginForm
import Name
import ProfileForm
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
        , subscriptions = \m -> Sub.none
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
      , group = Nothing
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

                GroupRoute groupId ->
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
            ( { model | route = MyGroupsRoute }, FrontendEffect.none )

        TypedEmail text ->
            ( { model | loginForm = LoginForm.typedEmail text model.loginForm }, FrontendEffect.none )

        PressedSubmitEmail ->
            LoginForm.submitForm model.route model.loginForm
                |> Tuple.mapFirst (\a -> { model | loginForm = a })

        PressedCreateGroup ->
            ( { model | route = CreateGroupRoute }, FrontendEffect.none )

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
            ( { model | route = MyProfileRoute }, FrontendEffect.none )

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
                                , selectFile = \mimeTypes fileMsg -> FrontendEffect.selectFile mimeTypes (fileMsg >> ProfileFormMsg)
                                , sendDeleteAccountEmail = FrontendEffect.sendToBackend SendDeleteUserEmailRequest
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
            ( { model | group = Just ( groupId, result ) }, FrontendEffect.none )

        LoginWithTokenResponse result ->
            case result of
                Ok ( userId, user ) ->
                    ( { model
                        | loginStatus =
                            LoggedIn
                                { userId = userId
                                , user = user
                                , profileForm = ProfileForm.init
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
                                | route = GroupRoute groupId
                                , group = Just ( groupId, Types.groupToFrontend loggedIn.user groupData |> Just )
                                , groupForm = GroupForm.init
                              }
                            , FrontendEffect.none
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
    { title = ""
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
        [ header (isLoggedIn model) model.route
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


viewPage : LoadedFrontend -> Element FrontendMsg
viewPage model =
    case model.route of
        HomepageRoute ->
            Element.paragraph
                [ Element.padding 8 ]
                [ Element.text "A place to find people with shared interests. We don't sell your data, we don't show ads, we don't charge money, and it's all open source." ]

        GroupRoute groupId ->
            case model.group of
                Just ( loadedGroupId, Just group ) ->
                    if groupId == loadedGroupId then
                        Element.column
                            [ Element.spacing 16 ]
                            [ Element.el
                                [ Element.Font.size 32 ]
                                (Element.text (GroupName.toString group.name))
                            , Element.text (Name.toString group.owner.name)
                            ]

                    else
                        Element.text "Loading group"

                Just ( loadedGroupId, Nothing ) ->
                    if groupId == loadedGroupId then
                        Element.text "Group not found or it is private"

                    else
                        Element.text "Loading group"

                Nothing ->
                    Element.text "Loading group"

        AdminRoute ->
            Element.text "Admin panel"

        CreateGroupRoute ->
            GroupForm.view model.groupForm
                |> Element.el
                    [ Element.width <| Element.maximum 800 Element.fill
                    , Element.centerX
                    ]
                |> Element.map GroupFormMsg

        MyGroupsRoute ->
            Element.text "My groups "

        MyProfileRoute ->
            case model.loginStatus of
                LoggedIn loggedIn ->
                    ProfileForm.view loggedIn.user loggedIn.profileForm
                        |> Element.el
                            [ Element.width <| Element.maximum 800 Element.fill
                            , Element.centerX
                            ]
                        |> Element.map ProfileFormMsg

                NotLoggedIn _ ->
                    LoginForm.view model.loginForm

                LoginStatusPending ->
                    Element.none


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
