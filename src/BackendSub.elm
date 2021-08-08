module BackendSub exposing (BackendSub(..))

import Duration exposing (Duration)
import Id exposing (ClientId, SessionId)
import Time


type BackendSub backendMsg
    = Batch (List (BackendSub backendMsg))
    | TimeEvery Duration (Time.Posix -> backendMsg)
    | OnConnect (SessionId -> ClientId -> backendMsg)
    | OnDisconnect (SessionId -> ClientId -> backendMsg)
