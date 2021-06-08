module Tests exposing (suite)

import Backend
import CreateGroupForm
import Date
import Duration
import EmailAddress exposing (EmailAddress)
import Env
import Frontend
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
                    |> TF.clickButton clientId Frontend.signUpOrLoginButtonId
                    |> TF.simulateTime Duration.second
                    |> TF.inputText clientId LoginForm.emailAddressInputId (EmailAddress.toString emailAddress)
                    |> TF.simulateTime Duration.second
                    |> (if loginWithEnterKey then
                            TF.keyDownEvent clientId LoginForm.emailAddressInputId Ui.enterKeyCode

                        else
                            TF.clickButton clientId LoginForm.submitButtonId
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
                    |> loginFromHomepage False session0 session0 (unsafeEmailAddress "a@a.se")
                    |> (\{ state, clientId, clientIdFromEmail } ->
                            createGroup clientIdFromEmail groupName groupDescription state
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
        , test "Create an event and get an email a day before it occurs" <|
            \_ ->
                let
                    session0 =
                        Id.sessionIdFromString "session0"

                    emailAddress =
                        unsafeEmailAddress "a@a.se"
                in
                TF.init
                    |> loginFromHomepage False session0 session0 emailAddress
                    |> (\{ state, clientId, clientIdFromEmail } ->
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
                                state
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
                    |> TF.finishSimulation
        , test "Create an event and but don't get a notification if it's occurring within 24 hours" <|
            \_ ->
                let
                    session0 =
                        Id.sessionIdFromString "session0"

                    emailAddress =
                        unsafeEmailAddress "a@a.se"
                in
                TF.init
                    |> loginFromHomepage False session0 session0 emailAddress
                    |> (\{ state, clientId, clientIdFromEmail } ->
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
                                state
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
                    |> TF.finishSimulation
        , test "Create an event and another user joins it and gets an event reminder" <|
            \_ ->
                let
                    session0 =
                        Id.sessionIdFromString "session0"

                    session1 =
                        Id.sessionIdFromString "session1"

                    emailAddress0 =
                        unsafeEmailAddress "a@a.se"

                    emailAddress1 =
                        unsafeEmailAddress "jim@a.com"

                    groupName =
                        unsafeGroupName "It's my Group!"
                in
                TF.init
                    |> loginFromHomepage False session0 session0 emailAddress0
                    |> (\{ state, clientId, clientIdFromEmail } ->
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
                                state
                       )
                    |> loginFromHomepage False session1 session1 emailAddress1
                    |> (\{ state, clientId, clientIdFromEmail } ->
                            state
                                |> TF.inputText clientId Frontend.groupSearchId "my group!"
                                |> TF.keyDownEvent clientId Frontend.groupSearchId Ui.enterKeyCode
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
                    |> TF.finishSimulation
        ]


gotReminder : a -> { b | emailInboxes : List ( a, EmailType ) } -> Maybe ( a, EmailType )
gotReminder emailAddress model =
    List.find
        (\( address, emailType ) ->
            address == emailAddress && TF.isEventReminderEmail emailType
        )
        model.emailInboxes


createGroup : Id.ClientId -> String -> String -> TF.State -> TF.State
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
    -> TF.State
    -> TF.State
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
