module Subscription exposing (Subscription, batch, fromJs, none, onConnect, onDisconnect, onResize, timeEvery, toSub)

import Browser.Events
import Duration exposing (Duration)
import Json.Decode
import Lamdera
import Pixels exposing (Pixels)
import Quantity exposing (Quantity)
import SimulatedTask exposing (BackendOnly, FrontendOnly)
import TestId exposing (ClientId, SessionId)
import TestInternal
import Time


type alias Subscription restriction msg =
    TestInternal.Subscription restriction msg


batch : List (Subscription restriction msg) -> Subscription restriction msg
batch =
    TestInternal.Batch


none : Subscription restriction msg
none =
    TestInternal.None


timeEvery : Duration -> (Time.Posix -> msg) -> Subscription restriction msg
timeEvery =
    TestInternal.TimeEvery


onResize : (Quantity Int Pixels -> Quantity Int Pixels -> msg) -> Subscription FrontendOnly msg
onResize =
    TestInternal.OnResize


fromJs : String -> ((Json.Decode.Value -> msg) -> Sub msg) -> (Json.Decode.Value -> msg) -> Subscription FrontendOnly msg
fromJs =
    TestInternal.Port


onConnect : (SessionId -> ClientId -> msg) -> Subscription BackendOnly msg
onConnect =
    TestInternal.OnConnect


onDisconnect : (SessionId -> ClientId -> msg) -> Subscription BackendOnly msg
onDisconnect =
    TestInternal.OnDisconnect



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


toSub : Subscription restriction msg -> Sub msg
toSub sub =
    case sub of
        TestInternal.Batch subs ->
            List.map toSub subs |> Sub.batch

        TestInternal.None ->
            Sub.none

        TestInternal.TimeEvery duration msg ->
            Time.every (Duration.inMilliseconds duration) msg

        TestInternal.OnResize msg ->
            Browser.Events.onResize (\w h -> msg (Pixels.pixels w) (Pixels.pixels h))

        TestInternal.Port _ portFunction msg ->
            portFunction msg

        TestInternal.OnConnect msg ->
            Lamdera.onConnect
                (\sessionId clientId -> msg (TestId.sessionIdFromString sessionId) (TestId.clientIdFromString clientId))

        TestInternal.OnDisconnect msg ->
            Lamdera.onDisconnect
                (\sessionId clientId -> msg (TestId.sessionIdFromString sessionId) (TestId.clientIdFromString clientId))
