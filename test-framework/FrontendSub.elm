module FrontendSub exposing (FrontendSub(..), batch, fromJs, none, onResize, timeEvery, toSub)

import Browser.Events
import Duration exposing (Duration)
import Json.Decode
import Pixels exposing (Pixels)
import Quantity exposing (Quantity)
import Time


type FrontendSub frontendMsg
    = Batch (List (FrontendSub frontendMsg))
    | None
    | TimeEvery Duration (Time.Posix -> frontendMsg)
    | OnResize (Quantity Int Pixels -> Quantity Int Pixels -> frontendMsg)
    | Port String ((Json.Decode.Value -> frontendMsg) -> Sub frontendMsg) (Json.Decode.Value -> frontendMsg)


batch : List (FrontendSub frontendMsg) -> FrontendSub frontendMsg
batch =
    Batch


none : FrontendSub frontendMsg
none =
    None


timeEvery : Duration -> (Time.Posix -> frontendMsg) -> FrontendSub frontendMsg
timeEvery =
    TimeEvery


onResize : (Quantity Int Pixels -> Quantity Int Pixels -> frontendMsg) -> FrontendSub frontendMsg
onResize =
    OnResize



--map : (a -> b) -> FrontendSub a -> FrontendSub b
--map mapFunc subscription =
--    case subscription of
--        Batch subscriptions ->
--            List.map (map mapFunc) subscriptions |> Batch
--
--        TimeEvery duration msg ->
--            TimeEvery duration (msg >> mapFunc)
--
--        OnResize msg ->
--            OnResize (\w h -> msg w h |> mapFunc)
--
--        Port portName portFunction msg ->
--            let
--                portFunction_ : (Json.Decode.Value -> b) -> Sub b
--                portFunction_ msg_ =
--                    portFunction msg_ |> Sub.map mapFunc
--            in
--            Port portName portFunction_ (msg >> mapFunc)


toSub : FrontendSub frontendMsg -> Sub frontendMsg
toSub sub =
    case sub of
        Batch subs ->
            List.map toSub subs |> Sub.batch

        None ->
            Sub.none

        TimeEvery duration msg ->
            Time.every (Duration.inMilliseconds duration) msg

        OnResize msg ->
            Browser.Events.onResize (\w h -> msg (Pixels.pixels w) (Pixels.pixels h))

        Port _ portFunction msg ->
            portFunction msg


fromJs : String -> ((Json.Decode.Value -> frontendMsg) -> Sub frontendMsg) -> (Json.Decode.Value -> frontendMsg) -> FrontendSub frontendMsg
fromJs =
    Port
