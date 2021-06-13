module FrontendSub exposing (FrontendSub(..), subscriptions)

import Duration exposing (Duration)
import FrontendLogic exposing (Subscriptions)
import Pixels exposing (Pixels)
import Quantity exposing (Quantity)
import Time
import Types exposing (FrontendMsg)


type FrontendSub
    = Batch (List FrontendSub)
    | TimeEvery Duration (Time.Posix -> FrontendMsg)
    | OnResize (Quantity Int Pixels -> Quantity Int Pixels -> FrontendMsg)
    | CropImageFromJs ({ requestId : Int, croppedImageUrl : String } -> FrontendMsg)


subscriptions : Subscriptions FrontendSub
subscriptions =
    { batch = Batch
    , timeEvery = TimeEvery
    , onResize = OnResize
    , cropImageFromJs = CropImageFromJs
    }
