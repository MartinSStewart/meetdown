module FrontendSub exposing (FrontendSub(..))

import Duration exposing (Duration)
import Pixels exposing (Pixels)
import Quantity exposing (Quantity)
import Time


type FrontendSub frontendMsg
    = Batch (List (FrontendSub frontendMsg))
    | TimeEvery Duration (Time.Posix -> frontendMsg)
    | OnResize (Quantity Int Pixels -> Quantity Int Pixels -> frontendMsg)
    | CropImageFromJs ({ requestId : Int, croppedImageUrl : String } -> frontendMsg)
