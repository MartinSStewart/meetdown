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
    Bool
    -> Id.SessionId
    -> Id.SessionId
    -> EmailAddress.EmailAddress
    -> TF.State
    -> { state : TF.State, clientId : Id.ClientId, clientIdFromEmail : Id.ClientId }
loginFromHomepage loginWithEnterKey sessionId sessionIdFromEmail emailAddress state =
    state
        |> TF.connectFrontend sessionId (TF.unsafeUrl Env.domain)
        |> (\( state2, clientId ) ->
                state2
                    |> TF.simulateTime Duration.second
                    |> TF.clickEvent clientId Frontend.signUpOrLoginButtonId
                    |> TF.simulateTime Duration.second
                    |> TF.inputEvent clientId LoginForm.emailAddressInputId (EmailAddress.toString emailAddress)
                    |> TF.simulateTime Duration.second
                    |> (if loginWithEnterKey then
                            TF.keyDownEvent clientId LoginForm.emailAddressInputId Ui.enterKeyCode

                        else
                            TF.clickEvent clientId LoginForm.submitButtonId
                       )
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
        [ test "Login from homepage and submit with login button" <|
            \_ ->
                let
                    sessionId =
                        Id.sessionIdFromString "session0"

                    emailAddress =
                        TF.unsafeEmailAddress "a@a.se"
                in
                TF.init
                    |> loginFromHomepage False sessionId sessionId emailAddress
                    |> (\{ state, clientId, clientIdFromEmail } ->
                            state
                                |> TF.checkLoadedFrontend
                                    clientIdFromEmail
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
                    |> TF.finishSimulation
        , test "Login from homepage and submit with enter key" <|
            \_ ->
                let
                    sessionId =
                        Id.sessionIdFromString "session0"

                    emailAddress =
                        TF.unsafeEmailAddress "a@a.se"
                in
                TF.init
                    |> loginFromHomepage True sessionId sessionId emailAddress
                    |> (\{ state, clientId, clientIdFromEmail } ->
                            state
                                |> TF.checkLoadedFrontend
                                    clientIdFromEmail
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
                    |> TF.finishSimulation
        , test "Login from homepage and check that original clientId also got logged in since it's on the same session" <|
            \_ ->
                let
                    sessionId =
                        Id.sessionIdFromString "session0"

                    emailAddress =
                        TF.unsafeEmailAddress "a@a.se"
                in
                TF.init
                    |> loginFromHomepage True sessionId sessionId emailAddress
                    |> (\{ state, clientId, clientIdFromEmail } ->
                            state
                                |> TF.checkLoadedFrontend
                                    clientId
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
                    |> TF.finishSimulation
        , test "Login from homepage and check that original clientId did not get logged since it has a different sessionId" <|
            \_ ->
                TF.init
                    |> loginFromHomepage
                        True
                        (Id.sessionIdFromString "session0")
                        (Id.sessionIdFromString "session1")
                        (TF.unsafeEmailAddress "a@a.se")
                    |> (\{ state, clientId, clientIdFromEmail } ->
                            state
                                |> TF.checkLoadedFrontend
                                    clientId
                                    (\frontend ->
                                        case frontend.loginStatus of
                                            LoggedIn _ ->
                                                Err "Should not have been logged in"

                                            NotLoggedIn _ ->
                                                Ok ()

                                            LoginStatusPending ->
                                                Err "Failed to check login"
                                    )
                       )
                    |> TF.finishSimulation
        , test "Login from homepage and check it's not possible to use the same login token twice" <|
            \_ ->
                let
                    emailAddress =
                        TF.unsafeEmailAddress "a@a.se"

                    sessionId =
                        Id.sessionIdFromString "session0"
                in
                TF.init
                    |> loginFromHomepage True sessionId sessionId emailAddress
                    |> (\{ state, clientId, clientIdFromEmail } ->
                            case List.filter (Tuple.first >> (==) emailAddress) state.emailInboxes of
                                [ ( _, LoginEmail route loginToken ) ] ->
                                    state
                                        |> TF.connectFrontend
                                            (Id.sessionIdFromString "session1")
                                            (TF.unsafeUrl (Backend.loginEmailLink route loginToken))
                                        |> (\( state2, clientId3 ) ->
                                                state2
                                                    |> TF.simulateTime Duration.second
                                                    --|> Debug.log "test"
                                                    |> TF.checkLoadedFrontend
                                                        clientId3
                                                        (\frontend ->
                                                            case frontend.loginStatus of
                                                                LoggedIn _ ->
                                                                    Err "Should not have been logged in"

                                                                NotLoggedIn _ ->
                                                                    if frontend.hasLoginTokenError then
                                                                        Ok ()

                                                                    else
                                                                        Err "Correctly didn't log in but failed to show error"

                                                                LoginStatusPending ->
                                                                    Err "Failed to check login"
                                                        )
                                           )

                                _ ->
                                    Debug.todo "Didn't find login email"
                       )
                    |> TF.finishSimulation

        --, only <|
        --    test "test" <|
        --        \_ ->
        --            TF.init
        --                |> TF.connectFrontend (Id.sessionIdFromString "sessionId0") (TF.unsafeUrl Env.domain)
        --                |> Tuple.first
        --                |> TF.simulateStep
        --                |> TF.simulateStep
        --                |> TF.finishSimulation
        ]
