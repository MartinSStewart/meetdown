module Tests exposing (suite)

import Backend
import Duration
import EmailAddress
import Env
import Frontend
import Id
import LoginForm
import Test exposing (..)
import TestFramework as TF exposing (EmailType(..))
import Types exposing (FrontendModel(..), LoginStatus(..))
import Ui


loginFromHomepage :
    Id.SessionId
    -> Id.SessionId
    -> EmailAddress.EmailAddress
    -> TF.State
    -> { state : TF.State, clientId : Id.ClientId, clientIdFromEmail : Id.ClientId }
loginFromHomepage sessionId sessionIdFromEmail emailAddress state =
    state
        |> TF.connectFrontend sessionId (TF.unsafeUrl Env.domain)
        |> (\( state2, clientId ) ->
                state2
                    |> TF.simulateTime Duration.second
                    |> TF.clickEvent clientId Frontend.signUpOrLoginButtonId
                    |> TF.simulateTime Duration.second
                    |> TF.inputEvent clientId LoginForm.emailAddressInputId (EmailAddress.toString emailAddress)
                    |> TF.simulateTime Duration.second
                    |> TF.keyDownEvent clientId LoginForm.emailAddressInputId Ui.enterKeyCode
                    |> TF.simulateTime Duration.second
                    |> (\state3 ->
                            case List.filter (Tuple.first >> (==) emailAddress) state3.emailInboxes of
                                [ ( _, LoginEmail route loginToken ) ] ->
                                    state3
                                        |> TF.connectFrontend
                                            sessionIdFromEmail
                                            (TF.unsafeUrl (Backend.loginEmailLink route loginToken))
                                        |> (\( state4, clientIdFromEmail ) ->
                                                { state = state4 |> TF.simulateTime Duration.second
                                                , clientId = clientId
                                                , clientIdFromEmail = clientIdFromEmail
                                                }
                                           )

                                _ ->
                                    Debug.todo "Should have gotten a login email"
                       )
           )


suite : Test
suite =
    describe "App tests"
        [ test "login test" <|
            \_ ->
                let
                    session0 =
                        Id.sessionIdFromString "session0"

                    emailAddress =
                        TF.unsafeEmailAddress "a@a.se"
                in
                TF.init
                    |> TF.connectFrontend session0 (TF.unsafeUrl Env.domain)
                    |> (\( state, clientId ) ->
                            state
                                |> TF.simulateTime Duration.second
                                |> TF.clickEvent clientId Frontend.signUpOrLoginButtonId
                                |> TF.simulateTime Duration.second
                                |> TF.inputEvent clientId LoginForm.emailAddressInputId (EmailAddress.toString emailAddress)
                                |> TF.simulateTime Duration.second
                                |> TF.keyDownEvent clientId LoginForm.emailAddressInputId Ui.enterKeyCode
                                |> TF.simulateTime Duration.second
                                |> (\state2 ->
                                        case List.filter (Tuple.first >> (==) emailAddress) state2.emailInboxes of
                                            [ ( _, LoginEmail route loginToken ) ] ->
                                                state2
                                                    |> TF.connectFrontend
                                                        session0
                                                        (TF.unsafeUrl (Backend.loginEmailLink route loginToken))
                                                    |> (\( state3, clientId2 ) ->
                                                            state3
                                                                |> TF.simulateTime Duration.second
                                                                |> TF.checkLoadedFrontend
                                                                    clientId2
                                                                    (\frontend ->
                                                                        case frontend.loginStatus of
                                                                            LoggedIn loggedIn ->
                                                                                if loggedIn.emailAddress == emailAddress then
                                                                                    Ok ()

                                                                                else
                                                                                    "Incorrect email address "
                                                                                        ++ EmailAddress.toString loggedIn.emailAddress
                                                                                        |> Err

                                                                            _ ->
                                                                                Err "Failed to log in"
                                                                    )
                                                       )

                                            _ ->
                                                Debug.todo "Should have gotten a login email"
                                   )
                       )
                    |> TF.finishSimulation
        ]
