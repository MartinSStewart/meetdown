module Frontend exposing (..)

import Browser exposing (UrlRequest(..))
import Element exposing (Element)
import Element.Font
import ElementExtra as Element
import FrontendEffect exposing (FrontendEffect)
import Html
import Html.Attributes as Attr
import Lamdera
import Time
import Types exposing (..)
import Url exposing (Url)
import Url.Parser exposing ((</>))


app =
    Lamdera.frontend
        { init = \url key -> init url (RealNavigationKey key)
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = \msg model -> update msg model |> Tuple.mapSecond FrontendEffect.toCmd
        , updateFromBackend = \msg model -> updateFromBackend msg model |> Tuple.mapSecond FrontendEffect.toCmd
        , subscriptions = \m -> Sub.none
        , view = view
        }


routeParser : Url.Parser.Parser (Route -> c) c
routeParser =
    Url.Parser.oneOf
        [ Url.Parser.top |> Url.Parser.map Homepage
        , Url.Parser.s "group" </> Url.Parser.string |> Url.Parser.map (GroupId >> GroupRoute)
        ]


decodeRoute : Url -> Route
decodeRoute url =
    case Url.Parser.parse routeParser url of
        Just route ->
            route

        Nothing ->
            Homepage


init : Url -> NavigationKey -> ( FrontendModel, Cmd FrontendMsg )
init url key =
    ( Loading key (decodeRoute url)
    , Cmd.none
    )


initLoadedFrontend : NavigationKey -> Route -> Time.Posix -> ( LoadedFrontend, FrontendEffect )
initLoadedFrontend navigationKey route time =
    ( { navigationKey = navigationKey
      , loginStatus = NotLoggedIn
      , route = route
      , group = Nothing
      , time = time
      , lastConnectionCheck = time
      }
    , case route of
        GroupRoute groupId ->
            FrontendEffect.sendToBackend (CheckLoginAndGetGroupRequest groupId)

        Homepage ->
            FrontendEffect.sendToBackend CheckLoginRequest
    )


update : FrontendMsg -> FrontendModel -> ( FrontendModel, FrontendEffect )
update msg model =
    case model of
        Loading key route ->
            ( Loading key route, FrontendEffect.none )

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

        NoOpFrontendMsg ->
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
        CheckLoginAndGetGroupResponse loginStatus groupId result ->
            ( { model | loginStatus = loginStatus, group = Just ( groupId, result ) }, FrontendEffect.none )

        GetGroupResponse groupId result ->
            ( { model | group = Just ( groupId, result ) }, FrontendEffect.none )

        CheckLoginResponse loginStatus ->
            ( { model | loginStatus = loginStatus }, FrontendEffect.none )


view : FrontendModel -> { title : String, body : List (Html.Html msg) }
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
    case model.route of
        Homepage ->
            Element.text "Homepage"

        GroupRoute groupId ->
            case model.group of
                Just ( loadedGroupId, Ok group ) ->
                    Element.column
                        [ Element.spacing 16 ]
                        [ Element.el [ Element.Font.size 32 ] (Element.nonemptyText group.name)
                        , Element.nonemptyText group.owner.name
                        ]

                Just ( loadedGroupId, Err () ) ->
                    Element.text "Group not found or it is private"

                Nothing ->
                    Element.text "Loading group"
