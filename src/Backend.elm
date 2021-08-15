module Backend exposing (app)

import BackendEffect exposing (BackendEffect)
import BackendLogic
import BackendSub exposing (BackendSub)
import Duration exposing (Duration)
import EmailAddress exposing (EmailAddress)
import Id exposing (ClientId, DeleteUserToken, GroupId, Id, LoginToken, SessionId, UserId)
import Lamdera
import SimulatedTask exposing (SimulatedTask)
import Task
import Time
import Types exposing (..)


app =
    Lamdera.backend
        { init = BackendLogic.init |> Tuple.mapSecond toCmd
        , update = \msg model -> BackendLogic.update msg model |> Tuple.mapSecond toCmd
        , updateFromFrontend =
            \sessionId clientId toBackend model ->
                BackendLogic.updateFromFrontend
                    (Id.sessionIdFromString sessionId)
                    (Id.clientIdFromString clientId)
                    toBackend
                    model
                    |> Tuple.mapSecond toCmd
        , subscriptions = \model -> BackendLogic.subscriptions model |> BackendSub.toSub
        }


noReplyEmailAddress : Maybe EmailAddress
noReplyEmailAddress =
    EmailAddress.fromString "no-reply@meetdown.app"


toCmd : BackendEffect ToFrontend BackendMsg -> Cmd BackendMsg
toCmd effect =
    case effect of
        BackendEffect.Batch effects ->
            List.map toCmd effects |> Cmd.batch

        BackendEffect.None ->
            Cmd.none

        BackendEffect.SendToFrontend clientId toFrontend ->
            Lamdera.sendToFrontend (Id.clientIdToString clientId) toFrontend

        BackendEffect.Task simulatedTask ->
            SimulatedTask.toTask simulatedTask
                |> Task.attempt
                    (\result ->
                        case result of
                            Ok ok ->
                                ok

                            Err err ->
                                err
                    )
