module FrontendEffect exposing (FrontendEffect(..), map)

import Browser.Dom
import Duration exposing (Duration)
import MockFile
import NavigationKey exposing (NavigationKey)
import Pixels exposing (Pixels)
import Quantity exposing (Quantity)
import Time
import TimeZone


type FrontendEffect toBackend frontendMsg
    = Batch (List (FrontendEffect toBackend frontendMsg))
    | None
    | SendToBackend toBackend
    | NavigationPushUrl NavigationKey String
    | NavigationReplaceUrl NavigationKey String
    | NavigationLoad String
    | GetTime (Time.Posix -> frontendMsg)
    | Wait Duration frontendMsg
    | SelectFile (List String) (MockFile.File -> frontendMsg)
    | CopyToClipboard String
    | CropImage CropImageData
    | FileToUrl (String -> frontendMsg) MockFile.File
    | GetElement (Result Browser.Dom.Error Browser.Dom.Element -> frontendMsg) String
    | GetWindowSize (Quantity Int Pixels -> Quantity Int Pixels -> frontendMsg)
    | GetTimeZone (Result TimeZone.Error ( String, Time.Zone ) -> frontendMsg)
    | ScrollToTop frontendMsg


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

        GetTime msg ->
            GetTime (msg >> mapFrontendMsg)

        Wait duration msg ->
            Wait duration (mapFrontendMsg msg)

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
