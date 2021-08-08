module Tests exposing (createEventAndAnotherUserNotLoggedInButWithAnExistingAccountJoinsIt, createEventAndAnotherUserNotLoggedInJoinsIt, suite)

import AssocList as Dict
import BackendLogic
import CreateGroupPage
import Date
import Duration
import EmailAddress exposing (EmailAddress)
import Env
import FrontendLogic
import Group
import GroupName exposing (GroupName)
import GroupPage
import Id exposing (GroupId, Id)
import List.Extra as List
import LoginForm
import ProfilePage
import Quantity
import Route
import Test exposing (..)
import Test.Html.Query
import Test.Html.Selector
import TestFramework as TF exposing (EmailType(..))
import Time
import Types exposing (FrontendModel(..), LoginStatus(..), ToBackend(..))
import Ui
import Unsafe
import Untrusted


loginFromHomepage :
    Bool
    -> Id.SessionId
    -> Id.SessionId
    -> EmailAddress.EmailAddress
    -> ({ instructions : TF.Instructions, clientId : Id.ClientId, clientIdFromEmail : Id.ClientId } -> TF.Instructions)
    -> TF.Instructions
    -> TF.Instructions
loginFromHomepage loginWithEnterKey sessionId sessionIdFromEmail emailAddress stateFunc =
    TF.connectFrontend sessionId
        (Unsafe.url Env.domain)
        (\( state3, clientId ) ->
            state3
                |> TF.simulateTime Duration.second
                |> TF.clickButton clientId FrontendLogic.signUpOrLoginButtonId
                |> handleLoginForm loginWithEnterKey clientId sessionIdFromEmail emailAddress stateFunc
        )


handleLoginForm :
    Bool
    -> Id.ClientId
    -> Id.SessionId
    -> EmailAddress
    -> ({ instructions : TF.Instructions, clientId : Id.ClientId, clientIdFromEmail : Id.ClientId } -> TF.Instructions)
    -> TF.Instructions
    -> TF.Instructions
handleLoginForm loginWithEnterKey clientId sessionIdFromEmail emailAddress andThenFunc state =
    state
        |> TF.simulateTime Duration.second
        |> TF.inputText clientId LoginForm.emailAddressInputId (EmailAddress.toString emailAddress)
        |> TF.simulateTime Duration.second
        |> (if loginWithEnterKey then
                TF.keyDownEvent clientId LoginForm.emailAddressInputId Ui.enterKeyCode

            else
                TF.clickButton clientId LoginForm.submitButtonId
           )
        |> TF.simulateTime Duration.second
        |> TF.andThen
            (\state3 ->
                case List.filter (Tuple.first >> (==) emailAddress) state3.emailInboxes |> List.reverse |> List.head of
                    Just ( _, LoginEmail route loginToken maybeJoinEvent ) ->
                        TF.continueWith state3
                            |> TF.connectFrontend
                                sessionIdFromEmail
                                (Unsafe.url (BackendLogic.loginEmailLink route loginToken maybeJoinEvent))
                                (\( state4, clientIdFromEmail ) ->
                                    andThenFunc
                                        { instructions = state4 |> TF.simulateTime Duration.second
                                        , clientId = clientId
                                        , clientIdFromEmail = clientIdFromEmail
                                        }
                                )

                    _ ->
                        TF.continueWith state3 |> TF.checkState (\_ -> Err "Should have gotten a login email")
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
                        Unsafe.emailAddress "the@email.com"
                in
                TF.init
                    |> loginFromHomepage False
                        sessionId
                        sessionId
                        emailAddress
                        (\{ instructions, clientId, clientIdFromEmail } ->
                            instructions
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
                    |> TF.toExpectation
        , test "Login from homepage and submit with enter key" <|
            \_ ->
                let
                    sessionId =
                        Id.sessionIdFromString "session0"

                    emailAddress =
                        Unsafe.emailAddress "the@email.com"
                in
                TF.init
                    |> loginFromHomepage
                        True
                        sessionId
                        sessionId
                        emailAddress
                        (\{ instructions, clientId, clientIdFromEmail } ->
                            instructions
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
                    |> TF.toExpectation
        , test "Login from homepage and check that original clientId also got logged in since it's on the same session" <|
            \_ ->
                let
                    sessionId =
                        Id.sessionIdFromString "session0"

                    emailAddress =
                        Unsafe.emailAddress "the@email.com"
                in
                TF.init
                    |> loginFromHomepage
                        True
                        sessionId
                        sessionId
                        emailAddress
                        (\{ instructions, clientId, clientIdFromEmail } ->
                            instructions
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
                    |> TF.toExpectation
        , test "Login from homepage and check that original clientId did not get logged since it has a different sessionId" <|
            \_ ->
                TF.init
                    |> loginFromHomepage
                        True
                        (Id.sessionIdFromString "session0")
                        (Id.sessionIdFromString "session1")
                        (Unsafe.emailAddress "the@email.com")
                        (\{ instructions, clientId, clientIdFromEmail } ->
                            instructions
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
                    |> TF.toExpectation
        , test "Login from homepage and check it's not possible to use the same login token twice" <|
            \_ ->
                let
                    emailAddress =
                        Unsafe.emailAddress "the@email.com"

                    sessionId =
                        Id.sessionIdFromString "session0"
                in
                TF.init
                    |> loginFromHomepage True
                        sessionId
                        sessionId
                        emailAddress
                        (\{ instructions, clientId, clientIdFromEmail } ->
                            instructions
                                |> TF.andThen
                                    (\state ->
                                        case List.filter (Tuple.first >> (==) emailAddress) state.emailInboxes of
                                            [ ( _, LoginEmail route loginToken maybeJoinEvent ) ] ->
                                                TF.continueWith state
                                                    |> TF.connectFrontend
                                                        (Id.sessionIdFromString "session1")
                                                        (Unsafe.url (BackendLogic.loginEmailLink route loginToken maybeJoinEvent))
                                                        (\( state2, clientId3 ) ->
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
                        )
                    |> TF.toExpectation
        , test "Creating a group redirects to newly created group page" <|
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
                    |> loginFromHomepage False
                        session0
                        session0
                        (Unsafe.emailAddress "the@email.com")
                        (\{ instructions, clientId, clientIdFromEmail } ->
                            createGroup clientIdFromEmail groupName groupDescription instructions
                                |> TF.checkFrontend clientIdFromEmail
                                    (\model ->
                                        case model of
                                            Loaded loaded ->
                                                case Dict.keys loaded.cachedGroups of
                                                    [ groupId ] ->
                                                        if loaded.route == Route.GroupRoute groupId (Unsafe.groupName groupName) then
                                                            Ok ()

                                                        else
                                                            Err "Was redirected to incorrect route"

                                                    _ ->
                                                        Err "No cached groups were found"

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
                    |> TF.toExpectation
        , test "Create an event and get an email a day before it occurs" <|
            \_ ->
                let
                    session0 =
                        Id.sessionIdFromString "session0"

                    emailAddress =
                        Unsafe.emailAddress "the@email.com"
                in
                TF.init
                    |> loginFromHomepage False
                        session0
                        session0
                        emailAddress
                        (\{ instructions, clientId, clientIdFromEmail } ->
                            createGroupAndEvent
                                clientId
                                { groupName = "It's my Group!"
                                , groupDescription = "This is the best group"
                                , eventName = "First group event!"
                                , eventDescription = "We're gonna party!"
                                , eventDate = Date.fromPosix Time.utc (Duration.addTo TF.startTime (Duration.days 3))
                                , eventHour = 14
                                , eventMinute = 0
                                , eventDuration = "1"
                                }
                                instructions
                                |> TF.fastForward (Duration.days 1.999 |> Quantity.plus (Duration.hours 14))
                                |> TF.checkState
                                    (\model ->
                                        case gotReminder emailAddress model of
                                            Just _ ->
                                                Err "Shouldn't have gotten an event notification yet"

                                            Nothing ->
                                                Ok ()
                                    )
                                |> TF.simulateTime (Duration.days 0.002)
                                |> TF.checkState
                                    (\model ->
                                        case gotReminder emailAddress model of
                                            Just _ ->
                                                Ok ()

                                            Nothing ->
                                                Err "Should have gotten an event notification"
                                    )
                        )
                    |> TF.toExpectation
        , test "Create an event and but don't get a notification if it's occurring within 24 hours" <|
            \_ ->
                let
                    session0 =
                        Id.sessionIdFromString "session0"

                    emailAddress =
                        Unsafe.emailAddress "the@email.com"
                in
                TF.init
                    |> loginFromHomepage False
                        session0
                        session0
                        emailAddress
                        (\{ instructions, clientId, clientIdFromEmail } ->
                            createGroupAndEvent
                                clientId
                                { groupName = "It's my Group!"
                                , groupDescription = "This is the best group"
                                , eventName = "First group event!"
                                , eventDescription = "We're gonna party!"
                                , eventDate = Date.fromPosix Time.utc TF.startTime
                                , eventHour = 14
                                , eventMinute = 0
                                , eventDuration = "1"
                                }
                                instructions
                                |> TF.fastForward (Duration.hours 1.99)
                                |> TF.simulateTime (Duration.hours 0.02)
                                |> TF.checkState
                                    (\model ->
                                        case gotReminder emailAddress model of
                                            Just _ ->
                                                Err "Shouldn't have gotten an event notification"

                                            Nothing ->
                                                Ok ()
                                    )
                        )
                    |> TF.toExpectation
        , test "Create an event and another user joins it and gets an event reminder" <|
            \_ ->
                let
                    session0 =
                        Id.sessionIdFromString "session0"

                    session1 =
                        Id.sessionIdFromString "session1"

                    emailAddress0 =
                        Unsafe.emailAddress "the@email.com"

                    emailAddress1 =
                        Unsafe.emailAddress "jim@a.com"

                    groupName =
                        Unsafe.groupName "It's my Group!"
                in
                TF.init
                    |> loginFromHomepage False
                        session0
                        session0
                        emailAddress0
                        (\{ instructions, clientId, clientIdFromEmail } ->
                            createGroupAndEvent
                                clientId
                                { groupName = GroupName.toString groupName
                                , groupDescription = "This is the best group"
                                , eventName = "First group event!"
                                , eventDescription = "We're gonna party!"
                                , eventDate = Date.fromPosix Time.utc (Duration.addTo TF.startTime Duration.day)
                                , eventHour = 14
                                , eventMinute = 0
                                , eventDuration = "1"
                                }
                                instructions
                        )
                    |> loginFromHomepage False
                        session1
                        session1
                        emailAddress1
                        (\{ instructions, clientId, clientIdFromEmail } ->
                            findSingleGroup
                                (\groupId inProgress2 ->
                                    inProgress2
                                        |> TF.inputText clientId FrontendLogic.groupSearchId "my group!"
                                        |> TF.keyDownEvent clientId FrontendLogic.groupSearchId Ui.enterKeyCode
                                        |> TF.simulateTime Duration.second
                                        |> TF.clickLink clientId (Route.GroupRoute groupId groupName)
                                        |> TF.simulateTime Duration.second
                                        |> TF.clickButton clientId GroupPage.joinEventButtonId
                                        |> TF.simulateTime Duration.second
                                        |> TF.fastForward (Duration.hours 14)
                                        |> TF.simulateTime (Duration.seconds 30)
                                        |> TF.checkState
                                            (\model ->
                                                case gotReminder emailAddress1 model of
                                                    Just _ ->
                                                        Ok ()

                                                    Nothing ->
                                                        Err "Should have gotten an event notification"
                                            )
                                )
                                instructions
                        )
                    |> TF.toExpectation
        , test "Create an event and another user (who isn't logged in) joins it" <|
            \_ -> TF.toExpectation createEventAndAnotherUserNotLoggedInJoinsIt
        , test "Create an event and another user (who isn't logged in but has an account) joins it" <|
            \_ -> TF.toExpectation createEventAndAnotherUserNotLoggedInButWithAnExistingAccountJoinsIt
        , test "Rate limit login for a given email address" <|
            \_ ->
                let
                    connectAndLogin count =
                        TF.connectFrontend
                            (Id.sessionIdFromString <| "session " ++ String.fromInt count)
                            (Unsafe.url Env.domain)
                            (\( state, clientId ) ->
                                state
                                    |> TF.simulateTime Duration.second
                                    |> TF.clickButton clientId FrontendLogic.signUpOrLoginButtonId
                                    |> TF.inputText clientId LoginForm.emailAddressInputId "my+good@email.eu"
                                    |> TF.clickButton clientId LoginForm.submitButtonId
                                    |> TF.simulateTime Duration.second
                            )
                in
                TF.init
                    |> connectAndLogin 1
                    |> connectAndLogin 2
                    |> connectAndLogin 3
                    |> connectAndLogin 4
                    |> TF.checkState
                        (\state2 ->
                            if List.length state2.emailInboxes == 1 then
                                Ok ()

                            else
                                Err "Only one email should have been sent"
                        )
                    |> TF.simulateTime (Duration.minutes 2)
                    |> connectAndLogin 5
                    |> TF.checkState
                        (\state2 ->
                            if List.length state2.emailInboxes == 2 then
                                Ok ()

                            else
                                Err "Two emails should have been sent"
                        )
                    |> TF.toExpectation
        , test "Rate limit login for a given session" <|
            \_ ->
                let
                    session0 =
                        Id.sessionIdFromString "session0"
                in
                TF.init
                    |> TF.connectFrontend
                        session0
                        (Unsafe.url Env.domain)
                        (\( state, clientId ) ->
                            state
                                |> TF.simulateTime Duration.second
                                |> TF.clickButton clientId FrontendLogic.signUpOrLoginButtonId
                                |> TF.inputText clientId LoginForm.emailAddressInputId "a@email.eu"
                                |> TF.clickButton clientId LoginForm.submitButtonId
                                |> TF.simulateTime Duration.second
                                |> TF.inputText clientId LoginForm.emailAddressInputId "b@email.eu"
                                |> TF.clickButton clientId LoginForm.submitButtonId
                                |> TF.simulateTime Duration.second
                                |> TF.inputText clientId LoginForm.emailAddressInputId "c@email.eu"
                                |> TF.clickButton clientId LoginForm.submitButtonId
                                |> TF.simulateTime Duration.second
                                |> TF.inputText clientId LoginForm.emailAddressInputId "d@email.eu"
                                |> TF.clickButton clientId LoginForm.submitButtonId
                                |> TF.simulateTime Duration.second
                                |> TF.inputText clientId LoginForm.emailAddressInputId "e@email.eu"
                                |> TF.clickButton clientId LoginForm.submitButtonId
                                |> TF.simulateTime Duration.second
                                |> TF.checkState
                                    (\state2 ->
                                        let
                                            count =
                                                List.length state2.emailInboxes
                                        in
                                        if count == 1 then
                                            Ok ()

                                        else
                                            "Only one email should have been sent, got "
                                                ++ String.fromInt count
                                                ++ " instead"
                                                |> Err
                                    )
                                |> TF.simulateTime Duration.minute
                                |> TF.inputText clientId LoginForm.emailAddressInputId "e@email.eu"
                                |> TF.clickButton clientId LoginForm.submitButtonId
                                |> TF.simulateTime Duration.second
                                |> TF.checkState
                                    (\state2 ->
                                        let
                                            count =
                                                List.length state2.emailInboxes
                                        in
                                        if count == 2 then
                                            Ok ()

                                        else
                                            "Two emails should have been sent, got "
                                                ++ String.fromInt count
                                                ++ " instead"
                                                |> Err
                                    )
                        )
                    |> TF.toExpectation
        , test "Rate limit delete account email" <|
            \_ ->
                let
                    session0 =
                        Id.sessionIdFromString "session0"

                    emailAddress =
                        Unsafe.emailAddress "a@email.eu"
                in
                TF.init
                    |> loginFromHomepage
                        True
                        session0
                        session0
                        emailAddress
                        (\{ instructions, clientId, clientIdFromEmail } ->
                            instructions
                                |> TF.simulateTime Duration.second
                                |> TF.clickLink clientId Route.MyProfileRoute
                                |> TF.clickButton clientId ProfilePage.deleteAccountButtonId
                                |> TF.simulateTime Duration.second
                                |> TF.clickButton clientId ProfilePage.deleteAccountButtonId
                                |> TF.simulateTime Duration.second
                                |> TF.clickButton clientId ProfilePage.deleteAccountButtonId
                                |> TF.simulateTime Duration.second
                                |> TF.clickButton clientId ProfilePage.deleteAccountButtonId
                                |> TF.simulateTime Duration.second
                                |> TF.checkState
                                    (\state2 ->
                                        let
                                            count =
                                                List.count
                                                    (\( address, email ) ->
                                                        address == emailAddress && TF.isDeleteAccountEmail email
                                                    )
                                                    state2.emailInboxes
                                        in
                                        if count == 1 then
                                            Ok ()

                                        else
                                            "Only one account deletion email should have been sent, got "
                                                ++ String.fromInt count
                                                ++ " instead"
                                                |> Err
                                    )
                                |> TF.simulateTime (Duration.minutes 1.5)
                                |> TF.clickButton clientId ProfilePage.deleteAccountButtonId
                                |> TF.simulateTime Duration.second
                                |> TF.checkState
                                    (\state2 ->
                                        let
                                            count =
                                                List.count
                                                    (\( address, email ) ->
                                                        address == emailAddress && TF.isDeleteAccountEmail email
                                                    )
                                                    state2.emailInboxes
                                        in
                                        if count == 2 then
                                            Ok ()

                                        else
                                            "Two account deletion emails should have been sent, got "
                                                ++ String.fromInt count
                                                ++ " instead"
                                                |> Err
                                    )
                        )
                    |> TF.toExpectation
        , test "Not logged in users can't create groups" <|
            \_ ->
                let
                    sessionId =
                        Id.sessionIdFromString "sessionId"
                in
                TF.init
                    |> TF.connectFrontend
                        sessionId
                        (Env.domain ++ Route.encode Route.HomepageRoute |> Unsafe.url)
                        (\( instructions, clientId ) ->
                            instructions
                                |> TF.sendToBackend
                                    sessionId
                                    clientId
                                    (CreateGroupRequest
                                        (Unsafe.groupName "group" |> Untrusted.untrust)
                                        (Unsafe.description "description" |> Untrusted.untrust)
                                        Group.PublicGroup
                                    )
                        )
                    |> TF.simulateTime Duration.second
                    |> TF.checkBackend
                        (\backend ->
                            if Dict.isEmpty backend.groups then
                                Ok ()

                            else
                                Err "No group should have been created"
                        )
                    |> TF.toExpectation
        , test "Non-admin users can't delete groups" <|
            \_ ->
                let
                    sessionId =
                        Id.sessionIdFromString "sessionId"

                    attackerSessionId =
                        Id.sessionIdFromString "sessionIdAttacker"

                    emailAddress =
                        Unsafe.emailAddress "my@email.com"

                    attackerEmailAddress =
                        Unsafe.emailAddress "hacker@email.com"
                in
                TF.init
                    |> loginFromHomepage
                        True
                        sessionId
                        sessionId
                        emailAddress
                        (\{ instructions, clientId } ->
                            instructions |> createGroup clientId "group" "description"
                        )
                    |> TF.simulateTime Duration.second
                    |> loginFromHomepage
                        False
                        attackerSessionId
                        attackerSessionId
                        attackerEmailAddress
                        (\{ instructions, clientId } ->
                            findSingleGroup
                                (\groupId instructions2 ->
                                    instructions2
                                        |> TF.sendToBackend
                                            sessionId
                                            clientId
                                            (DeleteGroupAdminRequest groupId)
                                )
                                instructions
                        )
                    |> TF.simulateTime Duration.second
                    |> TF.checkBackend
                        (\backend ->
                            if Dict.isEmpty backend.deletedGroups && Dict.size backend.groups == 1 then
                                Ok ()

                            else
                                Err "No group should have been deleted"
                        )
                    |> TF.toExpectation
        ]


findSingleGroup : (Id GroupId -> TF.Instructions -> TF.Instructions) -> TF.Instructions -> TF.Instructions
findSingleGroup continueWith inProgress =
    inProgress
        |> TF.andThen
            (\state ->
                case Dict.keys state.backend.groups of
                    [ groupId ] ->
                        TF.continueWith state
                            |> continueWith groupId

                    keys ->
                        TF.continueWith state
                            |> TF.checkState
                                (\_ ->
                                    "Expected to find exactly one group, instead got "
                                        ++ String.fromInt (List.length keys)
                                        |> Err
                                )
            )


createEventAndAnotherUserNotLoggedInJoinsIt : TF.Instructions
createEventAndAnotherUserNotLoggedInJoinsIt =
    let
        session0 =
            Id.sessionIdFromString "session0"

        session1 =
            Id.sessionIdFromString "session1"

        emailAddress0 =
            Unsafe.emailAddress "the@email.se"

        emailAddress1 =
            Unsafe.emailAddress "jim@a.com"

        groupName =
            Unsafe.groupName "It's my Group!"
    in
    TF.init
        |> loginFromHomepage False
            session0
            session0
            emailAddress0
            (\{ instructions, clientId, clientIdFromEmail } ->
                createGroupAndEvent
                    clientId
                    { groupName = GroupName.toString groupName
                    , groupDescription = "This is the best group"
                    , eventName = "First group event!"
                    , eventDescription = "We're gonna party!"
                    , eventDate = Date.fromPosix Time.utc (Duration.addTo TF.startTime Duration.day)
                    , eventHour = 14
                    , eventMinute = 0
                    , eventDuration = "1"
                    }
                    instructions
            )
        |> TF.connectFrontend session1
            (Env.domain ++ Route.encode Route.HomepageRoute |> Unsafe.url)
            (\( instructions, clientId ) ->
                findSingleGroup
                    (\groupId inProgress2 ->
                        inProgress2
                            |> TF.simulateTime Duration.second
                            |> TF.inputText clientId FrontendLogic.groupSearchId "my group!"
                            |> TF.keyDownEvent clientId FrontendLogic.groupSearchId Ui.enterKeyCode
                            |> TF.simulateTime Duration.second
                            |> TF.clickLink clientId (Route.GroupRoute groupId groupName)
                            |> TF.simulateTime Duration.second
                            |> TF.clickButton clientId GroupPage.joinEventButtonId
                            |> TF.simulateTime Duration.second
                            |> handleLoginForm
                                True
                                clientId
                                session1
                                emailAddress1
                                (\a ->
                                    a.instructions
                                        |> TF.simulateTime Duration.second
                                        -- We are just clicking the leave button to test that we had joined the event.
                                        |> TF.clickButton a.clientIdFromEmail GroupPage.leaveEventButtonId
                                )
                    )
                    instructions
            )


createEventAndAnotherUserNotLoggedInButWithAnExistingAccountJoinsIt : TF.Instructions
createEventAndAnotherUserNotLoggedInButWithAnExistingAccountJoinsIt =
    let
        session0 =
            Id.sessionIdFromString "session0"

        session1 =
            Id.sessionIdFromString "session1"

        emailAddress0 =
            Unsafe.emailAddress "the@email.com"

        emailAddress1 =
            Unsafe.emailAddress "jim@a.com"

        groupName =
            Unsafe.groupName "It's my Group!"
    in
    TF.init
        |> loginFromHomepage False
            session0
            session0
            emailAddress0
            (\{ instructions, clientId, clientIdFromEmail } ->
                createGroupAndEvent
                    clientId
                    { groupName = GroupName.toString groupName
                    , groupDescription = "This is the best group"
                    , eventName = "First group event!"
                    , eventDescription = "We're gonna party!"
                    , eventDate = Date.fromPosix Time.utc (Duration.addTo TF.startTime Duration.day)
                    , eventHour = 14
                    , eventMinute = 0
                    , eventDuration = "1"
                    }
                    instructions
            )
        |> loginFromHomepage False
            session1
            session1
            emailAddress1
            (\{ instructions, clientIdFromEmail } ->
                instructions
                    |> TF.simulateTime Duration.second
                    |> TF.clickButton clientIdFromEmail FrontendLogic.logOutButtonId
                    |> TF.simulateTime Duration.minute
            )
        |> TF.connectFrontend session1
            (Env.domain ++ Route.encode Route.HomepageRoute |> Unsafe.url)
            (\( instructions, clientId ) ->
                findSingleGroup
                    (\groupId inProgress2 ->
                        inProgress2
                            |> TF.simulateTime Duration.second
                            |> TF.inputText clientId FrontendLogic.groupSearchId "my group!"
                            |> TF.keyDownEvent clientId FrontendLogic.groupSearchId Ui.enterKeyCode
                            |> TF.simulateTime Duration.second
                            |> TF.clickLink clientId (Route.GroupRoute groupId groupName)
                            |> TF.simulateTime Duration.second
                            |> TF.clickButton clientId GroupPage.joinEventButtonId
                            |> TF.simulateTime Duration.second
                            |> handleLoginForm
                                True
                                clientId
                                session1
                                emailAddress1
                                (\a ->
                                    a.instructions
                                        |> TF.simulateTime Duration.second
                                        -- We are just clicking the leave button to test that we had joined the event.
                                        |> TF.clickButton a.clientIdFromEmail GroupPage.leaveEventButtonId
                                )
                    )
                    instructions
            )


gotReminder : a -> { b | emailInboxes : List ( a, EmailType ) } -> Maybe ( a, EmailType )
gotReminder emailAddress model =
    List.find
        (\( address, emailType ) ->
            address == emailAddress && TF.isEventReminderEmail emailType
        )
        model.emailInboxes


createGroup : Id.ClientId -> String -> String -> TF.Instructions -> TF.Instructions
createGroup loggedInClient groupName groupDescription state =
    state
        |> TF.clickLink loggedInClient Route.CreateGroupRoute
        |> TF.simulateTime Duration.second
        |> TF.inputText loggedInClient CreateGroupPage.nameInputId groupName
        |> TF.inputText loggedInClient CreateGroupPage.descriptionInputId groupDescription
        |> TF.clickRadioButton loggedInClient (CreateGroupPage.groupVisibilityId Group.PublicGroup)
        |> TF.clickButton loggedInClient CreateGroupPage.submitButtonId
        |> TF.simulateTime Duration.second


createGroupAndEvent :
    Id.ClientId
    ->
        { groupName : String
        , groupDescription : String
        , eventName : String
        , eventDescription : String
        , eventDate : Date.Date
        , eventHour : Int
        , eventMinute : Int
        , eventDuration : String
        }
    -> TF.Instructions
    -> TF.Instructions
createGroupAndEvent loggedInClient { groupName, groupDescription, eventName, eventDescription, eventDate, eventHour, eventMinute, eventDuration } state =
    createGroup loggedInClient groupName groupDescription state
        |> TF.clickButton loggedInClient GroupPage.createNewEventId
        |> TF.inputText loggedInClient GroupPage.eventNameInputId eventName
        |> TF.inputText loggedInClient GroupPage.eventDescriptionInputId eventDescription
        |> TF.clickRadioButton loggedInClient (GroupPage.eventMeetingTypeId GroupPage.MeetOnline)
        |> TF.inputDate loggedInClient GroupPage.createEventStartDateId eventDate
        |> TF.inputTime loggedInClient GroupPage.createEventStartTimeId eventHour eventMinute
        |> TF.inputNumber loggedInClient GroupPage.eventDurationId eventDuration
        |> TF.clickButton loggedInClient GroupPage.createEventSubmitId
        |> TF.simulateTime Duration.second
