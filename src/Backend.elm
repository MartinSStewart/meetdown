module Backend exposing (app)

import BackendEffect exposing (BackendEffect)
import BackendLogic
import BackendSub exposing (BackendSub)
import Duration exposing (Duration)
import EmailAddress exposing (EmailAddress)
import Env
import Id exposing (ClientId, DeleteUserToken, GroupId, Id, LoginToken, SessionId, UserId)
import Lamdera
import List.Nonempty
import Postmark
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

        BackendEffect.SendToFrontends clientIds toFrontend ->
            clientIds
                |> List.map (\clientId -> Lamdera.sendToFrontend (Id.clientIdToString clientId) toFrontend)
                |> Cmd.batch

        BackendEffect.SendLoginEmail msg emailAddress route loginToken maybeJoinEvent ->
            case noReplyEmailAddress of
                Just sender ->
                    { from = { name = "Meetdown", email = sender }
                    , to = List.Nonempty.fromElement { name = "", email = emailAddress }
                    , subject = BackendLogic.loginEmailSubject
                    , body = Postmark.BodyHtml <| BackendLogic.loginEmailContent route loginToken maybeJoinEvent
                    , messageStream = "outbound"
                    }
                        |> Postmark.sendEmail msg Env.postmarkServerToken

                Nothing ->
                    Cmd.none

        BackendEffect.SendDeleteUserEmail msg emailAddress deleteUserToken ->
            case noReplyEmailAddress of
                Just sender ->
                    { from = { name = "Meetdown", email = sender }
                    , to = List.Nonempty.fromElement { name = "", email = emailAddress }
                    , subject = BackendLogic.deleteAccountEmailSubject
                    , body = Postmark.BodyHtml <| BackendLogic.deleteAccountEmailContent deleteUserToken
                    , messageStream = "outbound"
                    }
                        |> Postmark.sendEmail msg Env.postmarkServerToken

                Nothing ->
                    Cmd.none

        BackendEffect.SendEventReminderEmail msg groupId groupName event timezone emailAddress ->
            case noReplyEmailAddress of
                Just sender ->
                    { from = { name = "Meetdown", email = sender }
                    , to = List.Nonempty.fromElement { name = "", email = emailAddress }
                    , subject = BackendLogic.eventReminderEmailSubject groupName event timezone
                    , body = Postmark.BodyHtml <| BackendLogic.eventReminderEmailContent groupId groupName event
                    , messageStream = "broadcast"
                    }
                        |> Postmark.sendEmail msg Env.postmarkServerToken

                Nothing ->
                    Cmd.none

        BackendEffect.GetTime msg ->
            Time.now |> Task.perform msg


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
