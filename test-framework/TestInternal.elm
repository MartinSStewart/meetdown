module TestInternal exposing (Subscription(..))

import Duration exposing (Duration)
import Json.Decode
import Pixels exposing (Pixels)
import Quantity exposing (Quantity)
import TestId exposing (ClientId, SessionId)
import Time


type Subscription restriction msg
    = Batch (List (Subscription restriction msg))
    | None
    | TimeEvery Duration (Time.Posix -> msg)
    | OnResize (Quantity Int Pixels -> Quantity Int Pixels -> msg)
    | Port String ((Json.Decode.Value -> msg) -> Sub msg) (Json.Decode.Value -> msg)
    | OnConnect (SessionId -> ClientId -> msg)
    | OnDisconnect (SessionId -> ClientId -> msg)
