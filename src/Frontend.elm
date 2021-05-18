module Frontend exposing (app, init, update, updateFromBackend, view)

import Browser exposing (UrlRequest(..))
import Element exposing (Element)
import Element.Background
import Element.Font
import ElementExtra as Element
import FrontendEffect exposing (FrontendEffect)
import GroupForm
import GroupName
import Id exposing (CryptoHash, LoginToken)
import Lamdera
import LoginForm
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
    ( Url.Parser.parse Route.decode url |> Maybe.withDefault ( HomepageRoute, Nothing ) |> Loading key
    , FrontendEffect.getTime GotTime
    )


initLoadedFrontend :
    NavigationKey
    -> Route
    -> Maybe (CryptoHash LoginToken)
    -> Time.Posix
    -> ( LoadedFrontend, FrontendEffect )
initLoadedFrontend navigationKey route maybeLoginToken time =
    let
        login =
            case maybeLoginToken of
                Just loginToken ->
                    LoginWithTokenRequest loginToken

                Nothing ->
                    CheckLoginRequest
    in
    ( { navigationKey = navigationKey
      , loginStatus = NotLoggedIn
      , route = route
      , group = Nothing
      , time = time
      , lastConnectionCheck = time
      , showLogin = False
      , loginForm =
            { email = ""
            , pressedSubmitEmail = False
            , emailSent = False
            }
      , logs = Nothing
      , hasLoginError = False
      , groupForm = GroupForm.init
      , groupCreated = False
      }
    , case route of
        HomepageRoute ->
            FrontendEffect.sendToBackend login

        GroupRoute groupId ->
            FrontendEffect.manyToBackend
                login
                [ GetGroupRequest groupId ]

        AdminRoute ->
            FrontendEffect.manyToBackend login [ GetAdminDataRequest ]

        CreateGroupRoute ->
            FrontendEffect.none

        MyGroupsRoute ->
            FrontendEffect.none
    )


update : FrontendMsg -> FrontendModel -> ( FrontendModel, FrontendEffect )
update msg model =
    case model of
        Loading key ( route, maybeLoginToken ) ->
            case msg of
                GotTime time ->
                    initLoadedFrontend key route maybeLoginToken time |> Tuple.mapFirst Loaded

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
                    ( model
                    , FrontendEffect.navigationPushUrl model.navigationKey (Url.toString url)
                    )

                External url ->
                    ( model, FrontendEffect.navigationLoad url )

        UrlChanged _ ->
            ( model, FrontendEffect.none )

        GotTime time ->
            ( { model | time = time }, FrontendEffect.none )

        PressedLogin ->
            ( { model | showLogin = True }, FrontendEffect.none )

        PressedLogout ->
            ( { model | loginStatus = NotLoggedIn }, FrontendEffect.sendToBackend LogoutRequest )

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
                Ok ( userId, userData ) ->
                    ( { model | loginStatus = LoggedIn userId userData, showLogin = False }
                    , FrontendEffect.none
                    )

                Err () ->
                    ( { model | hasLoginError = True }, FrontendEffect.none )

        CheckLoginResponse loginStatus ->
            ( { model | loginStatus = loginStatus }, FrontendEffect.none )

        GetAdminDataResponse logs ->
            ( { model | logs = Just logs }, FrontendEffect.none )

        CreateGroupResponse result ->
            case model.loginStatus of
                LoggedIn _ userData ->
                    case result of
                        Ok ( groupId, groupData ) ->
                            ( { model
                                | route = GroupRoute groupId
                                , group = Just ( groupId, Types.groupToFrontend userData groupData |> Just )
                                , groupForm = GroupForm.init
                              }
                            , FrontendEffect.none
                            )

                        Err error ->
                            ( { model | groupForm = GroupForm.submitFailed error model.groupForm }
                            , FrontendEffect.none
                            )

                NotLoggedIn ->
                    ( model, FrontendEffect.none )

        LogoutResponse ->
            ( { model | loginStatus = NotLoggedIn }, FrontendEffect.none )


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
        [ header (isLoggedIn model) (model.route == CreateGroupRoute)
        , if model.showLogin then
            LoginForm.view model.loginForm

          else
            case model.route of
                HomepageRoute ->
                    Element.text "Homepage"

                GroupRoute groupId ->
                    case model.group of
                        Just ( loadedGroupId, Just group ) ->
                            if groupId == loadedGroupId then
                                Element.column
                                    [ Element.spacing 16 ]
                                    [ Element.el
                                        [ Element.Font.size 32 ]
                                        (Element.text (GroupName.toString group.name))
                                    , Element.nonemptyText group.owner.name
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
        ]


isLoggedIn : LoadedFrontend -> Bool
isLoggedIn model =
    case model.loginStatus of
        LoggedIn _ _ ->
            True

        NotLoggedIn ->
            False


header : Bool -> Bool -> Element FrontendMsg
header isLoggedIn_ isCreatingGroup =
    Element.row
        [ Element.width Element.fill
        , Element.Background.color <| Element.rgb 0.8 0.8 0.8
        ]
        [ Element.row
            [ Element.alignRight ]
            (if isLoggedIn_ then
                [ if isCreatingGroup then
                    Element.none

                  else
                    Ui.headerButton
                        { onPress = PressedCreateGroup
                        , label = "Create group"
                        }
                , Ui.headerButton
                    { onPress = PressedMyGroups
                    , label = "My groups"
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
