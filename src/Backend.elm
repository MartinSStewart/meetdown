module Backend exposing (app)

import BackendLogic exposing (Effects, Subscriptions)
import Duration exposing (Duration)
import Email.Html
import EmailAddress exposing (EmailAddress)
import Env
import Id exposing (ClientId, DeleteUserToken, GroupId, Id, LoginToken, SessionId, UserId)
import Lamdera
import List.Nonempty
import Postmark
import SendGrid
import String.Nonempty
import Task
import Time
import Types exposing (..)


app =
    let
        app_ =
            BackendLogic.createApp allEffects allSubscriptions
    in
    Lamdera.backend
        { init = app_.init
        , update = app_.update
        , updateFromFrontend =
            \sessionId clientId toBackend model ->
                app_.updateFromFrontend
                    (Id.sessionIdFromString sessionId)
                    (Id.clientIdFromString clientId)
                    toBackend
                    model
        , subscriptions = app_.subscriptions
        }


noReplyEmailAddress : Maybe EmailAddress
noReplyEmailAddress =
    EmailAddress.fromString "no-reply@lamdera.com"


allEffects : Effects (Cmd BackendMsg)
allEffects =
    { batch = Cmd.batch
    , none = Cmd.none
    , sendToFrontend =
        \clientId toFrontend ->
            Lamdera.sendToFrontend (Id.clientIdToString clientId) toFrontend
    , sendToFrontends =
        \clientIds toFrontend ->
            clientIds
                |> List.map (\clientId -> Lamdera.sendToFrontend (Id.clientIdToString clientId) toFrontend)
                |> Cmd.batch
    , sendLoginEmail =
        \msg emailAddress route loginToken maybeJoinEvent ->
            case noReplyEmailAddress of
                Just sender ->
                    { from = sender
                    , to = List.Nonempty.fromElement { name = "Meetdown", email = emailAddress }
                    , subject = BackendLogic.loginEmailSubject
                    , body = Postmark.BodyHtml <| BackendLogic.loginEmailContent route loginToken maybeJoinEvent
                    , messageStream = "outbound"
                    }
                        |> Postmark.sendEmail msg Env.postmarkServerToken

                Nothing ->
                    Cmd.none
    , sendDeleteUserEmail =
        \msg emailAddress deleteUserToken ->
            case noReplyEmailAddress of
                Just sender ->
                    { from = sender
                    , to = List.Nonempty.fromElement { name = "Meetdown", email = emailAddress }
                    , subject = BackendLogic.deleteAccountEmailSubject
                    , body = Postmark.BodyHtml <| BackendLogic.deleteAccountEmailContent deleteUserToken
                    , messageStream = "outbound"
                    }
                        |> Postmark.sendEmail msg Env.postmarkServerToken

                Nothing ->
                    Cmd.none
    , sendEventReminderEmail =
        \msg groupId groupName event timezone emailAddress ->
            case noReplyEmailAddress of
                Just sender ->
                    { from = sender
                    , to = List.Nonempty.fromElement { name = "Meetdown", email = emailAddress }
                    , subject = BackendLogic.eventReminderEmailSubject groupName event timezone
                    , body = Postmark.BodyHtml <| BackendLogic.eventReminderEmailContent groupId groupName event
                    , messageStream = "outbound"
                    }
                        |> Postmark.sendEmail msg Env.postmarkServerToken

                Nothing ->
                    Cmd.none
    , getTime = \msg -> Time.now |> Task.perform msg
    }


allSubscriptions : Subscriptions (Sub BackendMsg)
allSubscriptions =
    { batch = Sub.batch
    , timeEvery = \duration msg -> Time.every (Duration.inMilliseconds duration) msg
    , onConnect =
        \msg ->
            Lamdera.onConnect
                (\sessionId clientId -> msg (Id.sessionIdFromString sessionId) (Id.clientIdFromString clientId))
    , onDisconnect =
        \msg ->
            Lamdera.onDisconnect
                (\sessionId clientId -> msg (Id.sessionIdFromString sessionId) (Id.clientIdFromString clientId))
    }
