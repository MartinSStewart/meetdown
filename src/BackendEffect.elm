module BackendEffect exposing (BackendEffect(..))

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
    | SendToFrontends (List ClientId) toFrontend
    | SendLoginEmail (Result Http.Error Postmark.PostmarkSendResponse -> backendMsg) EmailAddress Route (Id LoginToken) (Maybe ( Id GroupId, EventId ))
    | SendDeleteUserEmail (Result Http.Error Postmark.PostmarkSendResponse -> backendMsg) EmailAddress (Id DeleteUserToken)
    | SendEventReminderEmail (Result Http.Error Postmark.PostmarkSendResponse -> backendMsg) (Id GroupId) GroupName Event Time.Zone EmailAddress
    | GetTime (Time.Posix -> backendMsg)
