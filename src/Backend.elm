module Backend exposing (app)

import BackendEffect exposing (BackendEffect)
import BackendHttpEffect
import BackendLogic
import BackendSub exposing (BackendSub)
import Duration exposing (Duration)
import EmailAddress exposing (EmailAddress)
import Env
import Http
import Id exposing (ClientId, DeleteUserToken, GroupId, Id, LoginToken, SessionId, UserId)
import Lamdera
import List.Nonempty
import Postmark
import Process
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
        , subscriptions = \model -> BackendLogic.subscriptions model |> toSub
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

        BackendEffect.GetTime msg ->
            Time.now |> Task.perform msg

        BackendEffect.Task simulatedTask ->
            toTask simulatedTask
                |> Task.attempt
                    (\result ->
                        case result of
                            Ok ok ->
                                ok

                            Err err ->
                                err
                    )


toTask : BackendEffect.SimulatedTask x b -> Task.Task x b
toTask simulatedTask =
    case simulatedTask of
        BackendEffect.Succeed a ->
            Task.succeed a

        BackendEffect.Fail x ->
            Task.fail x

        BackendEffect.HttpTask httpRequest ->
            Http.task
                { method = httpRequest.method
                , headers = List.map (\( key, value ) -> Http.header key value) httpRequest.headers
                , url = httpRequest.url
                , body =
                    case httpRequest.body of
                        BackendEffect.EmptyBody ->
                            Http.emptyBody

                        BackendEffect.StringBody { contentType, content } ->
                            Http.stringBody contentType content
                , resolver = Http.stringResolver Ok
                , timeout = Maybe.map Duration.inMilliseconds httpRequest.timeout
                }
                |> Task.andThen (\response -> httpRequest.onRequestComplete response |> toTask)

        BackendEffect.SleepTask duration function ->
            Process.sleep (Duration.inMilliseconds duration)
                |> Task.andThen (\() -> toTask (function ()))


toSub : BackendSub BackendMsg -> Sub BackendMsg
toSub backendSub =
    case backendSub of
        BackendSub.Batch subs ->
            List.map toSub subs |> Sub.batch

        BackendSub.TimeEvery duration msg ->
            Time.every (Duration.inMilliseconds duration) msg

        BackendSub.OnConnect msg ->
            Lamdera.onConnect
                (\sessionId clientId -> msg (Id.sessionIdFromString sessionId) (Id.clientIdFromString clientId))

        BackendSub.OnDisconnect msg ->
            Lamdera.onDisconnect
                (\sessionId clientId -> msg (Id.sessionIdFromString sessionId) (Id.clientIdFromString clientId))
