module FrontendEffect exposing (FrontendEffect(..), PortToJs, batch, fileToUrl, map, none, selectFile, sendToBackend, sendToJs, taskAttempt, taskPerform)

import Json.Encode
import MockFile
import NavigationKey exposing (NavigationKey(..))
import SimulatedTask exposing (FrontendOnly, SimulatedTask)


type FrontendEffect toBackend frontendMsg
    = Batch (List (FrontendEffect toBackend frontendMsg))
    | None
    | SendToBackend toBackend
    | NavigationPushUrl NavigationKey String
    | NavigationReplaceUrl NavigationKey String
    | NavigationLoad String
    | SelectFile (List String) (MockFile.File -> frontendMsg)
    | FileToUrl (String -> frontendMsg) MockFile.File
    | Task (SimulatedTask FrontendOnly frontendMsg frontendMsg)
    | Port String (Json.Encode.Value -> Cmd frontendMsg) Json.Encode.Value


batch : List (FrontendEffect toBackend frontendMsg) -> FrontendEffect toBackend frontendMsg
batch =
    Batch


none : FrontendEffect toBackend frontendMsg
none =
    None


sendToBackend : toBackend -> FrontendEffect toBackend frontendMsg
sendToBackend =
    SendToBackend


selectFile : List String -> (MockFile.File -> frontendMsg) -> FrontendEffect toBackend frontendMsg
selectFile =
    SelectFile


fileToUrl : (String -> frontendMsg) -> MockFile.File -> FrontendEffect toBackend frontendMsg
fileToUrl =
    FileToUrl


sendToJs : String -> (Json.Encode.Value -> Cmd frontendMsg) -> Json.Encode.Value -> FrontendEffect toBackend frontendMsg
sendToJs =
    Port


type alias PortToJs =
    { portName : String, value : Json.Encode.Value }


map :
    (toBackendA -> toBackendB)
    -> (frontendMsgA -> frontendMsgB)
    -> FrontendEffect toBackendA frontendMsgA
    -> FrontendEffect toBackendB frontendMsgB
map mapToBackend mapFrontendMsg frontendEffect =
    case frontendEffect of
        Batch frontendEffects ->
            List.map (map mapToBackend mapFrontendMsg) frontendEffects |> Batch

        None ->
            None

        SendToBackend toBackend ->
            mapToBackend toBackend |> SendToBackend

        NavigationPushUrl navigationKey url ->
            NavigationPushUrl navigationKey url

        NavigationReplaceUrl navigationKey url ->
            NavigationReplaceUrl navigationKey url

        NavigationLoad url ->
            NavigationLoad url

        SelectFile mimeTypes msg ->
            SelectFile mimeTypes (msg >> mapFrontendMsg)

        FileToUrl msg file ->
            FileToUrl (msg >> mapFrontendMsg) file

        Task simulatedTask ->
            SimulatedTask.taskMap mapFrontendMsg simulatedTask
                |> SimulatedTask.taskMapError mapFrontendMsg
                |> Task

        Port portName function value ->
            Port portName (function >> Cmd.map mapFrontendMsg) value


{-| -}
taskPerform : (a -> msg) -> SimulatedTask FrontendOnly Never a -> FrontendEffect toBackend msg
taskPerform f task =
    task
        |> SimulatedTask.taskMap f
        |> SimulatedTask.taskMapError never
        |> Task


{-| This is very similar to [`perform`](#perform) except it can handle failures!
-}
taskAttempt : (Result x a -> msg) -> SimulatedTask FrontendOnly x a -> FrontendEffect toBackend msg
taskAttempt f task =
    task
        |> SimulatedTask.taskMap (Ok >> f)
        |> SimulatedTask.taskMapError (Err >> f)
        |> Task
