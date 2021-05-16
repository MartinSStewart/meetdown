module BackendEffect exposing (BackendEffect, batch, none, sendLoginEmail, sendToFrontend, toCmd)

import Email.Html
import Email.Html.Attributes
import EmailAddress exposing (EmailAddress)
import Env
import Id exposing (ClientId, CryptoHash, LoginToken)
import Lamdera
import List.Nonempty
import Route exposing (Route)
import SendGrid
import String.Nonempty exposing (NonemptyString(..))
import Types exposing (BackendMsg, ToFrontend)


type BackendEffect
    = Batch (List BackendEffect)
    | SendToFrontend ClientId ToFrontend
    | SendLoginEmail (Result SendGrid.Error () -> BackendMsg) EmailAddress Route (CryptoHash LoginToken)


none : BackendEffect
none =
    Batch []


batch : List BackendEffect -> BackendEffect
batch =
    Batch


sendToFrontend : ClientId -> ToFrontend -> BackendEffect
sendToFrontend =
    SendToFrontend


sendLoginEmail :
    (Result SendGrid.Error () -> BackendMsg)
    -> EmailAddress
    -> Route
    -> CryptoHash LoginToken
    -> BackendEffect
sendLoginEmail =
    SendLoginEmail


toCmd : BackendEffect -> Cmd BackendMsg
toCmd backendEffect =
    case backendEffect of
        Batch backendEffects ->
            Cmd.batch (List.map toCmd backendEffects)

        SendToFrontend clientId toFrontend ->
            Lamdera.sendToFrontend (Id.clientIdToString clientId) toFrontend

        SendLoginEmail msg email route loginToken ->
            let
                loginLink : String
                loginLink =
                    Route.encode route (Just loginToken)

                _ =
                    Debug.log "login" loginLink
            in
            case EmailAddress.fromString "noreply@meetdown.com" of
                Just sender ->
                    SendGrid.htmlEmail
                        { subject = NonemptyString 'M' "eetdown login link"
                        , content =
                            Email.Html.div
                                []
                                [ Email.Html.a
                                    [ Email.Html.Attributes.href loginLink ]
                                    [ Email.Html.text "Click here to log in." ]
                                , Email.Html.text " If you didn't request this email then it's safe to ignore it."
                                ]
                        , to = List.Nonempty.fromElement email
                        , emailAddressOfSender = sender
                        , nameOfSender = "Meetdown"
                        }
                        |> SendGrid.sendEmail msg Env.sendGridApiKey

                Nothing ->
                    Cmd.none
