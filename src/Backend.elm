module Backend exposing
    ( app
    , init
    , loginEmailLinkAbsolutePath
    , subscriptions
    , update
    , updateFromFrontend
    )

import Address
import Array
import BiDict.Assoc2 as BiDict
import Bytes
import Bytes.Encode as Encode
import CreateGroupPage exposing (CreateGroupError(..))
import Date
import Description exposing (Description)
import Duration
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Http as Http
import Effect.Lamdera exposing (ClientId, SessionId)
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Task as Task
import Effect.Time as Time
import Email.Html
import Email.Html.Attributes
import EmailAddress exposing (EmailAddress)
import Env
import Event exposing (Event)
import EventName
import Group exposing (EventId, Group, GroupVisibility)
import GroupName exposing (GroupName)
import GroupPage exposing (CreateEventError(..))
import Ics
import Id exposing (DeleteUserToken, GroupId, Id, LoginToken, UserId)
import Lamdera
import Link
import List.Extra as List
import List.Nonempty
import Name
import Postmark
import ProfileImage
import ProfilePage
import Quantity
import Route exposing (Route(..))
import SendGrid
import SeqDict as Dict
import SeqSet as Set
import String.Nonempty exposing (NonemptyString(..))
import TimeExtra
import Toop exposing (T5(..))
import Types exposing (..)
import Untrusted


app =
    Effect.Lamdera.backend
        Lamdera.broadcast
        Lamdera.sendToFrontend
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = subscriptions
        }


loginEmailLink : Route -> Id LoginToken -> Maybe ( Id GroupId, EventId ) -> String
loginEmailLink route loginToken maybeJoinEvent =
    Env.domain ++ loginEmailLinkAbsolutePath route loginToken maybeJoinEvent


loginEmailLinkAbsolutePath : Route -> Id LoginToken -> Maybe ( Id GroupId, EventId ) -> String
loginEmailLinkAbsolutePath route loginToken maybeJoinEvent =
    Route.encodeWithToken route (Route.LoginToken loginToken maybeJoinEvent)


init : ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
init =
    ( { users = Dict.empty
      , groups = Dict.empty
      , deletedGroups = Dict.empty
      , sessions = BiDict.empty
      , loginAttempts = Dict.empty
      , connections = Dict.empty
      , logs = Array.empty
      , time = Time.millisToPosix 0
      , secretCounter = 0
      , pendingLoginTokens = Dict.empty
      , pendingDeleteUserTokens = Dict.empty
      }
    , Time.now |> Task.perform BackendGotTime
    )



--
--fakeInit : ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
--fakeInit =
--    let
--        _ =
--            Debug.toString "This prevents accidentally deploying fakeInit to production"
--    in
--    ( { users =
--            Dict.fromList
--                [ ( Id "a"
--                  , { name = Unsafe.name "Person H Personson"
--                    , description = Unsafe.description "asdf"
--                    , emailAddress = Unsafe.emailAddress "as2df@asdf.com"
--                    , profileImage = DefaultImage
--                    , timezone = Time.utc
--                    , allowEventReminders = False
--                    , subscribedGroups = Set.empty
--                    }
--                  )
--                , ( Id "b"
--                  , { name = Unsafe.name "Steve Longlastnameerson"
--                    , description = Unsafe.description "asdf"
--                    , emailAddress = Unsafe.emailAddress "asd2f@asdf.com"
--                    , profileImage = DefaultImage
--                    , timezone = Time.utc
--                    , allowEventReminders = False
--                    , subscribedGroups = Set.empty
--                    }
--                  )
--                , ( Id "c"
--                  , { name = Name.anonymous
--                    , description = Unsafe.description "asdf"
--                    , emailAddress = Unsafe.emailAddress "asdf@asdf.com"
--                    , profileImage = DefaultImage
--                    , timezone = Time.utc
--                    , allowEventReminders = False
--                    , subscribedGroups = Set.empty
--                    }
--                  )
--                ]
--      , groups =
--            Dict.fromList
--                [ ( Id "10001"
--                  , Group.init
--                        (Id "a")
--                        (Unsafe.groupName "groupName")
--                        (Unsafe.description "asdf")
--                        Group.PublicGroup
--                        (Time.millisToPosix 0)
--                        |> Unsafe.addEvent
--                            (Event.newEvent
--                                (Id "a")
--                                (Unsafe.eventName "event")
--                                (Unsafe.description "asdf")
--                                (Event.MeetOnline Nothing)
--                                (Time.millisToPosix 20000)
--                                (Unsafe.eventDurationFromMinutes 10000)
--                                (Time.millisToPosix 10000)
--                                NoLimit
--                                |> Unsafe.addAttendee (Id "b")
--                                |> Unsafe.addAttendee (Id "c")
--                            )
--                        |> Unsafe.addEvent
--                            (Event.newEvent
--                                (Id "a")
--                                (Unsafe.eventName "event")
--                                (Unsafe.description "asdf")
--                                (Event.MeetOnline Nothing)
--                                (Time.millisToPosix 2000000000000000)
--                                (Unsafe.eventDurationFromMinutes 10000)
--                                (Time.millisToPosix 1000000000000000)
--                                NoLimit
--                                |> Unsafe.addAttendee (Id "b")
--                                |> Unsafe.addAttendee (Id "c")
--                            )
--                  )
--                ]
--      , deletedGroups = Dict.empty
--      , sessions = BiDict.empty
--      , loginAttempts = Dict.empty
--      , connections = Dict.empty
--      , logs = Array.empty
--      , time = Time.millisToPosix 0
--      , secretCounter = 0
--      , pendingLoginTokens = Dict.empty
--      , pendingDeleteUserTokens = Dict.empty
--      }
--    , Time.now |> Task.perform BackendGotTime
--    )


subscriptions : BackendModel -> Subscription BackendOnly BackendMsg
subscriptions _ =
    Subscription.batch
        [ Time.every (Duration.seconds 15) BackendGotTime
        , Effect.Lamdera.onConnect Connected
        , Effect.Lamdera.onDisconnect Disconnected
        ]


handleNotifications : Time.Posix -> Time.Posix -> BackendModel -> Command BackendOnly ToFrontend BackendMsg
handleNotifications lastCheck currentTime backendModel =
    Dict.toList backendModel.groups
        |> List.concatMap
            (\( groupId, group ) ->
                let
                    { futureEvents } =
                        Group.events currentTime group
                in
                List.concatMap
                    (\( eventId, event ) ->
                        let
                            start =
                                Event.startTime event
                        in
                        if
                            (Duration.from lastCheck start |> Quantity.greaterThan Duration.day)
                                && not (Duration.from currentTime start |> Quantity.greaterThan Duration.day)
                        then
                            Event.attendees event
                                |> Set.toList
                                |> List.filterMap
                                    (\userId ->
                                        case getUser userId backendModel of
                                            Just user ->
                                                sendEventReminderEmail
                                                    (SentEventReminderEmail userId groupId eventId)
                                                    groupId
                                                    (Group.name group)
                                                    event
                                                    user.timezone
                                                    user.emailAddress
                                                    |> Just

                                            Nothing ->
                                                Nothing
                                    )

                        else
                            []
                    )
                    futureEvents
            )
        |> Command.batch


update : BackendMsg -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
update msg model =
    case msg of
        SentLoginEmail userId result ->
            ( addLog (LogLoginEmail model.time result userId) model, Command.none )

        BackendGotTime time ->
            ( { model
                | time = time
                , loginAttempts =
                    Dict.toList model.loginAttempts
                        |> List.filterMap
                            (\( sessionId, logins ) ->
                                List.Nonempty.toList logins
                                    |> List.filter
                                        (\loginTime -> Duration.from loginTime time |> Quantity.lessThan (Duration.seconds 30))
                                    |> List.Nonempty.fromList
                                    |> Maybe.map (Tuple.pair sessionId)
                            )
                        |> Dict.fromList
              }
            , handleNotifications model.time time model
            )

        Connected sessionId clientId ->
            ( { model
                | connections =
                    Dict.update sessionId
                        (Maybe.map (List.Nonempty.cons clientId)
                            >> Maybe.withDefault (List.Nonempty.fromElement clientId)
                            >> Just
                        )
                        model.connections
              }
            , Command.none
            )

        Disconnected sessionId clientId ->
            ( { model
                | connections =
                    Dict.update sessionId
                        (Maybe.andThen (List.Nonempty.toList >> List.remove clientId >> List.Nonempty.fromList))
                        model.connections
              }
            , Command.none
            )

        SentDeleteUserEmail userId result ->
            ( addLog (LogDeleteAccountEmail model.time result userId) model, Command.none )

        SentEventReminderEmail userId groupId eventId result ->
            ( addLog (LogEventReminderEmail model.time result userId groupId eventId) model, Command.none )

        SentNewEventNotificationEmail userId groupId result ->
            ( addLog (LogNewEventNotificationEmail model.time result userId groupId) model, Command.none )

        NoOpBackendMsg ->
            ( model, Command.none )


addLog : Log -> BackendModel -> BackendModel
addLog log model =
    { model | logs = Array.push log model.logs }


sendToFrontends : List ClientId -> ToFrontend -> Command BackendOnly ToFrontend backendMsg
sendToFrontends clientIds toFrontend =
    List.map (\clientId -> Effect.Lamdera.sendToFrontend clientId toFrontend) clientIds |> Command.batch


noReplyEmailAddress : Maybe EmailAddress
noReplyEmailAddress =
    EmailAddress.fromString "no-reply@meetdown.app"


sendLoginEmail :
    (Result Http.Error Postmark.PostmarkSendResponse -> backendMsg)
    -> EmailAddress
    -> Route
    -> Id LoginToken
    -> Maybe ( Id GroupId, EventId )
    -> Command BackendOnly toFrontend backendMsg
sendLoginEmail msg emailAddress route loginToken maybeJoinEvent =
    case noReplyEmailAddress of
        Just sender ->
            { from = { name = "Meetdown", email = sender }
            , to = List.Nonempty.fromElement { name = "", email = emailAddress }
            , subject = loginEmailSubject
            , body = Postmark.BodyHtml (loginEmailContent route loginToken maybeJoinEvent)
            , messageStream = "outbound"
            }
                |> Postmark.sendEmail msg Env.postmarkServerToken

        Nothing ->
            Command.none


sendDeleteUserEmail :
    (Result Http.Error Postmark.PostmarkSendResponse -> backendMsg)
    -> EmailAddress
    -> Id DeleteUserToken
    -> Command BackendOnly toFrontend backendMsg
sendDeleteUserEmail msg emailAddress deleteUserToken =
    case noReplyEmailAddress of
        Just sender ->
            { from = { name = "Meetdown", email = sender }
            , to = List.Nonempty.fromElement { name = "", email = emailAddress }
            , subject = deleteAccountEmailSubject
            , body = Postmark.BodyHtml (deleteAccountEmailContent deleteUserToken)
            , messageStream = "outbound"
            }
                |> Postmark.sendEmail msg Env.postmarkServerToken

        Nothing ->
            Command.none


sendEventReminderEmail :
    (Result Http.Error Postmark.PostmarkSendResponse -> backendMsg)
    -> Id GroupId
    -> GroupName
    -> Event
    -> Time.Zone
    -> EmailAddress
    -> Command BackendOnly toFrontend backendMsg
sendEventReminderEmail msg groupId groupName event timezone emailAddress =
    case noReplyEmailAddress of
        Just sender ->
            { from = { name = "Meetdown", email = sender }
            , to = List.Nonempty.fromElement { name = "", email = emailAddress }
            , subject = eventReminderEmailSubject groupName event timezone
            , body = Postmark.BodyHtml (eventReminderEmailContent groupId groupName event)
            , messageStream = "broadcast"
            }
                |> Postmark.sendEmail msg Env.postmarkServerToken

        Nothing ->
            Command.none


sendNewEventNotificationEmail :
    (Result Http.Error Postmark.PostmarkSendResponse -> backendMsg)
    -> Id GroupId
    -> GroupName
    -> Event
    -> Time.Posix
    -> Time.Zone
    -> EmailAddress
    -> Command BackendOnly toFrontend backendMsg
sendNewEventNotificationEmail msg groupId groupName event currentTime timezone emailAddress =
    case noReplyEmailAddress of
        Just sender ->
            { from = { name = "Meetdown", email = sender }
            , to = List.Nonempty.fromElement { name = "", email = emailAddress }
            , subject = newEventNotificationEmailSubject groupName event currentTime timezone
            , body = Postmark.BodyHtml (newEventNotificationEmailContent groupId groupName event currentTime timezone)
            , messageStream = "broadcast"
            }
                |> Postmark.sendEmail msg Env.postmarkServerToken

        Nothing ->
            Command.none


updateFromFrontend : SessionId -> ClientId -> ToBackend -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
updateFromFrontend sessionId clientId msg model =
    let
        logUntrusted =
            ( addLog (LogUntrustedCheckFailed model.time msg (Id.anonymizeSessionId sessionId)) model
            , Command.none
            )
    in
    case msg of
        GetGroupRequest groupId ->
            ( model
            , (case getGroup groupId model of
                Just group ->
                    case getUserFromSessionId sessionId model of
                        Just ( userId, _ ) ->
                            GroupFound_
                                group
                                (if userId == Group.ownerId group then
                                    Dict.empty

                                 else
                                    case getUser (Group.ownerId group) model of
                                        Just groupOwner ->
                                            Dict.singleton (Group.ownerId group) (userToFrontend groupOwner)

                                        Nothing ->
                                            Dict.empty
                                )

                        Nothing ->
                            GroupFound_ group
                                (case getUser (Group.ownerId group) model of
                                    Just user ->
                                        Dict.singleton (Group.ownerId group) (userToFrontend user)

                                    Nothing ->
                                        Dict.empty
                                )

                Nothing ->
                    GroupNotFound_
              )
                |> GetGroupResponse groupId
                |> Effect.Lamdera.sendToFrontend clientId
            )

        GetUserRequest userIds ->
            ( model
            , List.Nonempty.toList userIds
                |> List.foldl
                    (\userId response ->
                        Dict.insert
                            userId
                            (case getUser userId model of
                                Just user ->
                                    Ok (Types.userToFrontend user)

                                Nothing ->
                                    Err ()
                            )
                            response
                    )
                    Dict.empty
                |> GetUserResponse
                |> Effect.Lamdera.sendToFrontend clientId
            )

        CheckLoginRequest ->
            ( model, checkLogin sessionId model |> CheckLoginResponse |> Effect.Lamdera.sendToFrontend clientId )

        GetLoginTokenRequest route untrustedEmail maybeJoinEvent ->
            case Untrusted.emailAddress untrustedEmail of
                Just email ->
                    let
                        ( model2, loginToken ) =
                            Id.getUniqueId model
                    in
                    if loginIsRateLimited sessionId email model then
                        ( addLog
                            (LogLoginTokenEmailRequestRateLimited model.time email (Id.anonymizeSessionId sessionId))
                            model
                        , Command.none
                        )

                    else
                        ( { model2
                            | pendingLoginTokens =
                                Dict.insert
                                    loginToken
                                    { creationTime = model2.time, emailAddress = email }
                                    model2.pendingLoginTokens
                            , loginAttempts =
                                Dict.update
                                    sessionId
                                    (\maybeAttempts ->
                                        case maybeAttempts of
                                            Just attempts ->
                                                List.Nonempty.cons model.time attempts |> Just

                                            Nothing ->
                                                List.Nonempty.fromElement model.time |> Just
                                    )
                                    model.loginAttempts
                          }
                        , sendLoginEmail (SentLoginEmail email) email route loginToken maybeJoinEvent
                        )

                Nothing ->
                    logUntrusted

        GetAdminDataRequest ->
            adminAuthorization
                sessionId
                model
                (\_ ->
                    ( model
                    , Effect.Lamdera.sendToFrontend
                        clientId
                        (GetAdminDataResponse
                            { cachedEmailAddress = Dict.map (\_ value -> value.emailAddress) model.users
                            , logs = model.logs
                            , lastLogCheck = model.time
                            }
                        )
                    )
                )

        LoginWithTokenRequest loginToken maybeJoinEvent ->
            getAndRemoveLoginToken (loginWithToken sessionId clientId maybeJoinEvent) loginToken model

        LogoutRequest ->
            ( { model | sessions = BiDict.remove sessionId model.sessions }
            , case Dict.get sessionId model.connections of
                Just clientIds ->
                    sendToFrontends (List.Nonempty.toList clientIds) LogoutResponse

                Nothing ->
                    Command.none
            )

        CreateGroupRequest untrustedName untrustedDescription visibility ->
            userAuthorization
                sessionId
                model
                (\( userId, _ ) ->
                    case
                        ( Untrusted.groupName untrustedName
                        , Untrusted.description untrustedDescription
                        )
                    of
                        ( Just groupName, Just description ) ->
                            addGroup clientId userId groupName description visibility model

                        _ ->
                            logUntrusted
                )

        ProfileFormRequest (ProfilePage.ChangeNameRequest untrustedName) ->
            case Untrusted.name untrustedName of
                Just name ->
                    userAuthorization
                        sessionId
                        model
                        (\( userId, user ) ->
                            ( { model | users = Dict.insert userId { user | name = name } model.users }
                            , sendToFrontends
                                (getClientIdsForUser userId model)
                                (ChangeNameResponse name)
                            )
                        )

                Nothing ->
                    logUntrusted

        ProfileFormRequest (ProfilePage.ChangeDescriptionRequest untrustedDescription) ->
            case Untrusted.description untrustedDescription of
                Just description ->
                    userAuthorization
                        sessionId
                        model
                        (\( userId, user ) ->
                            ( { model | users = Dict.insert userId { user | description = description } model.users }
                            , sendToFrontends
                                (getClientIdsForUser userId model)
                                (ChangeDescriptionResponse description)
                            )
                        )

                Nothing ->
                    logUntrusted

        ProfileFormRequest (ProfilePage.ChangeEmailAddressRequest untrustedEmailAddress) ->
            case Untrusted.emailAddress untrustedEmailAddress of
                Just emailAddress ->
                    userAuthorization
                        sessionId
                        model
                        (\( userId, user ) ->
                            ( { model
                                | users =
                                    Dict.insert
                                        userId
                                        { user | emailAddress = emailAddress }
                                        model.users
                              }
                            , sendToFrontends
                                (getClientIdsForUser userId model)
                                (ChangeEmailAddressResponse emailAddress)
                            )
                        )

                Nothing ->
                    logUntrusted

        ProfileFormRequest ProfilePage.SendDeleteUserEmailRequest ->
            userAuthorization
                sessionId
                model
                (\( userId, user ) ->
                    let
                        rateLimited =
                            Dict.toList model.pendingDeleteUserTokens
                                |> List.filter (Tuple.second >> .userId >> (==) userId)
                                |> List.maximumBy (Tuple.second >> .creationTime >> Time.posixToMillis)
                                |> Maybe.map
                                    (\( _, { creationTime } ) ->
                                        Duration.from creationTime model.time |> Quantity.lessThan (Duration.seconds 10)
                                    )
                                |> Maybe.withDefault False

                        ( model2, deleteUserToken ) =
                            Id.getUniqueId model
                    in
                    if rateLimited then
                        ( addLog
                            (LogDeleteAccountEmailRequestRateLimited model.time userId (Id.anonymizeSessionId sessionId))
                            model
                        , Command.none
                        )

                    else
                        ( { model2
                            | pendingDeleteUserTokens =
                                Dict.insert
                                    deleteUserToken
                                    { creationTime = model.time, userId = userId }
                                    model2.pendingDeleteUserTokens
                          }
                        , sendDeleteUserEmail
                            (SentDeleteUserEmail userId)
                            user.emailAddress
                            deleteUserToken
                        )
                )

        DeleteUserRequest deleteUserToken ->
            getAndRemoveDeleteUserToken (handleDeleteUserRequest clientId) deleteUserToken model

        ProfileFormRequest (ProfilePage.ChangeProfileImageRequest untrustedProfileImage) ->
            userAuthorization
                sessionId
                model
                (\( userId, user ) ->
                    case Untrusted.profileImage untrustedProfileImage of
                        Just profileImage ->
                            let
                                response =
                                    ChangeProfileImageResponse profileImage
                            in
                            ( { model
                                | users =
                                    Dict.insert
                                        userId
                                        { user | profileImage = profileImage }
                                        model.users
                              }
                            , sendToFrontends (getClientIdsForUser userId model) response
                            )

                        Nothing ->
                            logUntrusted
                )

        GetMyGroupsRequest ->
            userAuthorization
                sessionId
                model
                (\( userId, user ) ->
                    ( model
                    , GetMyGroupsResponse
                        { myGroups =
                            Dict.toList model.groups
                                |> List.filter (\( _, group ) -> Group.ownerId group == userId)
                        , subscribedGroups =
                            List.filterMap
                                (\groupId -> getGroup groupId model |> Maybe.map (Tuple.pair groupId))
                                (Set.toList user.subscribedGroups)
                        }
                        |> Effect.Lamdera.sendToFrontend clientId
                    )
                )

        SearchGroupsRequest searchText ->
            if String.length searchText < 1000 then
                ( model
                , Dict.toList model.groups
                    |> List.filter (Tuple.second >> Group.visibility >> (==) Group.PublicGroup)
                    |> List.sortBy
                        (\( _, group ) ->
                            let
                                events =
                                    Group.events model.time group

                                futureEvents =
                                    List.filter (Tuple.second >> Event.isCancelled >> not) events.futureEvents
                            in
                            if events.ongoingEvent /= Nothing then
                                -- Lowest value is highest priority
                                0

                            else if List.isEmpty futureEvents then
                                if List.isEmpty events.pastEvents then
                                    3

                                else
                                    2

                            else
                                1
                        )
                    |> SearchGroupsResponse searchText
                    |> Effect.Lamdera.sendToFrontend clientId
                )

            else
                ( model, Command.none )

        GroupRequest groupId (GroupPage.ChangeGroupNameRequest untrustedName) ->
            case Untrusted.groupName untrustedName of
                Just name ->
                    userWithGroupOwnerAuthorization
                        sessionId
                        groupId
                        model
                        (\( userId, _, group ) ->
                            ( { model
                                | groups =
                                    Dict.insert groupId (Group.withName name group) model.groups
                              }
                            , sendToFrontends
                                (getClientIdsForUser userId model)
                                (ChangeGroupNameResponse groupId name)
                            )
                        )

                Nothing ->
                    logUntrusted

        GroupRequest groupId (GroupPage.ChangeGroupDescriptionRequest untrustedDescription) ->
            case Untrusted.description untrustedDescription of
                Just description ->
                    userWithGroupOwnerAuthorization
                        sessionId
                        groupId
                        model
                        (\( userId, _, group ) ->
                            ( { model
                                | groups =
                                    Dict.insert groupId (Group.withDescription description group) model.groups
                              }
                            , sendToFrontends
                                (getClientIdsForUser userId model)
                                (ChangeGroupDescriptionResponse groupId description)
                            )
                        )

                Nothing ->
                    logUntrusted

        GroupRequest groupId (GroupPage.CreateEventRequest eventName_ description_ eventType_ startTime eventDuration_ maxAttendees_) ->
            case
                T5
                    (Untrusted.eventName eventName_)
                    (Untrusted.description description_)
                    (Untrusted.eventType eventType_)
                    (Untrusted.eventDuration eventDuration_)
                    (Untrusted.maxAttendees maxAttendees_)
            of
                T5 (Just eventName) (Just description) (Just eventType) (Just eventDuration) (Just maxAttendees) ->
                    userWithGroupOwnerAuthorization
                        sessionId
                        groupId
                        model
                        (\( userId, _, group ) ->
                            if Group.totalEvents group > 1000 then
                                ( model
                                , Effect.Lamdera.sendToFrontend clientId (CreateEventResponse groupId (Err TooManyEvents))
                                )

                            else if Duration.from model.time startTime |> Quantity.lessThanZero then
                                ( model
                                , Effect.Lamdera.sendToFrontend
                                    clientId
                                    (CreateEventResponse groupId (Err EventStartsInThePast))
                                )

                            else
                                let
                                    newEvent : Event
                                    newEvent =
                                        Event.newEvent
                                            userId
                                            eventName
                                            description
                                            eventType
                                            startTime
                                            eventDuration
                                            model.time
                                            maxAttendees

                                    subscriptionEmails : List (Command BackendOnly toFrontend BackendMsg)
                                    subscriptionEmails =
                                        List.filterMap
                                            (\subscriberId ->
                                                case getUser subscriberId model of
                                                    Just subscriber ->
                                                        sendNewEventNotificationEmail
                                                            (SentNewEventNotificationEmail subscriberId groupId)
                                                            groupId
                                                            (Group.name group)
                                                            newEvent
                                                            model.time
                                                            subscriber.timezone
                                                            subscriber.emailAddress
                                                            |> Just

                                                    Nothing ->
                                                        Nothing
                                            )
                                            (getGroupSubscribers groupId model)
                                in
                                case Group.addEvent newEvent group of
                                    Ok newGroup ->
                                        ( { model | groups = Dict.insert groupId newGroup model.groups }
                                        , sendToFrontends
                                            (getClientIdsForUser userId model)
                                            (CreateEventResponse groupId (Ok newEvent))
                                            :: subscriptionEmails
                                            |> Command.batch
                                        )

                                    Err overlappingEvents ->
                                        ( model
                                        , Effect.Lamdera.sendToFrontend
                                            clientId
                                            (CreateEventResponse groupId (Err (EventOverlapsOtherEvents overlappingEvents)))
                                        )
                        )

                _ ->
                    logUntrusted

        GroupRequest groupId (GroupPage.JoinEventRequest eventId) ->
            userAuthorization
                sessionId
                model
                (\( userId, _ ) -> joinEvent clientId userId ( groupId, eventId ) model)

        GroupRequest groupId (GroupPage.LeaveEventRequest eventId) ->
            userAuthorization
                sessionId
                model
                (\( userId, _ ) ->
                    case getGroup groupId model of
                        Just group ->
                            ( { model
                                | groups =
                                    Dict.insert groupId (Group.leaveEvent userId eventId group) model.groups
                              }
                            , sendToFrontends
                                (getClientIdsForUser userId model)
                                (LeaveEventResponse groupId eventId (Ok ()))
                            )

                        Nothing ->
                            ( model
                            , Effect.Lamdera.sendToFrontend
                                clientId
                                (LeaveEventResponse groupId eventId (Err ()))
                            )
                )

        GroupRequest groupId (GroupPage.EditEventRequest eventId eventName_ description_ eventType_ startTime eventDuration_ maxAttendees_) ->
            case
                T5
                    (Untrusted.eventName eventName_)
                    (Untrusted.description description_)
                    (Untrusted.eventType eventType_)
                    (Untrusted.eventDuration eventDuration_)
                    (Untrusted.maxAttendees maxAttendees_)
            of
                T5 (Just eventName) (Just description) (Just eventType) (Just eventDuration) (Just maxAttendees) ->
                    userWithGroupOwnerAuthorization
                        sessionId
                        groupId
                        model
                        (\( userId, _, group ) ->
                            case
                                Group.editEvent model.time
                                    eventId
                                    (Event.withName eventName
                                        >> Event.withDescription description
                                        >> Event.withEventType eventType
                                        >> Event.withDuration eventDuration
                                        >> Event.withStartTime startTime
                                        >> Event.withMaxAttendees maxAttendees
                                    )
                                    group
                            of
                                Ok ( newEvent, newGroup ) ->
                                    ( { model | groups = Dict.insert groupId newGroup model.groups }
                                    , sendToFrontends
                                        (getClientIdsForUser userId model)
                                        (EditEventResponse groupId eventId (Ok newEvent) model.time)
                                    )

                                Err error ->
                                    ( model
                                    , Effect.Lamdera.sendToFrontend
                                        clientId
                                        (EditEventResponse groupId eventId (Err error) model.time)
                                    )
                        )

                _ ->
                    logUntrusted

        GroupRequest groupId (GroupPage.ChangeEventCancellationStatusRequest eventId cancellationStatus) ->
            userWithGroupOwnerAuthorization
                sessionId
                groupId
                model
                (\( userId, _, group ) ->
                    case Group.editCancellationStatus model.time eventId cancellationStatus group of
                        Ok newGroup ->
                            ( { model | groups = Dict.insert groupId newGroup model.groups }
                            , sendToFrontends
                                (getClientIdsForUser userId model)
                                (ChangeEventCancellationStatusResponse
                                    groupId
                                    eventId
                                    (Ok cancellationStatus)
                                    model.time
                                )
                            )

                        Err error ->
                            ( model
                            , Effect.Lamdera.sendToFrontend
                                clientId
                                (ChangeEventCancellationStatusResponse groupId eventId (Err error) model.time)
                            )
                )

        GroupRequest groupId (GroupPage.ChangeGroupVisibilityRequest groupVisibility) ->
            userWithGroupOwnerAuthorization
                sessionId
                groupId
                model
                (\( userId, _, group ) ->
                    ( { model | groups = Dict.insert groupId (Group.withVisibility groupVisibility group) model.groups }
                    , sendToFrontends
                        (getClientIdsForUser userId model)
                        (ChangeGroupVisibilityResponse groupId groupVisibility)
                    )
                )

        GroupRequest groupId GroupPage.DeleteGroupAdminRequest ->
            adminAuthorization
                sessionId
                model
                (\( userId, _ ) ->
                    case Dict.get groupId model.groups of
                        Just group ->
                            ( { model
                                | groups = Dict.remove groupId model.groups
                                , deletedGroups = Dict.insert groupId group model.deletedGroups
                              }
                            , sendToFrontends
                                (getClientIdsForUser userId model)
                                (DeleteGroupAdminResponse groupId)
                            )

                        Nothing ->
                            ( model, Command.none )
                )

        GroupRequest groupId GroupPage.SubscribeRequest ->
            userAuthorization
                sessionId
                model
                (\( userId, user ) ->
                    case getGroup groupId model of
                        Just group ->
                            if Group.ownerId group == userId then
                                ( model, Command.none )

                            else
                                ( { model
                                    | users =
                                        Dict.insert
                                            userId
                                            { user | subscribedGroups = Set.insert groupId user.subscribedGroups }
                                            model.users
                                  }
                                , sendToFrontends
                                    (getClientIdsForUser userId model)
                                    (SubscribeResponse groupId)
                                )

                        Nothing ->
                            ( model, Command.none )
                )

        GroupRequest groupId GroupPage.UnsubscribeRequest ->
            userAuthorization
                sessionId
                model
                (\( userId, user ) ->
                    ( { model
                        | users =
                            Dict.insert
                                userId
                                { user | subscribedGroups = Set.remove groupId user.subscribedGroups }
                                model.users
                      }
                    , sendToFrontends (getClientIdsForUser userId model) (UnsubscribeResponse groupId)
                    )
                )

        GroupRequest groupId GroupPage.DeleteGroupUserRequest ->
            userAuthorization
                sessionId
                model
                (\( userId, _ ) ->
                    case Dict.get groupId model.groups of
                        Just group ->
                            if Group.ownerId group == userId then
                                ( deleteGroup groupId group model
                                , sendToFrontends
                                    (getClientIdsForUser userId model)
                                    (DeleteGroupUserResponse groupId)
                                )

                            else
                                ( model, Command.none )

                        Nothing ->
                            ( model, Command.none )
                )


deleteGroup : Id GroupId -> Group -> BackendModel -> BackendModel
deleteGroup groupId group model =
    { model
        | groups = Dict.remove groupId model.groups
        , deletedGroups = Dict.insert groupId group model.deletedGroups
    }


getGroupSubscribers : Id GroupId -> BackendModel -> List (Id UserId)
getGroupSubscribers groupId model =
    Dict.toList model.users
        |> List.filterMap
            (\( userId, user ) ->
                if Set.member groupId user.subscribedGroups then
                    Just userId

                else
                    Nothing
            )


loginIsRateLimited : SessionId -> EmailAddress -> BackendModel -> Bool
loginIsRateLimited sessionId emailAddress model =
    if
        Dict.get sessionId model.loginAttempts
            |> Maybe.map List.Nonempty.toList
            |> Maybe.withDefault []
            |> List.filter (\time -> Duration.from time model.time |> Quantity.lessThan (Duration.seconds 10))
            |> List.length
            |> (\a -> a > 0)
    then
        True

    else
        case Dict.values model.pendingLoginTokens |> List.find (.emailAddress >> (==) emailAddress) of
            Just { creationTime } ->
                if Duration.from creationTime model.time |> Quantity.lessThan Duration.minute then
                    True

                else
                    False

            Nothing ->
                False


handleDeleteUserRequest :
    ClientId
    -> Maybe DeleteUserTokenData
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
handleDeleteUserRequest clientId maybeDeleteUserTokenData model =
    case maybeDeleteUserTokenData of
        Just { creationTime, userId } ->
            if Duration.from creationTime model.time |> Quantity.lessThan Duration.hour then
                ( deleteUser userId model
                , sendToFrontends (getClientIdsForUser userId model) (DeleteUserResponse (Ok ()))
                )

            else
                ( model, Effect.Lamdera.sendToFrontend clientId (DeleteUserResponse (Err ())) )

        Nothing ->
            ( model, Effect.Lamdera.sendToFrontend clientId (DeleteUserResponse (Err ())) )


deleteUser : Id UserId -> BackendModel -> BackendModel
deleteUser userId model =
    { model
        | users = Dict.remove userId model.users
        , groups = Dict.filter (\_ group -> Group.ownerId group /= userId) model.groups
        , sessions = BiDict.filter (\_ userId_ -> userId_ /= userId) model.sessions
    }


getClientIdsForUser : Id UserId -> BackendModel -> List ClientId
getClientIdsForUser userId model =
    BiDict.getReverse userId model.sessions
        |> Set.toList
        |> List.concatMap
            (\sessionId_ ->
                case Dict.get sessionId_ model.connections of
                    Just nonempty ->
                        List.Nonempty.toList nonempty

                    Nothing ->
                        []
            )


loginWithToken :
    SessionId
    -> ClientId
    -> Maybe ( Id GroupId, EventId )
    -> Maybe LoginTokenData
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
loginWithToken sessionId clientId maybeJoinEvent maybeLoginTokenData model =
    let
        loginResponse : ( Id UserId, BackendUser ) -> Command BackendOnly ToFrontend BackendMsg
        loginResponse ( userId, userEntry ) =
            case Dict.get sessionId model.connections of
                Just clientIds ->
                    { userId = userId, user = userEntry, isAdmin = isAdmin userEntry }
                        |> Ok
                        |> LoginWithTokenResponse
                        |> sendToFrontends (List.Nonempty.toList clientIds)

                Nothing ->
                    Command.none

        addSession : Id UserId -> BackendModel -> BackendModel
        addSession userId model_ =
            { model_ | sessions = BiDict.insert sessionId userId model_.sessions }

        joinEventHelper : Id UserId -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
        joinEventHelper userId model_ =
            case maybeJoinEvent of
                Just joinEvent_ ->
                    joinEvent clientId userId joinEvent_ model_

                Nothing ->
                    ( model_, Command.none )
    in
    case maybeLoginTokenData of
        Just { creationTime, emailAddress } ->
            if Duration.from creationTime model.time |> Quantity.lessThan Duration.hour then
                case Dict.toList model.users |> List.find (Tuple.second >> .emailAddress >> (==) emailAddress) of
                    Just ( userId, user ) ->
                        let
                            ( model2, effects ) =
                                joinEventHelper userId model
                        in
                        ( addSession userId model2
                        , Command.batch [ loginResponse ( userId, user ), effects ]
                        )

                    Nothing ->
                        let
                            ( model2, userId ) =
                                Id.getUniqueShortId (\id_ model_ -> Dict.member id_ model_.users |> not) model

                            newUser : BackendUser
                            newUser =
                                { name = Name.anonymous
                                , description = Description.empty
                                , emailAddress = emailAddress
                                , profileImage = ProfileImage.defaultImage
                                , timezone = Time.utc
                                , allowEventReminders = True
                                , subscribedGroups = Set.empty
                                }

                            ( model3, effects ) =
                                { model2 | users = Dict.insert userId newUser model2.users }
                                    |> addSession userId
                                    |> joinEventHelper userId
                        in
                        ( model3
                        , Command.batch [ loginResponse ( userId, newUser ), effects ]
                        )

            else
                ( model, Err () |> LoginWithTokenResponse |> Effect.Lamdera.sendToFrontend clientId )

        Nothing ->
            ( model, Err () |> LoginWithTokenResponse |> Effect.Lamdera.sendToFrontend clientId )


joinEvent :
    ClientId
    -> Id UserId
    -> ( Id GroupId, EventId )
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
joinEvent clientId userId ( groupId, eventId ) model =
    case getGroup groupId model of
        Just group ->
            case Group.joinEvent userId eventId group of
                Ok newGroup ->
                    ( { model | groups = Dict.insert groupId newGroup model.groups }
                    , sendToFrontends
                        (getClientIdsForUser userId model)
                        (JoinEventResponse groupId eventId (Ok ()))
                    )

                Err error ->
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId (JoinEventResponse groupId eventId (Err error))
                    )

        Nothing ->
            ( model, Command.none )


getAndRemoveLoginToken :
    (Maybe LoginTokenData -> BackendModel -> ( BackendModel, cmds ))
    -> Id LoginToken
    -> BackendModel
    -> ( BackendModel, cmds )
getAndRemoveLoginToken updateFunc loginToken model =
    updateFunc
        (Dict.get loginToken model.pendingLoginTokens)
        { model | pendingLoginTokens = Dict.remove loginToken model.pendingLoginTokens }


getAndRemoveDeleteUserToken :
    (Maybe DeleteUserTokenData -> BackendModel -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg ))
    -> Id DeleteUserToken
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
getAndRemoveDeleteUserToken updateFunc deleteUserToken model =
    updateFunc
        (Dict.get deleteUserToken model.pendingDeleteUserTokens)
        { model | pendingDeleteUserTokens = Dict.remove deleteUserToken model.pendingDeleteUserTokens }


addGroup :
    ClientId
    -> Id UserId
    -> GroupName
    -> Description
    -> GroupVisibility
    -> BackendModel
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
addGroup clientId userId name description visibility model =
    if Dict.values model.groups |> List.any (Group.name >> GroupName.namesMatch name) then
        ( model, Err GroupNameAlreadyInUse |> CreateGroupResponse |> Effect.Lamdera.sendToFrontend clientId )

    else
        let
            ( model2, groupId ) =
                Id.getUniqueShortId (\id_ model_ -> Dict.member id_ model_.groups |> not) model

            newGroup =
                Group.init userId name description visibility model2.time
        in
        ( { model2 | groups = Dict.insert groupId newGroup model2.groups }
        , Ok ( groupId, newGroup ) |> CreateGroupResponse |> Effect.Lamdera.sendToFrontend clientId
        )


userAuthorization :
    SessionId
    -> BackendModel
    -> (( Id UserId, BackendUser ) -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg ))
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
userAuthorization sessionId model updateFunc =
    case checkLogin sessionId model of
        Just { userId, user } ->
            updateFunc ( userId, user )

        Nothing ->
            ( model, Command.none )


userWithGroupOwnerAuthorization :
    SessionId
    -> Id GroupId
    -> BackendModel
    -> (( Id UserId, BackendUser, Group ) -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg ))
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
userWithGroupOwnerAuthorization sessionId groupId model updateFunc =
    case checkLogin sessionId model of
        Just { userId, user } ->
            case getGroup groupId model of
                Just group ->
                    if Group.ownerId group == userId || isAdmin user then
                        updateFunc ( userId, user, group )

                    else
                        ( model, Command.none )

                Nothing ->
                    ( model, Command.none )

        Nothing ->
            ( model, Command.none )


adminAuthorization :
    SessionId
    -> BackendModel
    -> (( Id UserId, BackendUser ) -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg ))
    -> ( BackendModel, Command BackendOnly ToFrontend BackendMsg )
adminAuthorization sessionId model updateFunc =
    case checkLogin sessionId model of
        Just checkLogin_ ->
            if checkLogin_.isAdmin then
                updateFunc ( checkLogin_.userId, checkLogin_.user )

            else
                ( model, Command.none )

        Nothing ->
            ( model, Command.none )


isAdmin : BackendUser -> Bool
isAdmin user =
    EmailAddress.toString user.emailAddress == Env.adminEmailAddress


checkLogin : SessionId -> BackendModel -> Maybe { userId : Id UserId, user : BackendUser, isAdmin : Bool }
checkLogin sessionId model =
    getUserFromSessionId sessionId model
        |> Maybe.map (\( userId, user ) -> { userId = userId, user = user, isAdmin = isAdmin user })


getGroup : Id GroupId -> BackendModel -> Maybe Group
getGroup groupId model =
    Dict.get groupId model.groups


getUser : Id UserId -> BackendModel -> Maybe BackendUser
getUser userId model =
    Dict.get userId model.users


getUserFromSessionId : SessionId -> BackendModel -> Maybe ( Id UserId, BackendUser )
getUserFromSessionId sessionId model =
    BiDict.get sessionId model.sessions
        |> Maybe.andThen (\userId -> getUser userId model |> Maybe.map (Tuple.pair userId))


loginEmailSubject : NonemptyString
loginEmailSubject =
    NonemptyString 'M' "eetdown login link"


loginEmailContent : Route -> Id LoginToken -> Maybe ( Id GroupId, EventId ) -> Email.Html.Html
loginEmailContent route loginToken maybeJoinEvent =
    let
        loginLink : String
        loginLink =
            loginEmailLink route loginToken maybeJoinEvent

        _ =
            Debug.log "login" loginLink
    in
    Email.Html.div
        [ Email.Html.Attributes.padding "8px" ]
        [ Email.Html.a
            [ Email.Html.Attributes.href loginLink ]
            [ Email.Html.text "Click here to log in." ]
        , Email.Html.text " If you didn't request this email then it's safe to ignore it."
        ]


deleteAccountEmailSubject : NonemptyString
deleteAccountEmailSubject =
    NonemptyString 'C' "onfirm account deletion"


deleteAccountEmailContent : Id DeleteUserToken -> Email.Html.Html
deleteAccountEmailContent deleteUserToken =
    let
        deleteUserLink : String
        deleteUserLink =
            Env.domain ++ Route.encodeWithToken HomepageRoute (Route.DeleteUserToken deleteUserToken)

        _ =
            Debug.log "delete user" deleteUserLink
    in
    Email.Html.div
        [ Email.Html.Attributes.padding "8px" ]
        [ Email.Html.a
            [ Email.Html.Attributes.href deleteUserLink ]
            [ Email.Html.text "Click here confirm you want to delete your account." ]
        , Email.Html.text " Remember, this action can not be reversed! If you didn't request this email then it's safe to ignore it."
        ]


eventReminderEmailSubject : GroupName -> Event -> Time.Zone -> NonemptyString
eventReminderEmailSubject groupName event timezone =
    let
        startTime =
            Event.startTime event

        hour =
            String.fromInt (Time.toHour timezone startTime)

        minute =
            Time.toMinute timezone startTime |> String.fromInt |> String.padLeft 2 '0'

        startText =
            hour
                ++ ":"
                ++ minute
                ++ (if timezone == Time.utc then
                        " (UTC)"

                    else
                        ""
                   )
    in
    String.Nonempty.append_
        (GroupName.toNonemptyString groupName)
        ("'s next event starts tomorrow, " ++ startText)


eventReminderEmailContent : Id GroupId -> GroupName -> Event -> Email.Html.Html
eventReminderEmailContent groupId groupName event =
    let
        groupRoute =
            Env.domain ++ Route.encode (Route.GroupRoute groupId groupName)
    in
    Email.Html.div
        [ Email.Html.Attributes.padding "8px" ]
        (Email.Html.b [] [ Event.name event |> EventName.toString |> Email.Html.text ]
            :: Email.Html.text " will be taking place "
            :: (case Event.eventType event of
                    Event.MeetOnline (Just meetingLink) ->
                        [ Email.Html.text "online tomorrow. The event will be accessible with this link "
                        , Email.Html.a
                            [ Email.Html.Attributes.href (Link.toString meetingLink) ]
                            [ Email.Html.text (Link.toString meetingLink) ]
                        , Email.Html.text ". "
                        ]

                    Event.MeetOnline Nothing ->
                        [ Email.Html.text "online tomorrow." ]

                    Event.MeetInPerson (Just address) ->
                        [ Email.Html.text (" in person tomorrow at " ++ Address.toString address ++ ".") ]

                    Event.MeetInPerson Nothing ->
                        [ Email.Html.text " in person tomorrow." ]

                    Event.MeetOnlineAndInPerson (Just meetingLink) (Just address) ->
                        [ Email.Html.text " online and in person tomorrow. The event will be accessible with this link "
                        , Email.Html.a
                            [ Email.Html.Attributes.href (Link.toString meetingLink) ]
                            [ Email.Html.text (Link.toString meetingLink) ]
                        , Email.Html.text " and will be taking place at "
                        , Email.Html.text (Address.toString address)
                        , Email.Html.text ". "
                        ]

                    Event.MeetOnlineAndInPerson (Just meetingLink) Nothing ->
                        [ Email.Html.text " online and in person tomorrow. The event will be accessible with this link "
                        , Email.Html.a
                            [ Email.Html.Attributes.href (Link.toString meetingLink) ]
                            [ Email.Html.text (Link.toString meetingLink) ]
                        , Email.Html.text ". "
                        ]

                    Event.MeetOnlineAndInPerson Nothing (Just address) ->
                        [ Email.Html.text " online and in person tomorrow. The event will be taking place at "
                        , Email.Html.text (Address.toString address)
                        , Email.Html.text ". "
                        ]

                    Event.MeetOnlineAndInPerson Nothing Nothing ->
                        [ Email.Html.text " online and in person tomorrow." ]
               )
            ++ [ Email.Html.br [] []
               , Email.Html.br [] []
               , Email.Html.a
                    [ Email.Html.Attributes.href groupRoute ]
                    [ Email.Html.text "Click here to go to their group page" ]
               ]
        )


newEventNotificationEmailSubject : GroupName -> Event -> Time.Posix -> Time.Zone -> NonemptyString
newEventNotificationEmailSubject groupName event currentTime timezone =
    let
        startDateOrTime_ =
            startDateOrTime (Event.startTime event) currentTime timezone
    in
    String.Nonempty.append_
        (GroupName.toNonemptyString groupName)
        ("'s has planned a new event " ++ startDateOrTime_)


startDateOrTime : Time.Posix -> Time.Posix -> Time.Zone -> String
startDateOrTime startTime currentTime timezone =
    let
        startDate =
            Date.fromPosix timezone startTime

        hour =
            String.fromInt (Time.toHour timezone startTime)

        minute =
            Time.toMinute timezone startTime |> String.fromInt |> String.padLeft 2 '0'

        startText =
            hour
                ++ ":"
                ++ minute
                ++ (if timezone == Time.utc then
                        " (UTC)"

                    else
                        ""
                   )

        today : Date.Date
        today =
            Date.fromPosix timezone currentTime
    in
    if startDate == today then
        "today at " ++ startText

    else if startDate == Date.add Date.Days 1 today then
        "tomrrow at " ++ startText

    else
        "on " ++ Date.toIsoString startDate


newEventNotificationEmailContent : Id GroupId -> GroupName -> Event -> Time.Posix -> Time.Zone -> Email.Html.Html
newEventNotificationEmailContent groupId groupName event currentTime timezone =
    let
        groupRoute =
            Env.domain ++ Route.encode (Route.GroupRoute groupId groupName)

        startDateOrTime_ =
            startDateOrTime (Event.startTime event) currentTime timezone
    in
    Email.Html.div
        [ Email.Html.Attributes.padding "8px" ]
        (Email.Html.b [] [ Event.name event |> EventName.toString |> Email.Html.text ]
            :: Email.Html.text " will be taking place "
            :: (case Event.eventType event of
                    Event.MeetOnline (Just meetingLink) ->
                        [ "online "
                            ++ startDateOrTime_
                            ++ ". The event will be accessible with this link "
                            |> Email.Html.text
                        , Email.Html.a
                            [ Email.Html.Attributes.href (Link.toString meetingLink) ]
                            [ Email.Html.text (Link.toString meetingLink) ]
                        , Email.Html.text ". "
                        ]

                    Event.MeetOnline Nothing ->
                        [ Email.Html.text ("online " ++ startDateOrTime_ ++ ".") ]

                    Event.MeetInPerson (Just address) ->
                        [ Email.Html.text
                            (" in person at " ++ Address.toString address ++ " " ++ startDateOrTime_ ++ ".")
                        ]

                    Event.MeetInPerson Nothing ->
                        [ Email.Html.text (" in person " ++ startDateOrTime_ ++ ".") ]

                    Event.MeetOnlineAndInPerson (Just meetingLink) (Just address) ->
                        [ " online and in person at "
                            ++ Address.toString address
                            ++ " "
                            ++ startDateOrTime_
                            ++ ". The event will be accessible with this link "
                            |> Email.Html.text
                        , Email.Html.a
                            [ Email.Html.Attributes.href (Link.toString meetingLink) ]
                            [ Email.Html.text (Link.toString meetingLink) ]
                        , Email.Html.text ". "
                        ]

                    Event.MeetOnlineAndInPerson (Just meetingLink) Nothing ->
                        [ " online and in person "
                            ++ startDateOrTime_
                            ++ ". The event will be accessible with this link "
                            |> Email.Html.text
                        , Email.Html.a
                            [ Email.Html.Attributes.href (Link.toString meetingLink) ]
                            [ Email.Html.text (Link.toString meetingLink) ]
                        , Email.Html.text ". "
                        ]

                    Event.MeetOnlineAndInPerson Nothing (Just address) ->
                        [ Email.Html.text
                            (" online and in person at " ++ Address.toString address ++ " " ++ startDateOrTime_ ++ ".")
                        ]

                    Event.MeetOnlineAndInPerson Nothing Nothing ->
                        [ Email.Html.text (" online and in person " ++ startDateOrTime_ ++ ".") ]
               )
            ++ [ Email.Html.br [] []
               , Email.Html.br [] []
               , Email.Html.a
                    [ Email.Html.Attributes.href groupRoute ]
                    [ Email.Html.text "Click here to go to their group page" ]
               ]
        )



-- Helper to generate ICS attachment for an event


icsAttachmentForEvent : GroupName -> Event -> Time.Posix -> Time.Zone -> ( String, { content : Bytes.Bytes, mimeType : String } )
icsAttachmentForEvent groupName event currentTime timezone =
    let
        summary =
            EventName.toString (Event.name event)

        description =
            Description.toString (Event.description event)

        location =
            case Event.eventType event of
                Event.MeetOnline (Just link) ->
                    Link.toString link

                Event.MeetInPerson (Just address) ->
                    Address.toString address

                Event.MeetOnlineAndInPerson _ (Just address) ->
                    Address.toString address

                _ ->
                    ""

        startUtc =
            Time.posixToMillis (Event.startTime event)
                |> TimeExtra.toUtcIcsString timezone

        endUtc =
            Event.endTime event
                |> Time.posixToMillis
                |> TimeExtra.toUtcIcsString timezone

        icsString =
            Ics.generateEventIcs { summary = summary, description = description, location = location, startUtc = startUtc, endUtc = endUtc }

        bytes =
            Encode.string icsString |> Encode.encode
    in
    ( "event.ics", { content = bytes, mimeType = "text/calendar" } )
