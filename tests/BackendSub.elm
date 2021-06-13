module BackendSub exposing (BackendSub(..), subscriptions)

import BackendLogic exposing (Subscriptions)
import Duration exposing (Duration)
import Id exposing (ClientId, SessionId)
import Time
import Types exposing (BackendMsg)


type BackendSub
    = Batch (List BackendSub)
    | TimeEvery Duration (Time.Posix -> BackendMsg)
    | OnConnect (SessionId -> ClientId -> BackendMsg)
    | OnDisconnect (SessionId -> ClientId -> BackendMsg)


subscriptions : Subscriptions BackendSub
subscriptions =
    { batch = Batch
    , timeEvery = TimeEvery
    , onConnect = OnConnect
    , onDisconnect = OnDisconnect
    }
