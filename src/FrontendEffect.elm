module FrontendEffect exposing (FrontendEffect, batch, getTime, manyToBackend, navigationLoad, navigationPushUrl, none, sendToBackend, toCmd)

import Browser.Navigation
import Lamdera
import List.Nonempty exposing (Nonempty(..))
import Task
import Time
import Types exposing (FrontendMsg, NavigationKey(..), ToBackend, ToBackendRequest)


type FrontendEffect
    = Batch (List FrontendEffect)
    | SendToBackend ToBackend
    | NavigationPushUrl NavigationKey String
    | NavigationLoad String
    | GetTime (Time.Posix -> FrontendMsg)


none : FrontendEffect
none =
    Batch []


batch : List FrontendEffect -> FrontendEffect
batch =
    Batch


sendToBackend : ToBackendRequest -> FrontendEffect
sendToBackend =
    List.Nonempty.fromElement >> SendToBackend


manyToBackend : ToBackendRequest -> List ToBackendRequest -> FrontendEffect
manyToBackend firstRequest restOfRequests =
    Nonempty firstRequest restOfRequests |> SendToBackend


navigationPushUrl : NavigationKey -> String -> FrontendEffect
navigationPushUrl =
    NavigationPushUrl


navigationLoad : String -> FrontendEffect
navigationLoad =
    NavigationLoad


getTime : (Time.Posix -> FrontendMsg) -> FrontendEffect
getTime =
    GetTime


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

        NavigationLoad string ->
            Browser.Navigation.load string

        GetTime msg ->
            Time.now |> Task.perform msg
