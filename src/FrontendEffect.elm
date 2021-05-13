module FrontendEffect exposing (FrontendEffect, batch, navigationLoad, navigationPushUrl, none, sendToBackend, toCmd)

import Browser.Navigation
import Lamdera
import Types exposing (FrontendMsg, NavigationKey(..), ToBackend)


type FrontendEffect
    = Batch (List FrontendEffect)
    | SendToBackend ToBackend
    | NavigationPushUrl NavigationKey String
    | NavigationLoad String


none : FrontendEffect
none =
    Batch []


batch : List FrontendEffect -> FrontendEffect
batch =
    Batch


sendToBackend : ToBackend -> FrontendEffect
sendToBackend =
    SendToBackend


navigationPushUrl : NavigationKey -> String -> FrontendEffect
navigationPushUrl =
    NavigationPushUrl


navigationLoad : String -> FrontendEffect
navigationLoad =
    NavigationLoad


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
