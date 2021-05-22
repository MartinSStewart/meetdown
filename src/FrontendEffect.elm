port module FrontendEffect exposing (FrontendEffect, batch, copyToClipboard, fileToBytes, getTime, manyToBackend, navigationLoad, navigationPushUrl, navigationReplaceUrl, none, selectFile, sendToBackend, setCanvasImage, toCmd, wait)

import Browser.Navigation
import Bytes exposing (Bytes)
import Duration exposing (Duration)
import File
import File.Select
import Lamdera
import List.Nonempty exposing (Nonempty(..))
import MockFile exposing (File(..))
import Process
import Task
import Time
import Types exposing (FrontendMsg, NavigationKey(..), ToBackend(..), ToBackendRequest)


port supermario_copy_to_clipboard_to_js : String -> Cmd msg


port martinsstewart_screenshot_canvas_to_js : { canvasId : String, image : Bytes } -> Cmd msg


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
    | SetCanvasImage { canvasId : String, image : Bytes }
    | FileToBytes (Bytes -> FrontendMsg) File


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


navigationReplaceUrl : NavigationKey -> String -> FrontendEffect
navigationReplaceUrl =
    NavigationReplaceUrl


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


setCanvasImage : { canvasId : String, image : Bytes } -> FrontendEffect
setCanvasImage =
    SetCanvasImage


fileToBytes : (Bytes -> FrontendMsg) -> File -> FrontendEffect
fileToBytes =
    FileToBytes


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

        SetCanvasImage imageBlob ->
            martinsstewart_screenshot_canvas_to_js imageBlob

        FileToBytes msg file ->
            case file of
                RealFile realFile ->
                    File.toBytes realFile |> Task.perform msg

                MockFile ->
                    Cmd.none
