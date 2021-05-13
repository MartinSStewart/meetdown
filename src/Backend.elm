module Backend exposing (..)

import AssocList as Dict
import BackendEffect exposing (BackendEffect)
import Html
import Id exposing (ClientId, GroupId, SessionId, UserId)
import Lamdera
import Types exposing (..)


type alias Model =
    BackendModel


app =
    Lamdera.backend
        { init = init
        , update = \msg model -> update msg model |> Tuple.mapSecond BackendEffect.toCmd
        , updateFromFrontend =
            \sessionId clientId toBackend model ->
                updateFromFrontend
                    (Id.sessionIdFromString sessionId)
                    (Id.clientIdFromString clientId)
                    toBackend
                    model
                    |> Tuple.mapSecond BackendEffect.toCmd
        , subscriptions = \m -> Sub.none
        }


init : ( Model, Cmd BackendMsg )
init =
    ( { users = Dict.empty
      , groups = Dict.empty
      , sessions = Dict.empty
      }
    , Cmd.none
    )


update : BackendMsg -> Model -> ( Model, BackendEffect )
update msg model =
    case msg of
        NoOpBackendMsg ->
            ( model, BackendEffect.none )


updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, BackendEffect )
updateFromFrontend sessionId clientId msg model =
    case msg of
        CheckLoginAndGetGroupRequest groupId ->
            ( model
            , CheckLoginAndGetGroupResponse
                (checkLogin sessionId model)
                groupId
                (getGroup groupId model |> Maybe.andThen (groupToFrontend model))
                |> BackendEffect.sendToFrontend clientId
            )

        GetGroupRequest groupId ->
            ( model
            , getGroup groupId model
                |> Maybe.andThen (groupToFrontend model)
                |> GetGroupResponse groupId
                |> BackendEffect.sendToFrontend clientId
            )

        CheckLoginRequest ->
            ( model, checkLogin sessionId model |> CheckLoginResponse |> BackendEffect.sendToFrontend clientId )


checkLogin : SessionId -> Model -> LoginStatus
checkLogin sessionId model =
    case Dict.get sessionId model.sessions of
        Just session ->
            case Dict.get session.userId model.users of
                Just user ->
                    LoggedIn session.userId user

                Nothing ->
                    NotLoggedIn

        Nothing ->
            NotLoggedIn


getGroup : GroupId -> Model -> Maybe BackendGroup
getGroup groupId model =
    Dict.get groupId model.groups


getUser : UserId -> Model -> Maybe BackendUser
getUser userId model =
    Dict.get userId model.users


groupToFrontend : Model -> BackendGroup -> Maybe FrontendGroup
groupToFrontend model backendGroup =
    case getUser backendGroup.ownerId model of
        Just owner ->
            { ownerId = backendGroup.ownerId
            , owner = userToFrontend owner
            , name = backendGroup.name
            , events = backendGroup.events
            , isPrivate = backendGroup.isPrivate
            }
                |> Just

        Nothing ->
            Nothing


userToFrontend : BackendUser -> FrontendUser
userToFrontend backendUser =
    { name = backendUser.name
    , profileImage = backendUser.profileImage
    }
