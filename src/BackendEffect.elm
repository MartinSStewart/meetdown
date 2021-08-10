module BackendEffect exposing (BackendEffect(..), map)

import EmailAddress exposing (EmailAddress)
import Event exposing (Event)
import Group exposing (EventId)
import GroupName exposing (GroupName)
import Http
import Id exposing (ClientId, DeleteUserToken, GroupId, Id, LoginToken)
import Postmark
import Route exposing (Route)
import Time


type BackendEffect toFrontend backendMsg
    = Batch (List (BackendEffect toFrontend backendMsg))
    | None
    | SendToFrontend ClientId toFrontend
    | SendLoginEmail (Result Http.Error Postmark.PostmarkSendResponse -> backendMsg) EmailAddress Route (Id LoginToken) (Maybe ( Id GroupId, EventId ))
    | SendDeleteUserEmail (Result Http.Error Postmark.PostmarkSendResponse -> backendMsg) EmailAddress (Id DeleteUserToken)
    | SendEventReminderEmail (Result Http.Error Postmark.PostmarkSendResponse -> backendMsg) (Id GroupId) GroupName Event Time.Zone EmailAddress
    | GetTime (Time.Posix -> backendMsg)


map :
    (toFrontendA -> toFrontendB)
    -> (backendMsgA -> backendMsgB)
    -> BackendEffect toFrontendA backendMsgA
    -> BackendEffect toFrontendB backendMsgB
map mapToFrontend mapBackendMsg backendEffect =
    case backendEffect of
        Batch backendEffects ->
            List.map (map mapToFrontend mapBackendMsg) backendEffects |> Batch

        None ->
            None

        SendToFrontend clientId toFrontend ->
            SendToFrontend clientId (mapToFrontend toFrontend)

        SendLoginEmail msg emailAddress route id maybe ->
            SendLoginEmail (msg >> mapBackendMsg) emailAddress route id maybe

        SendDeleteUserEmail msg emailAddress id ->
            SendDeleteUserEmail (msg >> mapBackendMsg) emailAddress id

        SendEventReminderEmail msg id groupName event zone emailAddress ->
            SendEventReminderEmail (msg >> mapBackendMsg) id groupName event zone emailAddress

        GetTime msg ->
            GetTime (msg >> mapBackendMsg)
