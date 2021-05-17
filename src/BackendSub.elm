module BackendSub exposing (BackendSub, batch, onConnect, onDisconnect, timeEvery, toSub)

import Duration exposing (Duration)
import Id exposing (ClientId, SessionId)
import Lamdera
import Time
import Types exposing (BackendMsg)


type BackendSub
    = Batch (List BackendSub)
    | TimeEvery Duration (Time.Posix -> BackendMsg)
    | OnConnect (SessionId -> ClientId -> BackendMsg)
    | OnDisconnect (SessionId -> ClientId -> BackendMsg)


batch : List BackendSub -> BackendSub
batch =
    Batch


timeEvery : Duration -> (Time.Posix -> BackendMsg) -> BackendSub
timeEvery =
    TimeEvery


onConnect : (SessionId -> ClientId -> BackendMsg) -> BackendSub
onConnect =
    OnConnect


onDisconnect : (SessionId -> ClientId -> BackendMsg) -> BackendSub
onDisconnect =
    OnDisconnect


toSub : BackendSub -> Sub BackendMsg
toSub backendSub =
    case backendSub of
        Batch backendSubs ->
            List.map toSub backendSubs |> Sub.batch

        TimeEvery duration msg ->
            Time.every (Duration.inMilliseconds duration) msg

        OnConnect msg ->
            Lamdera.onConnect
                (\sessionId clientId -> msg (Id.sessionIdFromString sessionId) (Id.clientIdFromString clientId))

        OnDisconnect msg ->
            Lamdera.onDisconnect
                (\sessionId clientId -> msg (Id.sessionIdFromString sessionId) (Id.clientIdFromString clientId))
