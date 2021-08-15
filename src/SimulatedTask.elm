module SimulatedTask exposing (BackendOnly, FrontendOnly, HttpBody(..), HttpRequest, SimulatedTask(..), getTime, taskAndThen, taskFail, taskMap, taskMap2, taskMap3, taskMap4, taskMap5, taskMapError, taskOnError, taskSucceed, toTask, wait)

import Duration exposing (Duration)
import Http
import Json.Encode
import Process
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


getTime : SimulatedTask restriction x Time.Posix
getTime =
    GetTime Succeed


wait : Duration -> SimulatedTask restriction x ()
wait duration =
    SleepTask duration Succeed


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
taskAndThen : (a -> SimulatedTask restriction x b) -> SimulatedTask restriction x a -> SimulatedTask restriction x b
taskAndThen f task =
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
                , onRequestComplete = request.onRequestComplete >> taskAndThen f
                , timeout = request.timeout
                }

        SleepTask delay onResult ->
            SleepTask delay (onResult >> taskAndThen f)

        GetTime gotTime ->
            GetTime (gotTime >> taskAndThen f)


{-| A task that succeeds immediately when run.
-}
taskSucceed : a -> SimulatedTask restriction x a
taskSucceed =
    Succeed


{-| A task that fails immediately when run.
-}
taskFail : x -> SimulatedTask restriction x a
taskFail =
    Fail


{-| Transform a task.
-}
taskMap : (a -> b) -> SimulatedTask restriction x a -> SimulatedTask restriction x b
taskMap f =
    taskAndThen (f >> Succeed)


{-| Put the results of two tasks together.
-}
taskMap2 : (a -> b -> result) -> SimulatedTask restriction x a -> SimulatedTask restriction x b -> SimulatedTask restriction x result
taskMap2 func taskA taskB =
    taskA
        |> taskAndThen
            (\a ->
                taskB
                    |> taskAndThen (\b -> taskSucceed (func a b))
            )


{-| Put the results of three tasks together.
-}
taskMap3 : (a -> b -> c -> result) -> SimulatedTask restriction x a -> SimulatedTask restriction x b -> SimulatedTask restriction x c -> SimulatedTask restriction x result
taskMap3 func taskA taskB taskC =
    taskA
        |> taskAndThen
            (\a ->
                taskB
                    |> taskAndThen
                        (\b ->
                            taskC
                                |> taskAndThen (\c -> taskSucceed (func a b c))
                        )
            )


{-| Put the results of four tasks together.
-}
taskMap4 :
    (a -> b -> c -> d -> result)
    -> SimulatedTask restriction x a
    -> SimulatedTask restriction x b
    -> SimulatedTask restriction x c
    -> SimulatedTask restriction x d
    -> SimulatedTask restriction x result
taskMap4 func taskA taskB taskC taskD =
    taskA
        |> taskAndThen
            (\a ->
                taskB
                    |> taskAndThen
                        (\b ->
                            taskC
                                |> taskAndThen
                                    (\c ->
                                        taskD
                                            |> taskAndThen (\d -> taskSucceed (func a b c d))
                                    )
                        )
            )


{-| Put the results of five tasks together.
-}
taskMap5 :
    (a -> b -> c -> d -> e -> result)
    -> SimulatedTask restriction x a
    -> SimulatedTask restriction x b
    -> SimulatedTask restriction x c
    -> SimulatedTask restriction x d
    -> SimulatedTask restriction x e
    -> SimulatedTask restriction x result
taskMap5 func taskA taskB taskC taskD taskE =
    taskA
        |> taskAndThen
            (\a ->
                taskB
                    |> taskAndThen
                        (\b ->
                            taskC
                                |> taskAndThen
                                    (\c ->
                                        taskD
                                            |> taskAndThen
                                                (\d ->
                                                    taskE
                                                        |> taskAndThen (\e -> taskSucceed (func a b c d e))
                                                )
                                    )
                        )
            )


{-| Transform the error value.
-}
taskMapError : (x -> y) -> SimulatedTask restriction x a -> SimulatedTask restriction y a
taskMapError f task =
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
                , onRequestComplete = request.onRequestComplete >> taskMapError f
                , timeout = request.timeout
                }

        SleepTask delay onResult ->
            SleepTask delay (onResult >> taskMapError f)

        GetTime gotTime ->
            GetTime (gotTime >> taskMapError f)


{-| Recover from a failure in a task.
-}
taskOnError : (x -> SimulatedTask restriction y a) -> SimulatedTask restriction x a -> SimulatedTask restriction y a
taskOnError f task =
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
                , onRequestComplete = request.onRequestComplete >> taskOnError f
                , timeout = request.timeout
                }

        SleepTask delay onResult ->
            SleepTask delay (onResult >> taskOnError f)

        GetTime gotTime ->
            GetTime (gotTime >> taskOnError f)


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
