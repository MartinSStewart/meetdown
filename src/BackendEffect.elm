module BackendEffect exposing (BackendEffect(..), HttpRequest, SimulatedTask(..), map, taskAndThen, taskAttempt, taskFail, taskMap, taskMap2, taskMap3, taskMap4, taskMap5, taskMapError, taskOnError, taskPerform, taskSucceed)

import Duration exposing (Duration)
import EmailAddress exposing (EmailAddress)
import Event exposing (Event)
import Group exposing (EventId)
import GroupName exposing (GroupName)
import Http
import Id exposing (ClientId, DeleteUserToken, GroupId, Id, LoginToken)
import Postmark
import Route exposing (Route)
import Time


type BackendEffect toFrontend backendMsg
    = Batch (List (BackendEffect toFrontend backendMsg))
    | None
    | SendToFrontend ClientId toFrontend
    | SendLoginEmail (Result Http.Error Postmark.PostmarkSendResponse -> backendMsg) EmailAddress Route (Id LoginToken) (Maybe ( Id GroupId, EventId ))
    | SendDeleteUserEmail (Result Http.Error Postmark.PostmarkSendResponse -> backendMsg) EmailAddress (Id DeleteUserToken)
    | SendEventReminderEmail (Result Http.Error Postmark.PostmarkSendResponse -> backendMsg) (Id GroupId) GroupName Event Time.Zone EmailAddress
    | GetTime (Time.Posix -> backendMsg)
    | Task (SimulatedTask backendMsg backendMsg)


type SimulatedTask x a
    = Succeed a
    | Fail x
    | HttpTask (HttpRequest x a)
    | SleepTask Duration (() -> SimulatedTask x a)


type alias HttpRequest x a =
    { method : String
    , url : String
    , body : String
    , headers : List ( String, String )
    , onRequestComplete : Http.Response String -> SimulatedTask x a
    }


map :
    (toFrontendA -> toFrontendB)
    -> (backendMsgA -> backendMsgB)
    -> BackendEffect toFrontendA backendMsgA
    -> BackendEffect toFrontendB backendMsgB
map mapToFrontend mapBackendMsg backendEffect =
    case backendEffect of
        Batch backendEffects ->
            List.map (map mapToFrontend mapBackendMsg) backendEffects |> Batch

        None ->
            None

        SendToFrontend clientId toFrontend ->
            SendToFrontend clientId (mapToFrontend toFrontend)

        SendLoginEmail msg emailAddress route id maybe ->
            SendLoginEmail (msg >> mapBackendMsg) emailAddress route id maybe

        SendDeleteUserEmail msg emailAddress id ->
            SendDeleteUserEmail (msg >> mapBackendMsg) emailAddress id

        SendEventReminderEmail msg id groupName event zone emailAddress ->
            SendEventReminderEmail (msg >> mapBackendMsg) id groupName event zone emailAddress

        GetTime msg ->
            GetTime (msg >> mapBackendMsg)

        Task simulatedTask ->
            taskMap mapBackendMsg simulatedTask |> taskMapError mapBackendMsg |> Task


{-| -}
taskPerform : (a -> msg) -> SimulatedTask Never a -> BackendEffect toFrontend msg
taskPerform f task =
    task
        |> taskMap f
        |> taskMapError never
        |> Task


{-| This is very similar to [`perform`](#perform) except it can handle failures!
-}
taskAttempt : (Result x a -> msg) -> SimulatedTask x a -> BackendEffect toFrontend msg
taskAttempt f task =
    task
        |> taskMap (Ok >> f)
        |> taskMapError (Err >> f)
        |> Task


{-| Chain together a task and a callback.
-}
taskAndThen : (a -> SimulatedTask x b) -> SimulatedTask x a -> SimulatedTask x b
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
                }

        SleepTask delay onResult ->
            SleepTask delay (onResult >> taskAndThen f)


{-| A task that succeeds immediately when run.
-}
taskSucceed : a -> SimulatedTask x a
taskSucceed =
    Succeed


{-| A task that fails immediately when run.
-}
taskFail : x -> SimulatedTask x a
taskFail =
    Fail


{-| Transform a task.
-}
taskMap : (a -> b) -> SimulatedTask x a -> SimulatedTask x b
taskMap f =
    taskAndThen (f >> Succeed)


{-| Put the results of two tasks together.
-}
taskMap2 : (a -> b -> result) -> SimulatedTask x a -> SimulatedTask x b -> SimulatedTask x result
taskMap2 func taskA taskB =
    taskA
        |> taskAndThen
            (\a ->
                taskB
                    |> taskAndThen (\b -> taskSucceed (func a b))
            )


{-| Put the results of three tasks together.
-}
taskMap3 : (a -> b -> c -> result) -> SimulatedTask x a -> SimulatedTask x b -> SimulatedTask x c -> SimulatedTask x result
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
    -> SimulatedTask x a
    -> SimulatedTask x b
    -> SimulatedTask x c
    -> SimulatedTask x d
    -> SimulatedTask x result
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
    -> SimulatedTask x a
    -> SimulatedTask x b
    -> SimulatedTask x c
    -> SimulatedTask x d
    -> SimulatedTask x e
    -> SimulatedTask x result
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
taskMapError : (x -> y) -> SimulatedTask x a -> SimulatedTask y a
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
                }

        SleepTask delay onResult ->
            SleepTask delay (onResult >> taskMapError f)


{-| Recover from a failure in a task.
-}
taskOnError : (x -> SimulatedTask y a) -> SimulatedTask x a -> SimulatedTask y a
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
                }

        SleepTask delay onResult ->
            SleepTask delay (onResult >> taskOnError f)
