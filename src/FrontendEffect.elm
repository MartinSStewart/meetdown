module FrontendEffect exposing (FrontendEffect, batch, getTime, manyToBackend, navigationLoad, navigationPushUrl, navigationReplaceUrl, none, selectFile, sendToBackend, toCmd, wait)

import Browser.Navigation
import Duration exposing (Duration)
import File.Select
import Lamdera
import List.Nonempty exposing (Nonempty(..))
import MockFile exposing (File(..))
import Process
import Task
import Time
import Types exposing (FrontendMsg, NavigationKey(..), ToBackend(..), ToBackendRequest)


type FrontendEffect
    = Batch (List FrontendEffect)
    | SendToBackend ToBackend
    | NavigationPushUrl NavigationKey String
    | NavigationReplaceUrl NavigationKey String
    | NavigationLoad String
    | GetTime (Time.Posix -> FrontendMsg)
    | Wait Duration FrontendMsg
    | SelectFile (List String) (MockFile.File -> FrontendMsg)


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
