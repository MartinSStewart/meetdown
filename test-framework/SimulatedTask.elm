module SimulatedTask exposing (BackendOnly, FrontendOnly, HttpBody(..), HttpRequest, SimulatedTask(..), andThen, fail, getElement, getTime, getTimeZone, getTimeZoneName, getViewport, map, map2, map3, map4, map5, mapError, onError, setViewport, succeed, toTask, wait)

import Browser.Dom
import Duration exposing (Duration)
import Http
import Json.Encode
import Pixels exposing (Pixels)
import Process
import Quantity exposing (Quantity)
import Task
import Time


type FrontendOnly
    = FrontendOnly Never


type BackendOnly
    = BackendOnly Never


type SimulatedTask restriction x a
    = Succeed a
    | Fail x
    | HttpTask (HttpRequest restriction x a)
    | SleepTask Duration (() -> SimulatedTask restriction x a)
    | GetTime (Time.Posix -> SimulatedTask restriction x a)
    | GetTimeZone (Time.Zone -> SimulatedTask restriction x a)
    | GetTimeZoneName (Time.ZoneName -> SimulatedTask restriction x a)
    | GetViewport (Browser.Dom.Viewport -> SimulatedTask restriction x a)
    | SetViewport (Quantity Float Pixels) (Quantity Float Pixels) (() -> SimulatedTask restriction x a)
    | GetElement (Result Browser.Dom.Error Browser.Dom.Element -> SimulatedTask restriction x a) String


getTime : SimulatedTask restriction x Time.Posix
getTime =
    GetTime Succeed


wait : Duration -> SimulatedTask restriction x ()
wait duration =
    SleepTask duration Succeed


getTimeZone : SimulatedTask FrontendOnly x Time.Zone
getTimeZone =
    GetTimeZone Succeed


getTimeZoneName : SimulatedTask FrontendOnly x Time.ZoneName
getTimeZoneName =
    GetTimeZoneName Succeed


setViewport : Quantity Float Pixels -> Quantity Float Pixels -> SimulatedTask FrontendOnly x ()
setViewport x y =
    SetViewport x y Succeed


getViewport : SimulatedTask FrontendOnly x Browser.Dom.Viewport
getViewport =
    GetViewport Succeed


getElement : String -> SimulatedTask FrontendOnly Browser.Dom.Error Browser.Dom.Element
getElement htmlId =
    GetElement
        (\result ->
            case result of
                Ok ok ->
                    Succeed ok

                Err err ->
                    Fail err
        )
        htmlId


type alias HttpRequest restriction x a =
    { method : String
    , url : String
    , body : HttpBody
    , headers : List ( String, String )
    , onRequestComplete : Http.Response String -> SimulatedTask restriction x a
    , timeout : Maybe Duration
    }


{-| Represents the body of a `Request`.
-}
type HttpBody
    = EmptyBody
    | StringBody
        { contentType : String
        , content : String
        }
    | JsonBody Json.Encode.Value


{-| Chain together a task and a callback.
-}
andThen : (a -> SimulatedTask restriction x b) -> SimulatedTask restriction x a -> SimulatedTask restriction x b
andThen f task =
    case task of
        Succeed a ->
            f a

        Fail x ->
            Fail x

        HttpTask request ->
            HttpTask
                { method = request.method
                , url = request.url
                , body = request.body
                , headers = request.headers
                , onRequestComplete = request.onRequestComplete >> andThen f
                , timeout = request.timeout
                }

        SleepTask delay onResult ->
            SleepTask delay (onResult >> andThen f)

        GetTime gotTime ->
            GetTime (gotTime >> andThen f)

        GetTimeZone gotTimeZone ->
            GetTimeZone (gotTimeZone >> andThen f)

        GetTimeZoneName gotTimeZoneName ->
            GetTimeZoneName (gotTimeZoneName >> andThen f)

        SetViewport x y function ->
            SetViewport x y (function >> andThen f)

        GetViewport function ->
            GetViewport (function >> andThen f)

        GetElement function string ->
            GetElement (function >> andThen f) string


{-| A task that succeeds immediately when run.
-}
succeed : a -> SimulatedTask restriction x a
succeed =
    Succeed


{-| A task that fails immediately when run.
-}
fail : x -> SimulatedTask restriction x a
fail =
    Fail


{-| Transform a task.
-}
map : (a -> b) -> SimulatedTask restriction x a -> SimulatedTask restriction x b
map f =
    andThen (f >> Succeed)


{-| Put the results of two tasks together.
-}
map2 : (a -> b -> result) -> SimulatedTask restriction x a -> SimulatedTask restriction x b -> SimulatedTask restriction x result
map2 func taskA taskB =
    taskA
        |> andThen
            (\a ->
                taskB
                    |> andThen (\b -> succeed (func a b))
            )


{-| Put the results of three tasks together.
-}
map3 : (a -> b -> c -> result) -> SimulatedTask restriction x a -> SimulatedTask restriction x b -> SimulatedTask restriction x c -> SimulatedTask restriction x result
map3 func taskA taskB taskC =
    taskA
        |> andThen
            (\a ->
                taskB
                    |> andThen
                        (\b ->
                            taskC
                                |> andThen (\c -> succeed (func a b c))
                        )
            )


{-| Put the results of four tasks together.
-}
map4 :
    (a -> b -> c -> d -> result)
    -> SimulatedTask restriction x a
    -> SimulatedTask restriction x b
    -> SimulatedTask restriction x c
    -> SimulatedTask restriction x d
    -> SimulatedTask restriction x result
map4 func taskA taskB taskC taskD =
    taskA
        |> andThen
            (\a ->
                taskB
                    |> andThen
                        (\b ->
                            taskC
                                |> andThen
                                    (\c ->
                                        taskD
                                            |> andThen (\d -> succeed (func a b c d))
                                    )
                        )
            )


{-| Put the results of five tasks together.
-}
map5 :
    (a -> b -> c -> d -> e -> result)
    -> SimulatedTask restriction x a
    -> SimulatedTask restriction x b
    -> SimulatedTask restriction x c
    -> SimulatedTask restriction x d
    -> SimulatedTask restriction x e
    -> SimulatedTask restriction x result
map5 func taskA taskB taskC taskD taskE =
    taskA
        |> andThen
            (\a ->
                taskB
                    |> andThen
                        (\b ->
                            taskC
                                |> andThen
                                    (\c ->
                                        taskD
                                            |> andThen
                                                (\d ->
                                                    taskE
                                                        |> andThen (\e -> succeed (func a b c d e))
                                                )
                                    )
                        )
            )


{-| Transform the error value.
-}
mapError : (x -> y) -> SimulatedTask restriction x a -> SimulatedTask restriction y a
mapError f task =
    case task of
        Succeed a ->
            Succeed a

        Fail x ->
            Fail (f x)

        HttpTask request ->
            HttpTask
                { method = request.method
                , url = request.url
                , body = request.body
                , headers = request.headers
                , onRequestComplete = request.onRequestComplete >> mapError f
                , timeout = request.timeout
                }

        SleepTask delay onResult ->
            SleepTask delay (onResult >> mapError f)

        GetTime gotTime ->
            GetTime (gotTime >> mapError f)

        GetTimeZone gotTimeZone ->
            GetTimeZone (gotTimeZone >> mapError f)

        GetTimeZoneName gotTimeZoneName ->
            GetTimeZoneName (gotTimeZoneName >> mapError f)

        SetViewport x y function ->
            SetViewport x y (function >> mapError f)

        GetViewport function ->
            GetViewport (function >> mapError f)

        GetElement function string ->
            GetElement (function >> mapError f) string


{-| Recover from a failure in a task.
-}
onError : (x -> SimulatedTask restriction y a) -> SimulatedTask restriction x a -> SimulatedTask restriction y a
onError f task =
    case task of
        Succeed a ->
            Succeed a

        Fail x ->
            f x

        HttpTask request ->
            HttpTask
                { method = request.method
                , url = request.url
                , body = request.body
                , headers = request.headers
                , onRequestComplete = request.onRequestComplete >> onError f
                , timeout = request.timeout
                }

        SleepTask delay onResult ->
            SleepTask delay (onResult >> onError f)

        GetTime gotTime ->
            GetTime (gotTime >> onError f)

        GetTimeZone gotTimeZone ->
            GetTimeZone (gotTimeZone >> onError f)

        GetTimeZoneName gotTimeZoneName ->
            GetTimeZoneName (gotTimeZoneName >> onError f)

        SetViewport x y function ->
            SetViewport x y (function >> onError f)

        GetViewport function ->
            GetViewport (function >> onError f)

        GetElement function string ->
            GetElement (function >> onError f) string


toTask : SimulatedTask restriction x b -> Task.Task x b
toTask simulatedTask =
    case simulatedTask of
        Succeed a ->
            Task.succeed a

        Fail x ->
            Task.fail x

        HttpTask httpRequest ->
            Http.task
                { method = httpRequest.method
                , headers = List.map (\( key, value ) -> Http.header key value) httpRequest.headers
                , url = httpRequest.url
                , body =
                    case httpRequest.body of
                        EmptyBody ->
                            Http.emptyBody

                        StringBody { contentType, content } ->
                            Http.stringBody contentType content

                        JsonBody value ->
                            Http.jsonBody value
                , resolver = Http.stringResolver Ok
                , timeout = Maybe.map Duration.inMilliseconds httpRequest.timeout
                }
                |> Task.andThen (\response -> httpRequest.onRequestComplete response |> toTask)

        SleepTask duration function ->
            Process.sleep (Duration.inMilliseconds duration)
                |> Task.andThen (\() -> toTask (function ()))

        GetTime gotTime ->
            Time.now |> Task.andThen (\time -> toTask (gotTime time))

        GetTimeZone gotTimeZone ->
            Time.here |> Task.andThen (\time -> toTask (gotTimeZone time))

        GetTimeZoneName gotTimeZoneName ->
            Time.getZoneName |> Task.andThen (\time -> toTask (gotTimeZoneName time))

        SetViewport x y function ->
            Browser.Dom.setViewport (Pixels.inPixels x) (Pixels.inPixels y) |> Task.andThen (\() -> toTask (function ()))

        GetViewport function ->
            Browser.Dom.getViewport |> Task.andThen (\viewport -> toTask (function viewport))

        GetElement function string ->
            Browser.Dom.getElement string
                |> Task.map Ok
                |> Task.onError (Err >> Task.succeed)
                |> Task.andThen (\result -> toTask (function result))
