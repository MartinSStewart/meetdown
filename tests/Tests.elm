module Tests exposing (createEventAndAnotherUserNotLoggedInJoinsIt, suite)

import BackendLogic
import CreateGroupForm
import Date
import Duration
import EmailAddress exposing (EmailAddress)
import Env
import FrontendLogic
import Group
import GroupName exposing (GroupName)
import GroupPage
import Id
import List.Extra as List
import LoginForm
import Quantity
import Route
import Test exposing (..)
import Test.Html.Query
import Test.Html.Selector
import TestFramework as TF exposing (EmailType(..))
import Time
import Types exposing (FrontendModel(..), LoginStatus(..))
import Ui
import Unsafe


loginFromHomepage :
    Bool
    -> Id.SessionId
    -> Id.SessionId
    -> EmailAddress.EmailAddress
    -> ({ inProgress : TF.Instructions, clientId : Id.ClientId, clientIdFromEmail : Id.ClientId } -> TF.Instructions)
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
    -> ({ inProgress : TF.Instructions, clientId : Id.ClientId, clientIdFromEmail : Id.ClientId } -> TF.Instructions)
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
                case List.filter (Tuple.first >> (==) emailAddress) state3.emailInboxes of
                    [ ( _, LoginEmail route loginToken maybeJoinEvent ) ] ->
                        TF.continueWith state3
                            |> TF.connectFrontend
                                sessionIdFromEmail
                                (Unsafe.url (BackendLogic.loginEmailLink route loginToken maybeJoinEvent))
                                (\( state4, clientIdFromEmail ) ->
                                    andThenFunc
                                        { inProgress = state4 |> TF.simulateTime Duration.second
                                        , clientId = clientId
                                        , clientIdFromEmail = clientIdFromEmail
                                        }
                                )

                    _ ->
                        Debug.todo "Should have gotten a login email"
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
                        Unsafe.emailAddress "a@a.se"
                in
                TF.init
                    |> loginFromHomepage False
                        sessionId
                        sessionId
                        emailAddress
                        (\{ inProgress, clientId, clientIdFromEmail } ->
                            inProgress
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
                        Unsafe.emailAddress "a@a.se"
                in
                TF.init
                    |> loginFromHomepage
                        True
                        sessionId
                        sessionId
                        emailAddress
                        (\{ inProgress, clientId, clientIdFromEmail } ->
                            inProgress
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
                        Unsafe.emailAddress "a@a.se"
                in
                TF.init
                    |> loginFromHomepage
                        True
                        sessionId
                        sessionId
                        emailAddress
                        (\{ inProgress, clientId, clientIdFromEmail } ->
                            inProgress
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
                        (Unsafe.emailAddress "a@a.se")
                        (\{ inProgress, clientId, clientIdFromEmail } ->
                            inProgress
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
                        Unsafe.emailAddress "a@a.se"

                    sessionId =
                        Id.sessionIdFromString "session0"
                in
                TF.init
                    |> loginFromHomepage True
                        sessionId
                        sessionId
                        emailAddress
                        (\{ inProgress, clientId, clientIdFromEmail } ->
                            inProgress
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
                        (Unsafe.emailAddress "a@a.se")
                        (\{ inProgress, clientId, clientIdFromEmail } ->
                            createGroup clientIdFromEmail groupName groupDescription inProgress
                                |> TF.checkFrontend clientIdFromEmail
                                    (\model ->
                                        case model of
                                            Loaded loaded ->
                                                if loaded.route == Route.GroupRoute (Id.groupIdFromInt 0) (Unsafe.groupName groupName) then
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
                    |> TF.toExpectation
        , test "Create an event and get an email a day before it occurs" <|
            \_ ->
                let
                    session0 =
                        Id.sessionIdFromString "session0"

                    emailAddress =
                        Unsafe.emailAddress "a@a.se"
                in
                TF.init
                    |> loginFromHomepage False
                        session0
                        session0
                        emailAddress
                        (\{ inProgress, clientId, clientIdFromEmail } ->
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
                                inProgress
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
                        Unsafe.emailAddress "a@a.se"
                in
                TF.init
                    |> loginFromHomepage False
                        session0
                        session0
                        emailAddress
                        (\{ inProgress, clientId, clientIdFromEmail } ->
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
                                inProgress
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
                        Unsafe.emailAddress "a@a.se"

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
                        (\{ inProgress, clientId, clientIdFromEmail } ->
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
                                inProgress
                        )
                    |> loginFromHomepage False
                        session1
                        session1
                        emailAddress1
                        (\{ inProgress, clientId, clientIdFromEmail } ->
                            inProgress
                                |> TF.inputText clientId FrontendLogic.groupSearchId "my group!"
                                |> TF.keyDownEvent clientId FrontendLogic.groupSearchId Ui.enterKeyCode
                                |> TF.simulateTime Duration.second
                                |> TF.clickLink clientId (Route.GroupRoute (Id.groupIdFromInt 0) groupName)
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
                    |> TF.toExpectation
        , test "Create an event and another user (who isn't logged in) joins it" <|
            \_ ->
                TF.toExpectation createEventAndAnotherUserNotLoggedInJoinsIt
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
        ]


createEventAndAnotherUserNotLoggedInJoinsIt : TF.Instructions
createEventAndAnotherUserNotLoggedInJoinsIt =
    let
        session0 =
            Id.sessionIdFromString "session0"

        session1 =
            Id.sessionIdFromString "session1"

        emailAddress0 =
            Unsafe.emailAddress "a@a.se"

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
            (\{ inProgress, clientId, clientIdFromEmail } ->
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
                    inProgress
            )
        |> TF.connectFrontend session1
            (Env.domain ++ Route.encode Route.HomepageRoute |> Unsafe.url)
            (\( state, clientId ) ->
                state
                    |> TF.simulateTime Duration.second
                    |> TF.inputText clientId FrontendLogic.groupSearchId "my group!"
                    |> TF.keyDownEvent clientId FrontendLogic.groupSearchId Ui.enterKeyCode
                    |> TF.simulateTime Duration.second
                    |> TF.clickLink clientId (Route.GroupRoute (Id.groupIdFromInt 0) groupName)
                    |> TF.simulateTime Duration.second
                    |> TF.clickButton clientId GroupPage.joinEventButtonId
                    |> TF.simulateTime Duration.second
                    |> handleLoginForm
                        True
                        clientId
                        session1
                        emailAddress1
                        (\a ->
                            a.inProgress
                                |> TF.simulateTime Duration.second
                                -- We are just clicking the leave button to test that we had joined the event.
                                |> TF.clickButton a.clientIdFromEmail GroupPage.leaveEventButtonId
                        )
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
        |> TF.inputText loggedInClient CreateGroupForm.nameInputId groupName
        |> TF.inputText loggedInClient CreateGroupForm.descriptionInputId groupDescription
        |> TF.clickRadioButton loggedInClient (CreateGroupForm.groupVisibilityId Group.PublicGroup)
        |> TF.clickButton loggedInClient CreateGroupForm.submitButtonId
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
