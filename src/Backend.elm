module Backend exposing (app, init, update, updateFromFrontend)

import Array
import AssocList as Dict
import BackendEffect exposing (BackendEffect)
import BackendSub exposing (BackendSub)
import Duration
import Email
import Id exposing (ClientId, GroupId, SessionId, UserId)
import Lamdera
import List.Nonempty
import SendGrid
import String.Nonempty exposing (NonemptyString(..))
import Time
import Types exposing (..)
import Untrusted


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
        , subscriptions = subscriptions >> BackendSub.toSub
        }


init : ( BackendModel, Cmd BackendMsg )
init =
    ( { users = Dict.empty
      , groups = Dict.empty
      , sessions = Dict.empty
      , logs = Array.empty
      , time = Time.millisToPosix 0
      , secretCounter = 0
      }
    , Cmd.none
    )


subscriptions : BackendModel -> BackendSub
subscriptions _ =
    BackendSub.timeEvery (Duration.seconds 15) BackendGotTime


update : BackendMsg -> BackendModel -> ( BackendModel, BackendEffect )
update msg model =
    case msg of
        SentLoginEmail email result ->
            case result of
                Ok () ->
                    ( addLog
                        True
                        (NonemptyString 'S' "endGrid")
                        ("Sent a login email to " ++ Email.toString email)
                        model
                    , BackendEffect.none
                    )

                Err error ->
                    let
                        errorText =
                            "Tried sending a login email to "
                                ++ Email.toString email
                                ++ " but got this error "
                                ++ (case error of
                                        SendGrid.StatusCode400 errors ->
                                            List.map (\a -> a.message) errors
                                                |> String.join ", "
                                                |> (++) "StatusCode400: "

                                        SendGrid.StatusCode401 errors ->
                                            List.map (\a -> a.message) errors
                                                |> String.join ", "
                                                |> (++) "StatusCode401: "

                                        SendGrid.StatusCode403 { errors } ->
                                            List.filterMap (\a -> a.message) errors
                                                |> String.join ", "
                                                |> (++) "StatusCode403: "

                                        SendGrid.StatusCode413 errors ->
                                            List.map (\a -> a.message) errors
                                                |> String.join ", "
                                                |> (++) "StatusCode413: "

                                        SendGrid.UnknownError { statusCode, body } ->
                                            "UnknownError: " ++ String.fromInt statusCode ++ " " ++ body

                                        SendGrid.NetworkError ->
                                            "NetworkError"

                                        SendGrid.Timeout ->
                                            "Timeout"

                                        SendGrid.BadUrl url ->
                                            "BadUrl: " ++ url
                                   )
                    in
                    ( addLog True (NonemptyString 'S' "endGrid") errorText model, BackendEffect.none )

        BackendGotTime time ->
            ( { model | time = time }, BackendEffect.none )


addLog : Bool -> NonemptyString -> String -> BackendModel -> BackendModel
addLog isError title message model =
    { model
        | logs =
            Array.push { isError = isError, title = title, message = message, time = model.time } model.logs
    }


updateFromFrontend : SessionId -> ClientId -> ToBackend -> BackendModel -> ( BackendModel, BackendEffect )
updateFromFrontend sessionId clientId msgs model =
    List.Nonempty.foldl
        (\msg ( newModel, effects ) ->
            updateFromRequest sessionId clientId msg newModel
                |> Tuple.mapSecond (\a -> BackendEffect.batch [ a, effects ])
        )
        ( model, BackendEffect.none )
        msgs


updateFromRequest : SessionId -> ClientId -> ToBackendRequest -> BackendModel -> ( BackendModel, BackendEffect )
updateFromRequest sessionId clientId msg model =
    case msg of
        GetGroupRequest groupId ->
            ( model
            , getGroup groupId model
                |> Maybe.andThen (groupToFrontend model)
                |> GetGroupResponse groupId
                |> BackendEffect.sendToFrontend clientId
            )

        CheckLoginRequest ->
            ( model, checkLogin sessionId model |> CheckLoginResponse |> BackendEffect.sendToFrontend clientId )

        LoginRequest route untrustedEmail ->
            case Untrusted.validateEmail untrustedEmail of
                Ok email ->
                    let
                        ( model2, loginToken ) =
                            Id.getCryptoHash model
                    in
                    ( model2, BackendEffect.sendLoginEmail (SentLoginEmail email) email route loginToken )

                Err invalidEmail ->
                    ( addLog
                        True
                        (NonemptyString 'T' "rust check failed")
                        ("LoginRequest with " ++ invalidEmail ++ " failed due to invalid email.")
                        model
                    , BackendEffect.none
                    )

        GetAdminDataRequest ->
            adminAuthorization
                sessionId
                model
                (\_ ->
                    ( model, BackendEffect.sendToFrontend clientId (GetAdminDataResponse model.logs) )
                )

        LoginWithTokenRequest loginToken ->
            Debug.todo ""


userAuthorization :
    SessionId
    -> BackendModel
    -> (( UserId, BackendUser ) -> ( BackendModel, BackendEffect ))
    -> ( BackendModel, BackendEffect )
userAuthorization sessionId model updateFunc =
    case checkLogin sessionId model of
        LoggedIn userId user ->
            updateFunc ( userId, user )

        NotLoggedIn ->
            ( model, BackendEffect.none )


adminAuthorization :
    SessionId
    -> BackendModel
    -> (( UserId, BackendUser ) -> ( BackendModel, BackendEffect ))
    -> ( BackendModel, BackendEffect )
adminAuthorization sessionId model updateFunc =
    case checkLogin sessionId model of
        LoggedIn userId user ->
            if Id.adminUserId == Just userId then
                updateFunc ( userId, user )

            else
                ( model, BackendEffect.none )

        NotLoggedIn ->
            ( model, BackendEffect.none )


checkLogin : SessionId -> BackendModel -> LoginStatus
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


getGroup : GroupId -> BackendModel -> Maybe BackendGroup
getGroup groupId model =
    Dict.get groupId model.groups


getUser : UserId -> BackendModel -> Maybe BackendUser
getUser userId model =
    Dict.get userId model.users


groupToFrontend : BackendModel -> BackendGroup -> Maybe FrontendGroup
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
