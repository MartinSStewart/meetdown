module BackendEffect exposing (BackendEffect, batch, none, sendDeleteUserEmail, sendLoginEmail, sendToFrontend, sendToFrontends, toCmd)

import Email.Html
import Email.Html.Attributes
import EmailAddress exposing (EmailAddress)
import Env
import Id exposing (ClientId, DeleteUserToken, Id, LoginToken)
import Lamdera
import List.Nonempty exposing (Nonempty)
import Route exposing (Route(..))
import SendGrid
import String.Nonempty exposing (NonemptyString(..))
import Types exposing (BackendMsg, ToFrontend)


type BackendEffect
    = Batch (List BackendEffect)
    | SendToFrontend ClientId ToFrontend
    | SendLoginEmail (Result SendGrid.Error () -> BackendMsg) EmailAddress Route (Id LoginToken)
    | SendDeleteUserEmail (Result SendGrid.Error () -> BackendMsg) EmailAddress (Id DeleteUserToken)


none : BackendEffect
none =
    Batch []


batch : List BackendEffect -> BackendEffect
batch =
    Batch


sendToFrontend : ClientId -> ToFrontend -> BackendEffect
sendToFrontend =
    SendToFrontend


sendToFrontends : List ClientId -> ToFrontend -> BackendEffect
sendToFrontends clientIds toFrontend =
    clientIds |> List.map (\clientId -> sendToFrontend clientId toFrontend) |> batch


sendLoginEmail :
    (Result SendGrid.Error () -> BackendMsg)
    -> EmailAddress
    -> Route
    -> Id LoginToken
    -> BackendEffect
sendLoginEmail =
    SendLoginEmail


sendDeleteUserEmail :
    (Result SendGrid.Error () -> BackendMsg)
    -> EmailAddress
    -> Id DeleteUserToken
    -> BackendEffect
sendDeleteUserEmail =
    SendDeleteUserEmail


toCmd : BackendEffect -> Cmd BackendMsg
toCmd backendEffect =
    case backendEffect of
        Batch backendEffects ->
            Cmd.batch (List.map toCmd backendEffects)

        SendToFrontend clientId toFrontend ->
            Lamdera.sendToFrontend (Id.clientIdToString clientId) toFrontend

        SendLoginEmail msg emailAddress route loginToken ->
            let
                loginLink : String
                loginLink =
                    Env.domain ++ Route.encodeWithToken route (Route.LoginToken loginToken)

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
                        , to = List.Nonempty.fromElement emailAddress
                        , emailAddressOfSender = sender
                        , nameOfSender = "Meetdown"
                        }
                        |> SendGrid.sendEmail msg sendGridApiKey

                Nothing ->
                    Cmd.none

        SendDeleteUserEmail msg emailAddress deleteUserToken ->
            let
                deleteUserLink : String
                deleteUserLink =
                    Env.domain ++ Route.encodeWithToken HomepageRoute (Route.DeleteUserToken deleteUserToken)

                _ =
                    Debug.log "delete user" deleteUserLink
            in
            case EmailAddress.fromString "noreply@meetdown.com" of
                Just sender ->
                    SendGrid.htmlEmail
                        { subject = NonemptyString 'C' "onfirm account deletion"
                        , content =
                            Email.Html.div
                                []
                                [ Email.Html.a
                                    [ Email.Html.Attributes.href deleteUserLink ]
                                    [ Email.Html.text "Click here confirm you want to delete your account." ]
                                , Email.Html.text " Remember, this action can not be reversed! If you didn't request this email then it's safe to ignore it."
                                ]
                        , to = List.Nonempty.fromElement emailAddress
                        , emailAddressOfSender = sender
                        , nameOfSender = "Meetdown"
                        }
                        |> SendGrid.sendEmail msg sendGridApiKey

                Nothing ->
                    Cmd.none


sendGridApiKey : SendGrid.ApiKey
sendGridApiKey =
    SendGrid.apiKey Env.sendGridApiKey_
