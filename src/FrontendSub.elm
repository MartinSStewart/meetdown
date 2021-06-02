module FrontendSub exposing (FrontendSub, batch, cropImageFromJs, onResize, timeEvery, toSub)

import Browser.Events
import Duration exposing (Duration)
import FrontendEffect
import Pixels exposing (Pixels)
import Quantity exposing (Quantity)
import Time
import Types exposing (BackendMsg, FrontendMsg)


type FrontendSub
    = Batch (List FrontendSub)
    | TimeEvery Duration (Time.Posix -> FrontendMsg)
    | OnResize (Quantity Int Pixels -> Quantity Int Pixels -> FrontendMsg)
    | CropImageFromJs ({ requestId : Int, croppedImageUrl : String } -> FrontendMsg)


batch : List FrontendSub -> FrontendSub
batch =
    Batch


timeEvery : Duration -> (Time.Posix -> FrontendMsg) -> FrontendSub
timeEvery =
    TimeEvery


onResize : (Quantity Int Pixels -> Quantity Int Pixels -> FrontendMsg) -> FrontendSub
onResize =
    OnResize


cropImageFromJs : ({ requestId : Int, croppedImageUrl : String } -> FrontendMsg) -> FrontendSub
cropImageFromJs =
    CropImageFromJs


toSub : FrontendSub -> Sub FrontendMsg
toSub frontendSub =
    case frontendSub of
        Batch frontendSubs ->
            List.map toSub frontendSubs |> Sub.batch

        TimeEvery duration msg ->
            Time.every (Duration.inMilliseconds duration) msg

        OnResize msg ->
            Browser.Events.onResize (\w h -> msg (Pixels.pixels w) (Pixels.pixels h))

        CropImageFromJs msg ->
            FrontendEffect.martinsstewart_crop_image_from_js msg
