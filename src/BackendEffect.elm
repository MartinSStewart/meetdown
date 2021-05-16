module BackendEffect exposing (BackendEffect, batch, none, sendLoginEmail, sendToFrontend, toCmd)

import Email exposing (Email)
import Email.Html
import Email.Html.Attributes
import Env
import Id exposing (ClientId, CryptoHash, LoginToken)
import Lamdera
import List.Nonempty
import Route exposing (Route)
import SendGrid
import String.Nonempty exposing (NonemptyString(..))
import Types exposing (BackendMsg, ToFrontend)
import Url.Builder


type BackendEffect
    = Batch (List BackendEffect)
    | SendToFrontend ClientId ToFrontend
    | SendLoginEmail (Result SendGrid.Error () -> BackendMsg) Email Route (CryptoHash LoginToken)


none : BackendEffect
none =
    Batch []


batch : List BackendEffect -> BackendEffect
batch =
    Batch


sendToFrontend : ClientId -> ToFrontend -> BackendEffect
sendToFrontend =
    SendToFrontend


sendLoginEmail : (Result SendGrid.Error () -> BackendMsg) -> Email -> Route -> CryptoHash LoginToken -> BackendEffect
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

                --Url.Builder.crossOrigin
                --    Env.domain
                --    []
                --    [ Url.Builder.string Route.loginToken (Id.cryptoHashToString loginToken) ]
                _ =
                    Debug.log "login" loginLink
            in
            case Email.fromString "noreply@meetdown.com" of
                Just sender ->
                    SendGrid.htmlEmail
                        { subject = NonemptyString 'H' "ere's your login link"
                        , content =
                            Email.Html.a
                                [ Email.Html.Attributes.src loginLink ]
                                [ Email.Html.text "Click here to log in." ]
                        , to = List.Nonempty.fromElement email
                        , emailAddressOfSender = sender
                        , nameOfSender = "Meetdown"
                        }
                        |> SendGrid.sendEmail msg Env.sendGridApiKey

                Nothing ->
                    Cmd.none
