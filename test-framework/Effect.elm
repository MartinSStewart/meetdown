module Effect exposing (Effect(..), PortToJs, attempt, batch, fileToUrl, get, map, navigationLoad, navigationPushUrl, navigationReplaceUrl, none, perform, post, request, selectFile, sendToBackend, sendToFrontend, sendToJs)

import Duration exposing (Duration)
import HttpEffect
import Json.Encode
import MockFile
import NavigationKey exposing (NavigationKey(..))
import SimulatedTask exposing (BackendOnly, FrontendOnly, SimulatedTask)
import TestId exposing (ClientId)


type Effect restriction toMsg msg
    = Batch (List (Effect restriction toMsg msg))
    | None
    | SendToBackend toMsg
    | NavigationPushUrl NavigationKey String
    | NavigationReplaceUrl NavigationKey String
    | NavigationLoad String
    | SelectFile (List String) (MockFile.File -> msg)
    | FileToUrl (String -> msg) MockFile.File
    | Task (SimulatedTask restriction msg msg)
    | Port String (Json.Encode.Value -> Cmd msg) Json.Encode.Value
    | SendToFrontend ClientId toMsg


batch : List (Effect restriction toMsg msg) -> Effect restriction toMsg msg
batch =
    Batch


none : Effect restriction toMsg msg
none =
    None


sendToBackend : toMsg -> Effect FrontendOnly toMsg msg
sendToBackend =
    SendToBackend


navigationPushUrl : NavigationKey -> String -> Effect restriction toMsg msg
navigationPushUrl =
    NavigationPushUrl


navigationReplaceUrl : NavigationKey -> String -> Effect restriction toMsg msg
navigationReplaceUrl =
    NavigationReplaceUrl


navigationLoad : String -> Effect restriction toMsg msg
navigationLoad =
    NavigationLoad


selectFile : List String -> (MockFile.File -> msg) -> Effect FrontendOnly toMsg msg
selectFile =
    SelectFile


fileToUrl : (String -> msg) -> MockFile.File -> Effect FrontendOnly toMsg msg
fileToUrl =
    FileToUrl


sendToJs : String -> (Json.Encode.Value -> Cmd msg) -> Json.Encode.Value -> Effect FrontendOnly toMsg msg
sendToJs =
    Port


sendToFrontend : ClientId -> toMsg -> Effect BackendOnly toMsg msg
sendToFrontend =
    SendToFrontend


type alias PortToJs =
    { portName : String, value : Json.Encode.Value }


map :
    (toBackendA -> toBackendB)
    -> (frontendMsgA -> frontendMsgB)
    -> Effect restriction toBackendA frontendMsgA
    -> Effect restriction toBackendB frontendMsgB
map mapToMsg mapMsg frontendEffect =
    case frontendEffect of
        Batch frontendEffects ->
            List.map (map mapToMsg mapMsg) frontendEffects |> Batch

        None ->
            None

        SendToBackend toMsg ->
            mapToMsg toMsg |> SendToBackend

        NavigationPushUrl navigationKey url ->
            NavigationPushUrl navigationKey url

        NavigationReplaceUrl navigationKey url ->
            NavigationReplaceUrl navigationKey url

        NavigationLoad url ->
            NavigationLoad url

        SelectFile mimeTypes msg ->
            SelectFile mimeTypes (msg >> mapMsg)

        FileToUrl msg file ->
            FileToUrl (msg >> mapMsg) file

        Task simulatedTask ->
            SimulatedTask.map mapMsg simulatedTask
                |> SimulatedTask.mapError mapMsg
                |> Task

        Port portName function value ->
            Port portName (function >> Cmd.map mapMsg) value

        SendToFrontend clientId toMsg ->
            SendToFrontend clientId (mapToMsg toMsg)


{-| -}
perform : (a -> msg) -> SimulatedTask restriction Never a -> Effect restriction toMsg msg
perform f task =
    task
        |> SimulatedTask.map f
        |> SimulatedTask.mapError never
        |> Task


{-| This is very similar to [`perform`](#perform) except it can handle failures!
-}
attempt : (Result x a -> msg) -> SimulatedTask restriction x a -> Effect restriction toMsg msg
attempt f task =
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
    -> Effect restriction toFrontend msg
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
    -> Effect restriction toFrontend msg
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
    -> Effect restriction toFrontend msg
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
