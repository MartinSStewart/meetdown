port module FrontendEffect exposing
    ( FrontendEffect
    , batch
    , copyToClipboard
    , cropImage
    , fileToBytes
    , getElement
    , getTime
    , manyToBackend
    , martinsstewart_crop_image_from_js
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
import Bytes exposing (Bytes)
import Duration exposing (Duration)
import File
import File.Select
import Lamdera
import List.Nonempty exposing (Nonempty(..))
import MockFile exposing (File(..))
import Process
import Route exposing (Route, Token(..))
import Task
import Time
import Types exposing (FrontendMsg, NavigationKey(..), ToBackend(..), ToBackendRequest)


port supermario_copy_to_clipboard_to_js : String -> Cmd msg


port martinsstewart_crop_image_to_js : CropImageData -> Cmd msg


port martinsstewart_crop_image_from_js : ({ requestId : Int, croppedImageUrl : String } -> msg) -> Sub msg


type alias CropImageData =
    { requestId : Int, imageUrl : String, x : Int, y : Int, size : Int }


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
    | CropImage { requestId : Int, imageUrl : String, x : Int, y : Int, size : Int }
    | FileToUrl (String -> FrontendMsg) File
    | GetElement (Result Browser.Dom.Error Browser.Dom.Element -> FrontendMsg) String


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
    NavigationPushUrl navigationKey (Route.encode route NoToken)


navigationReplaceUrl : NavigationKey -> String -> FrontendEffect
navigationReplaceUrl =
    NavigationReplaceUrl


navigationReplaceRoute : NavigationKey -> Route -> FrontendEffect
navigationReplaceRoute navigationKey route =
    NavigationReplaceUrl navigationKey (Route.encode route NoToken)


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
            martinsstewart_crop_image_to_js data

        FileToUrl msg file ->
            case file of
                RealFile realFile ->
                    File.toUrl realFile |> Task.perform msg

                MockFile ->
                    Cmd.none

        GetElement msg elementId ->
            Browser.Dom.getElement elementId |> Task.attempt msg
