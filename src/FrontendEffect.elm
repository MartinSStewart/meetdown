module FrontendEffect exposing (FrontendEffect(..), map, taskAttempt, taskPerform)

import Browser.Dom
import Duration exposing (Duration)
import MockFile
import NavigationKey exposing (NavigationKey)
import Pixels exposing (Pixels)
import Quantity exposing (Quantity)
import SimulatedTask exposing (FrontendOnly, SimulatedTask)
import Time
import TimeZone


type FrontendEffect toBackend frontendMsg
    = Batch (List (FrontendEffect toBackend frontendMsg))
    | None
    | SendToBackend toBackend
    | NavigationPushUrl NavigationKey String
    | NavigationReplaceUrl NavigationKey String
    | NavigationLoad String
    | SelectFile (List String) (MockFile.File -> frontendMsg)
    | CopyToClipboard String
    | CropImage CropImageData
    | FileToUrl (String -> frontendMsg) MockFile.File
    | GetElement (Result Browser.Dom.Error Browser.Dom.Element -> frontendMsg) String
    | GetWindowSize (Quantity Int Pixels -> Quantity Int Pixels -> frontendMsg)
    | GetTimeZone (Result TimeZone.Error ( String, Time.Zone ) -> frontendMsg)
    | ScrollToTop frontendMsg
    | Task (SimulatedTask FrontendOnly frontendMsg frontendMsg)


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

        CopyToClipboard text ->
            CopyToClipboard text

        CropImage cropImageData ->
            CropImage cropImageData

        FileToUrl msg file ->
            FileToUrl (msg >> mapFrontendMsg) file

        GetElement msg string ->
            GetElement (msg >> mapFrontendMsg) string

        GetWindowSize msg ->
            GetWindowSize (\w h -> msg w h |> mapFrontendMsg)

        GetTimeZone msg ->
            GetTimeZone (msg >> mapFrontendMsg)

        ScrollToTop msg ->
            ScrollToTop (mapFrontendMsg msg)

        Task simulatedTask ->
            SimulatedTask.taskMap mapFrontendMsg simulatedTask
                |> SimulatedTask.taskMapError mapFrontendMsg
                |> Task


type alias CropImageData =
    { requestId : Int
    , imageUrl : String
    , cropX : Quantity Int Pixels
    , cropY : Quantity Int Pixels
    , cropWidth : Quantity Int Pixels
    , cropHeight : Quantity Int Pixels
    , width : Quantity Int Pixels
    , height : Quantity Int Pixels
    }


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
