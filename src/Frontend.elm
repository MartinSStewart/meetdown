module Frontend exposing (app, init, update, updateFromBackend, view)

import Browser exposing (UrlRequest(..))
import Element exposing (Element)
import Element.Background
import Element.Border
import Element.Font
import Element.Input
import ElementExtra as Element
import Email exposing (Email)
import FrontendEffect exposing (FrontendEffect)
import Html exposing (Html)
import Id exposing (CryptoHash, LoginToken)
import Lamdera
import Route exposing (Route(..))
import Time
import Types exposing (..)
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
    ( Url.Parser.parse Route.decode url |> Maybe.withDefault ( Homepage, Nothing ) |> Loading key
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
      , email = ""
      , pressedSubmitEmail = False
      , emailSent = False
      , logs = Nothing
      , hasLoginError = False
      }
    , case route of
        Homepage ->
            FrontendEffect.sendToBackend login

        GroupRoute groupId ->
            FrontendEffect.manyToBackend
                login
                [ GetGroupRequest groupId ]

        AdminRoute ->
            FrontendEffect.manyToBackend login [ GetAdminDataRequest ]
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

        UrlChanged url ->
            ( model, FrontendEffect.none )

        GotTime time ->
            ( { model | time = time }, FrontendEffect.none )

        PressedLogin ->
            ( { model | showLogin = True }, FrontendEffect.none )

        TypedEmail text ->
            ( { model | email = text }, FrontendEffect.none )

        PressedSubmitEmail ->
            case validateEmail model.email of
                Ok email ->
                    ( { model | emailSent = True }
                    , Untrusted.untrust email |> LoginRequest model.route |> FrontendEffect.sendToBackend
                    )

                Err _ ->
                    ( { model | pressedSubmitEmail = True }, FrontendEffect.none )


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
                    ( { model | loginStatus = LoggedIn userId userData }, FrontendEffect.none )

                Err () ->
                    ( { model | hasLoginError = True }, FrontendEffect.none )

        CheckLoginResponse loginStatus ->
            ( { model | loginStatus = loginStatus }, FrontendEffect.none )

        GetAdminDataResponse logs ->
            ( { model | logs = Just logs }, FrontendEffect.none )


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
        [ Element.width Element.fill, Element.height Element.fill ]
        [ header
        , if model.showLogin then
            loginView model

          else
            case model.route of
                Homepage ->
                    Element.text "Homepage"

                GroupRoute groupId ->
                    case model.group of
                        Just ( loadedGroupId, Just group ) ->
                            if groupId == loadedGroupId then
                                Element.column
                                    [ Element.spacing 16 ]
                                    [ Element.el [ Element.Font.size 32 ] (Element.nonemptyText group.name)
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
        ]


header : Element FrontendMsg
header =
    Element.row
        [ Element.width Element.fill
        , Element.Background.color <| Element.rgb 0.8 0.8 0.8
        , Element.padding 8
        ]
        [ signUp ]


signUp : Element FrontendMsg
signUp =
    Element.button
        [ Element.alignRight ]
        { onPress = PressedLogin
        , label = Element.text "Sign up/Login"
        }


loginView : { a | email : String, pressedSubmitEmail : Bool } -> Element FrontendMsg
loginView { email, pressedSubmitEmail } =
    Element.el
        [ Element.width Element.fill, Element.height Element.fill ]
        (Element.column
            [ Element.centerX, Element.centerY, Element.spacing 16 ]
            [ Element.Input.text
                []
                { onChange = TypedEmail
                , text = email
                , placeholder = Nothing
                , label = Element.Input.labelAbove [] (Element.text "Enter your email address")
                }
            , case ( pressedSubmitEmail, validateEmail email ) of
                ( True, Err error ) ->
                    Element.text error

                _ ->
                    Element.none
            , Element.button buttonAttributes { onPress = PressedSubmitEmail, label = Element.text "Sign up/Login" }
            ]
        )


buttonAttributes =
    [ Element.Background.color <| Element.rgb 0.9 0.9 0.9
    , Element.Border.width 2
    , Element.Border.color <| Element.rgb 0.3 0.3 0.3
    , Element.padding 8
    , Element.Border.rounded 4
    ]


validateEmail : String -> Result String Email
validateEmail text =
    case Email.fromString text of
        Just email ->
            Ok email

        Nothing ->
            if String.isEmpty text then
                Err "Enter your email first"

            else
                Err "Invalid email address"
