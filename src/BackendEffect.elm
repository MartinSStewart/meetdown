module BackendEffect exposing (BackendEffect, batch, none, sendToFrontend, toCmd)

import Id exposing (ClientId)
import Lamdera
import Types exposing (BackendMsg, ToFrontend)


type BackendEffect
    = Batch (List BackendEffect)
    | SendToFrontend ClientId ToFrontend


none : BackendEffect
none =
    Batch []


batch : List BackendEffect -> BackendEffect
batch =
    Batch


sendToFrontend : ClientId -> ToFrontend -> BackendEffect
sendToFrontend =
    SendToFrontend


toCmd : BackendEffect -> Cmd BackendMsg
toCmd backendEffect =
    case backendEffect of
        Batch backendEffects ->
            Cmd.batch (List.map toCmd backendEffects)

        SendToFrontend (ClientId clientId) toFrontend ->
            Lamdera.sendToFrontend clientId toFrontend
