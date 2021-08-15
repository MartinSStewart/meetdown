module BackendSub exposing (BackendSub(..), map, toSub)

import Duration exposing (Duration)
import Id exposing (ClientId, SessionId)
import Lamdera
import Time


type BackendSub backendMsg
    = Batch (List (BackendSub backendMsg))
    | TimeEvery Duration (Time.Posix -> backendMsg)
    | OnConnect (SessionId -> ClientId -> backendMsg)
    | OnDisconnect (SessionId -> ClientId -> backendMsg)


map : (a -> b) -> BackendSub a -> BackendSub b
map mapFunc backendSub =
    case backendSub of
        Batch backendSubs ->
            List.map (map mapFunc) backendSubs |> Batch

        TimeEvery duration msg ->
            TimeEvery duration (msg >> mapFunc)

        OnConnect msg ->
            OnConnect (\sessionId clientId -> msg sessionId clientId |> mapFunc)

        OnDisconnect msg ->
            OnDisconnect (\sessionId clientId -> msg sessionId clientId |> mapFunc)


toSub : BackendSub backendMsg -> Sub backendMsg
toSub backendSub =
    case backendSub of
        Batch subs ->
            List.map toSub subs |> Sub.batch

        TimeEvery duration msg ->
            Time.every (Duration.inMilliseconds duration) msg

        OnConnect msg ->
            Lamdera.onConnect
                (\sessionId clientId -> msg (Id.sessionIdFromString sessionId) (Id.clientIdFromString clientId))

        OnDisconnect msg ->
            Lamdera.onDisconnect
                (\sessionId clientId -> msg (Id.sessionIdFromString sessionId) (Id.clientIdFromString clientId))
