port module FrontendEffect exposing
    ( FrontendEffect
    , batch
    , copyToClipboard
    , cropImage
    , fileToBytes
    , getElement
    , getTime
    , getTimeZone
    , getWindowSize
    , manyToBackend
    , martinsstewart_crop_image_from_js
    , martinsstewart_get_time_zone_from_js
    , navigationLoad
    , navigationPushRoute
    , navigationPushUrl
    , navigationReplaceRoute
    , navigationReplaceUrl
    , none
    , selectFile
    , sendToBackend
    , toCmd
    , wait
    )

import Browser.Dom
import Browser.Navigation
import Duration exposing (Duration)
import File
import File.Select
import Lamdera
import List.Nonempty exposing (Nonempty(..))
import MockFile exposing (File(..))
import Pixels exposing (Pixels)
import Process
import Quantity exposing (Quantity)
import Route exposing (Route, Token(..))
import Task
import Time
import Types exposing (FrontendMsg, NavigationKey(..), ToBackend(..), ToBackendRequest)


port supermario_copy_to_clipboard_to_js : String -> Cmd msg


port martinsstewart_crop_image_to_js :
    { requestId : Int
    , imageUrl : String
    , cropX : Int
    , cropY : Int
    , cropWidth : Int
    , cropHeight : Int
    , width : Int
    , height : Int
    }
    -> Cmd msg


port martinsstewart_crop_image_from_js : ({ requestId : Int, croppedImageUrl : String } -> msg) -> Sub msg


port martinsstewart_get_time_zone_from_js : (Int -> msg) -> Sub msg


port martinsstewart_get_time_zone_to_js : () -> Cmd msg


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


type FrontendEffect
    = Batch (List FrontendEffect)
    | SendToBackend ToBackend
    | NavigationPushUrl NavigationKey String
    | NavigationReplaceUrl NavigationKey String
    | NavigationLoad String
    | GetTime (Time.Posix -> FrontendMsg)
    | Wait Duration FrontendMsg
    | SelectFile (List String) (MockFile.File -> FrontendMsg)
    | CopyToClipboard String
    | CropImage CropImageData
    | FileToUrl (String -> FrontendMsg) File
    | GetElement (Result Browser.Dom.Error Browser.Dom.Element -> FrontendMsg) String
    | GetWindowSize (Quantity Int Pixels -> Quantity Int Pixels -> FrontendMsg)
    | GetTimeZone


none : FrontendEffect
none =
    Batch []


batch : List FrontendEffect -> FrontendEffect
batch =
    Batch


sendToBackend : ToBackendRequest -> FrontendEffect
sendToBackend =
    List.Nonempty.fromElement >> ToBackend >> SendToBackend


manyToBackend : ToBackendRequest -> List ToBackendRequest -> FrontendEffect
manyToBackend firstRequest restOfRequests =
    Nonempty firstRequest restOfRequests |> ToBackend |> SendToBackend


navigationPushUrl : NavigationKey -> String -> FrontendEffect
navigationPushUrl =
    NavigationPushUrl


navigationPushRoute : NavigationKey -> Route -> FrontendEffect
navigationPushRoute navigationKey route =
    NavigationPushUrl navigationKey (Route.encode route)


navigationReplaceUrl : NavigationKey -> String -> FrontendEffect
navigationReplaceUrl =
    NavigationReplaceUrl


navigationReplaceRoute : NavigationKey -> Route -> FrontendEffect
navigationReplaceRoute navigationKey route =
    NavigationReplaceUrl navigationKey (Route.encode route)


navigationLoad : String -> FrontendEffect
navigationLoad =
    NavigationLoad


getTime : (Time.Posix -> FrontendMsg) -> FrontendEffect
getTime =
    GetTime


wait : Duration -> FrontendMsg -> FrontendEffect
wait =
    Wait


selectFile : List String -> (File -> FrontendMsg) -> FrontendEffect
selectFile =
    SelectFile


copyToClipboard : String -> FrontendEffect
copyToClipboard =
    CopyToClipboard


cropImage : CropImageData -> FrontendEffect
cropImage =
    CropImage


fileToBytes : (String -> FrontendMsg) -> File -> FrontendEffect
fileToBytes =
    FileToUrl


getElement : (Result Browser.Dom.Error Browser.Dom.Element -> FrontendMsg) -> String -> FrontendEffect
getElement =
    GetElement


getWindowSize : (Quantity Int Pixels -> Quantity Int Pixels -> FrontendMsg) -> FrontendEffect
getWindowSize =
    GetWindowSize


getTimeZone : FrontendEffect
getTimeZone =
    GetTimeZone


toCmd : FrontendEffect -> Cmd FrontendMsg
toCmd frontendEffect =
    case frontendEffect of
        Batch frontendEffects ->
            Cmd.batch (List.map toCmd frontendEffects)

        SendToBackend toBackend ->
            Lamdera.sendToBackend toBackend

        NavigationPushUrl navigationKey string ->
            case navigationKey of
                RealNavigationKey key ->
                    Browser.Navigation.pushUrl key string

                MockNavigationKey ->
                    Cmd.none

        NavigationReplaceUrl navigationKey string ->
            case navigationKey of
                RealNavigationKey key ->
                    Browser.Navigation.replaceUrl key string

                MockNavigationKey ->
                    Cmd.none

        NavigationLoad string ->
            Browser.Navigation.load string

        GetTime msg ->
            Time.now |> Task.perform msg

        Wait duration msg ->
            Process.sleep (Duration.inMilliseconds duration) |> Task.perform (always msg)

        SelectFile mimeTypes msg ->
            File.Select.file mimeTypes (RealFile >> msg)

        CopyToClipboard text ->
            supermario_copy_to_clipboard_to_js text

        CropImage data ->
            martinsstewart_crop_image_to_js
                { requestId = data.requestId
                , imageUrl = data.imageUrl
                , cropX = Pixels.inPixels data.cropX
                , cropY = Pixels.inPixels data.cropY
                , cropWidth = Pixels.inPixels data.cropWidth
                , cropHeight = Pixels.inPixels data.cropHeight
                , width = Pixels.inPixels data.width
                , height = Pixels.inPixels data.height
                }

        FileToUrl msg file ->
            case file of
                RealFile realFile ->
                    File.toUrl realFile |> Task.perform msg

                MockFile ->
                    Cmd.none

        GetElement msg elementId ->
            Browser.Dom.getElement elementId |> Task.attempt msg

        GetWindowSize msg ->
            Browser.Dom.getViewport
                |> Task.perform
                    (\{ scene } ->
                        msg (Pixels.pixels (round scene.width)) (Pixels.pixels (round scene.height))
                    )

        GetTimeZone ->
            martinsstewart_get_time_zone_to_js ()
