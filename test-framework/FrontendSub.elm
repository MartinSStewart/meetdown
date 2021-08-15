module FrontendSub exposing (FrontendSub(..), toSub)

import Browser.Events
import Duration exposing (Duration)
import Json.Decode
import Pixels exposing (Pixels)
import Quantity exposing (Quantity)
import Time


type FrontendSub frontendMsg
    = Batch (List (FrontendSub frontendMsg))
    | TimeEvery Duration (Time.Posix -> frontendMsg)
    | OnResize (Quantity Int Pixels -> Quantity Int Pixels -> frontendMsg)
    | Port String ((Json.Decode.Value -> frontendMsg) -> Sub frontendMsg) (Json.Decode.Value -> frontendMsg)


toSub : FrontendSub frontendMsg -> Sub frontendMsg
toSub sub =
    case sub of
        Batch subs ->
            List.map toSub subs |> Sub.batch

        TimeEvery duration msg ->
            Time.every (Duration.inMilliseconds duration) msg

        OnResize msg ->
            Browser.Events.onResize (\w h -> msg (Pixels.pixels w) (Pixels.pixels h))

        Port _ portFunction msg ->
            portFunction msg
