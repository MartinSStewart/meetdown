module BackendEffect exposing
    ( BackendEffect(..)
    , get
    , map
    , post
    , request
    , taskAttempt
    , taskPerform
    )

import Duration exposing (Duration)
import HttpEffect
import SimulatedTask exposing (BackendOnly, SimulatedTask)
import TestId exposing (ClientId)


type BackendEffect toFrontend backendMsg
    = Batch (List (BackendEffect toFrontend backendMsg))
    | None
    | SendToFrontend ClientId toFrontend
    | Task (SimulatedTask BackendOnly backendMsg backendMsg)


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

        Task simulatedTask ->
            SimulatedTask.map mapBackendMsg simulatedTask
                |> SimulatedTask.mapError mapBackendMsg
                |> Task


{-| -}
taskPerform : (a -> msg) -> SimulatedTask BackendOnly Never a -> BackendEffect toFrontend msg
taskPerform f task =
    task
        |> SimulatedTask.map f
        |> SimulatedTask.mapError never
        |> Task


{-| This is very similar to [`perform`](#perform) except it can handle failures!
-}
taskAttempt : (Result x a -> msg) -> SimulatedTask BackendOnly x a -> BackendEffect toFrontend msg
taskAttempt f task =
    task
        |> SimulatedTask.map (Ok >> f)
        |> SimulatedTask.mapError (Err >> f)
        |> Task


{-| Create a `GET` request.
-}
get :
    { url : String
    , expect : HttpEffect.Expect msg
    }
    -> BackendEffect toFrontend msg
get r =
    request
        { method = "GET"
        , headers = []
        , url = r.url
        , body = HttpEffect.emptyBody
        , expect = r.expect
        , timeout = Nothing
        , tracker = Nothing
        }


{-| Create a `POST` request.
-}
post :
    { url : String
    , body : SimulatedTask.HttpBody
    , expect : HttpEffect.Expect msg
    }
    -> BackendEffect toFrontend msg
post r =
    request
        { method = "POST"
        , headers = []
        , url = r.url
        , body = r.body
        , expect = r.expect
        , timeout = Nothing
        , tracker = Nothing
        }


{-| Create a custom request.
-}
request :
    { method : String
    , headers : List HttpEffect.Header
    , url : String
    , body : SimulatedTask.HttpBody
    , expect : HttpEffect.Expect msg
    , timeout : Maybe Duration
    , tracker : Maybe String
    }
    -> BackendEffect toFrontend msg
request r =
    let
        (HttpEffect.Expect onResult) =
            r.expect
    in
    SimulatedTask.HttpTask
        { method = r.method
        , url = r.url
        , headers = r.headers
        , body = r.body
        , onRequestComplete = onResult >> SimulatedTask.Succeed
        , timeout = r.timeout
        }
        |> Task
