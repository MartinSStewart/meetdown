module Tests exposing (suite)

import AssocList as Dict
import Backend
import CreateGroupForm
import Duration
import EmailAddress exposing (EmailAddress)
import Env
import Frontend
import Group
import GroupName exposing (GroupName)
import Id
import LoginForm
import Route
import Test exposing (..)
import Test.Html.Query
import Test.Html.Selector
import TestFramework as TF exposing (EmailType(..))
import Types exposing (FrontendModel(..), LoginStatus(..))
import Ui
import Url exposing (Url)


loginFromHomepage :
    Bool
    -> Id.SessionId
    -> Id.SessionId
    -> EmailAddress.EmailAddress
    -> TF.State
    -> { state : TF.State, clientId : Id.ClientId, clientIdFromEmail : Id.ClientId }
loginFromHomepage loginWithEnterKey sessionId sessionIdFromEmail emailAddress state =
    state
        |> TF.connectFrontend sessionId (unsafeUrl Env.domain)
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
                                            (unsafeUrl (Backend.loginEmailLink route loginToken))
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
                        unsafeEmailAddress "a@a.se"
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
                        unsafeEmailAddress "a@a.se"
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
                        unsafeEmailAddress "a@a.se"
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
                        (unsafeEmailAddress "a@a.se")
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
                        unsafeEmailAddress "a@a.se"

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
                                            (unsafeUrl (Backend.loginEmailLink route loginToken))
                                        |> (\( state2, clientId3 ) ->
                                                state2
                                                    |> TF.simulateTime Duration.second
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
        , test "Creating a group redirects to group page and updates backend" <|
            \_ ->
                let
                    session0 =
                        Id.sessionIdFromString "session0"

                    groupName =
                        "It's my Group!"

                    groupDescription =
                        "This is the best group"
                in
                TF.init
                    |> loginFromHomepage False session0 session0 (unsafeEmailAddress "a@a.se")
                    |> (\{ state, clientId, clientIdFromEmail } ->
                            state
                                |> TF.clickLink clientIdFromEmail Route.CreateGroupRoute
                                |> TF.simulateTime Duration.second
                                |> TF.inputEvent clientIdFromEmail CreateGroupForm.nameInputId groupName
                                |> TF.inputEvent clientIdFromEmail CreateGroupForm.descriptionInputId groupDescription
                                |> TF.clickEvent clientIdFromEmail (CreateGroupForm.groupVisibilityId Group.PublicGroup)
                                |> TF.clickEvent clientIdFromEmail CreateGroupForm.submitButtonId
                                |> TF.simulateTime Duration.second
                                |> TF.checkFrontend clientIdFromEmail
                                    (\model ->
                                        case model of
                                            Loaded loaded ->
                                                if loaded.route == Route.GroupRoute (Id.groupIdFromInt 0) (unsafeGroupName groupName) then
                                                    Ok ()

                                                else
                                                    Err "Was redirected to incorrect route"

                                            Loading _ ->
                                                Err "Somehow we ended up in the loading state"
                                    )
                                |> TF.checkView
                                    clientIdFromEmail
                                    (Test.Html.Query.has
                                        [ Test.Html.Selector.text groupName
                                        , Test.Html.Selector.text groupDescription
                                        ]
                                    )
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


unsafeUrl : String -> Url
unsafeUrl urlText =
    case Url.fromString urlText of
        Just url ->
            url

        Nothing ->
            Debug.todo ("Invalid url " ++ urlText)


unsafeEmailAddress : String -> EmailAddress
unsafeEmailAddress text =
    case EmailAddress.fromString text of
        Just address ->
            address

        Nothing ->
            Debug.todo ("Invalid email address " ++ text)


unsafeGroupName : String -> GroupName
unsafeGroupName name =
    case GroupName.fromString name of
        Ok value ->
            value

        Err _ ->
            Debug.todo ("Invalid group name " ++ name)
