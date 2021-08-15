module FrontendEffect exposing (FrontendEffect(..), PortToJs, map, taskAttempt, taskPerform)

import Browser.Dom
import Json.Encode
import MockFile
import NavigationKey exposing (NavigationKey(..))
import Pixels exposing (Pixels)
import Quantity exposing (Quantity)
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
    | GetElement (Result Browser.Dom.Error Browser.Dom.Element -> frontendMsg) String
    | GetWindowSize (Quantity Int Pixels -> Quantity Int Pixels -> frontendMsg)
    | Task (SimulatedTask FrontendOnly frontendMsg frontendMsg)
    | Port String (Json.Encode.Value -> Cmd frontendMsg) Json.Encode.Value


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

        GetElement msg string ->
            GetElement (msg >> mapFrontendMsg) string

        GetWindowSize msg ->
            GetWindowSize (\w h -> msg w h |> mapFrontendMsg)

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
