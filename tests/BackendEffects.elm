module BackendEffects exposing (BackendEffect(..), effects)

import Backend
import EmailAddress exposing (EmailAddress)
import Id exposing (ClientId, DeleteUserToken, Id, LoginToken)
import Route exposing (Route)
import SendGrid
import Time
import Types exposing (BackendMsg, ToFrontend)


type BackendEffect
    = Batch (List BackendEffect)
    | None
    | SendToFrontend ClientId ToFrontend
    | SendLoginEmail (Result SendGrid.Error () -> BackendMsg) EmailAddress Route (Id LoginToken)
    | SendDeleteUserEmail (Result SendGrid.Error () -> BackendMsg) EmailAddress (Id DeleteUserToken)
    | GetTime (Time.Posix -> BackendMsg)


effects : Backend.Effects BackendEffect
effects =
    { batch = Batch
    , none = None
    , sendToFrontend = SendToFrontend
    , sendToFrontends =
        \clientIds toFrontend ->
            List.map (\clientId -> SendToFrontend clientId toFrontend) clientIds |> Batch
    , sendLoginEmail = SendLoginEmail
    , sendDeleteUserEmail = SendDeleteUserEmail
    , getTime = GetTime
    }
