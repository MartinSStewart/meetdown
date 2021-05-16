module BackendSub exposing (BackendSub, batch, timeEvery, toSub)

import Duration exposing (Duration)
import Time
import Types exposing (BackendMsg)


type BackendSub
    = Batch (List BackendSub)
    | TimeEvery Duration (Time.Posix -> BackendMsg)


batch : List BackendSub -> BackendSub
batch =
    Batch


timeEvery : Duration -> (Time.Posix -> BackendMsg) -> BackendSub
timeEvery =
    TimeEvery


toSub : BackendSub -> Sub BackendMsg
toSub backendSub =
    case backendSub of
        Batch backendSubs ->
            List.map toSub backendSubs |> Sub.batch

        TimeEvery duration msg ->
            Time.every (Duration.inMilliseconds duration) msg
