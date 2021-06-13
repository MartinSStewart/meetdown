module BackendEffects exposing (BackendEffect(..), effects)

import BackendLogic exposing (Effects)
import EmailAddress exposing (EmailAddress)
import Event exposing (Event)
import Group exposing (EventId)
import GroupName exposing (GroupName)
import Id exposing (ClientId, DeleteUserToken, GroupId, Id, LoginToken)
import Route exposing (Route)
import SendGrid
import Time
import Types exposing (BackendMsg, ToFrontend)


type BackendEffect
    = Batch (List BackendEffect)
    | None
    | SendToFrontend ClientId ToFrontend
    | SendLoginEmail (Result SendGrid.Error () -> BackendMsg) EmailAddress Route (Id LoginToken) (Maybe ( GroupId, EventId ))
    | SendDeleteUserEmail (Result SendGrid.Error () -> BackendMsg) EmailAddress (Id DeleteUserToken)
    | SendEventReminderEmail (Result SendGrid.Error () -> BackendMsg) GroupId GroupName Event Time.Zone EmailAddress
    | GetTime (Time.Posix -> BackendMsg)


effects : Effects BackendEffect
effects =
    { batch = Batch
    , none = None
    , sendToFrontend = SendToFrontend
    , sendToFrontends =
        \clientIds toFrontend ->
            List.map (\clientId -> SendToFrontend clientId toFrontend) clientIds |> Batch
    , sendLoginEmail = SendLoginEmail
    , sendDeleteUserEmail = SendDeleteUserEmail
    , sendEventReminderEmail = SendEventReminderEmail
    , getTime = GetTime
    }
