module BackendLogic exposing
    ( init
    , loginEmailLink
    , subscriptions
    , update
    , updateFromFrontend
    )

import Address
import Array
import AssocList as Dict exposing (Dict)
import AssocSet as Set
import BackendEffect exposing (BackendEffect)
import BackendSub exposing (BackendSub)
import BiDict.Assoc as BiDict
import CreateGroupPage exposing (CreateGroupError(..))
import Description exposing (Description)
import Duration exposing (Duration)
import Email.Html
import Email.Html.Attributes
import EmailAddress exposing (EmailAddress)
import Env
import Event exposing (Event)
import EventName
import Group exposing (EventId, Group, GroupVisibility)
import GroupName exposing (GroupName)
import GroupPage exposing (CreateEventError(..))
import Http
import Id exposing (ClientId, DeleteUserToken, GroupId, Id, LoginToken, SessionId, UserId)
import Link
import List.Extra as List
import List.Nonempty
import Name
import Postmark
import ProfileImage
import Quantity
import Route exposing (Route(..))
import String.Nonempty exposing (NonemptyString(..))
import Time
import Toop exposing (T3(..), T4(..), T5(..))
import Types exposing (..)
import Untrusted


loginEmailLink : Route -> Id LoginToken -> Maybe ( Id GroupId, EventId ) -> String
loginEmailLink route loginToken maybeJoinEvent =
    Env.domain ++ Route.encodeWithToken route (Route.LoginToken loginToken maybeJoinEvent)


init : ( BackendModel, BackendEffect ToFrontend BackendMsg )
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
    , BackendEffect.getTime |> BackendEffect.taskPerform BackendGotTime
    )


subscriptions : BackendModel -> BackendSub BackendMsg
subscriptions _ =
    BackendSub.Batch
        [ BackendSub.TimeEvery (Duration.seconds 15) BackendGotTime
        , BackendSub.OnConnect Connected
        , BackendSub.OnDisconnect Disconnected
        ]


handleNotifications : Time.Posix -> Time.Posix -> BackendModel -> BackendEffect ToFrontend BackendMsg
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
        |> BackendEffect.Batch


update : BackendMsg -> BackendModel -> ( BackendModel, BackendEffect ToFrontend BackendMsg )
update msg model =
    case msg of
        SentLoginEmail userId result ->
            ( addLog (LogLoginEmail model.time result userId) model, BackendEffect.None )

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
            , BackendEffect.None
            )

        Disconnected sessionId clientId ->
            ( { model
                | connections =
                    Dict.update sessionId
                        (Maybe.andThen (List.Nonempty.toList >> List.remove clientId >> List.Nonempty.fromList))
                        model.connections
              }
            , BackendEffect.None
            )

        SentDeleteUserEmail userId result ->
            ( addLog (LogDeleteAccountEmail model.time result userId) model, BackendEffect.None )

        SentEventReminderEmail userId groupId eventId result ->
            ( addLog (LogEventReminderEmail model.time result userId groupId eventId) model, BackendEffect.None )


addLog : Log -> BackendModel -> BackendModel
addLog log model =
    { model | logs = Array.push log model.logs }


sendToFrontends : List ClientId -> ToFrontend -> BackendEffect ToFrontend backendMsg
sendToFrontends clientIds toFrontend =
    List.map (\clientId -> BackendEffect.SendToFrontend clientId toFrontend) clientIds |> BackendEffect.Batch


noReplyEmailAddress : Maybe EmailAddress
noReplyEmailAddress =
    EmailAddress.fromString "no-reply@meetdown.app"


sendLoginEmail : (Result Http.Error Postmark.PostmarkSendResponse -> backendMsg) -> EmailAddress -> Route -> Id LoginToken -> Maybe ( Id GroupId, EventId ) -> BackendEffect toFrontend backendMsg
sendLoginEmail msg emailAddress route loginToken maybeJoinEvent =
    case noReplyEmailAddress of
        Just sender ->
            { from = { name = "Meetdown", email = sender }
            , to = List.Nonempty.fromElement { name = "", email = emailAddress }
            , subject = loginEmailSubject
            , body = Postmark.BodyHtml <| loginEmailContent route loginToken maybeJoinEvent
            , messageStream = "outbound"
            }
                |> Postmark.sendEmail msg Env.postmarkServerToken

        Nothing ->
            BackendEffect.None


sendDeleteUserEmail : (Result Http.Error Postmark.PostmarkSendResponse -> backendMsg) -> EmailAddress -> Id DeleteUserToken -> BackendEffect toFrontend backendMsg
sendDeleteUserEmail msg emailAddress deleteUserToken =
    case noReplyEmailAddress of
        Just sender ->
            { from = { name = "Meetdown", email = sender }
            , to = List.Nonempty.fromElement { name = "", email = emailAddress }
            , subject = deleteAccountEmailSubject
            , body = Postmark.BodyHtml <| deleteAccountEmailContent deleteUserToken
            , messageStream = "outbound"
            }
                |> Postmark.sendEmail msg Env.postmarkServerToken

        Nothing ->
            BackendEffect.None


sendEventReminderEmail : (Result Http.Error Postmark.PostmarkSendResponse -> backendMsg) -> Id GroupId -> GroupName -> Event -> Time.Zone -> EmailAddress -> BackendEffect toFrontend backendMsg
sendEventReminderEmail msg groupId groupName event timezone emailAddress =
    case noReplyEmailAddress of
        Just sender ->
            { from = { name = "Meetdown", email = sender }
            , to = List.Nonempty.fromElement { name = "", email = emailAddress }
            , subject = eventReminderEmailSubject groupName event timezone
            , body = Postmark.BodyHtml <| eventReminderEmailContent groupId groupName event
            , messageStream = "broadcast"
            }
                |> Postmark.sendEmail msg Env.postmarkServerToken

        Nothing ->
            BackendEffect.None


updateFromFrontend : SessionId -> ClientId -> ToBackend -> BackendModel -> ( BackendModel, BackendEffect ToFrontend BackendMsg )
updateFromFrontend sessionId clientId msg model =
    let
        logUntrusted =
            ( addLog (LogUntrustedCheckFailed model.time msg (Id.anonymizeSessionId sessionId)) model
            , BackendEffect.None
            )
    in
    case msg of
        GetGroupRequest groupId ->
            ( model
            , (case getGroup groupId model of
                Just group ->
                    case getUserFromSessionId sessionId model of
                        Just ( userId, user ) ->
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
                |> BackendEffect.SendToFrontend clientId
            )

        GetUserRequest userId ->
            case getUser userId model of
                Just user ->
                    ( model
                    , Ok (Types.userToFrontend user) |> GetUserResponse userId |> BackendEffect.SendToFrontend clientId
                    )

                Nothing ->
                    ( model, Err () |> GetUserResponse userId |> BackendEffect.SendToFrontend clientId )

        CheckLoginRequest ->
            ( model, checkLogin sessionId model |> CheckLoginResponse |> BackendEffect.SendToFrontend clientId )

        GetLoginTokenRequest route untrustedEmail maybeJoinEvent ->
            case Untrusted.validateEmailAddress untrustedEmail of
                Just email ->
                    let
                        ( model2, loginToken ) =
                            Id.getUniqueId model
                    in
                    if loginIsRateLimited sessionId email model then
                        ( addLog
                            (LogLoginTokenEmailRequestRateLimited model.time email (Id.anonymizeSessionId sessionId))
                            model
                        , BackendEffect.None
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
                    , BackendEffect.SendToFrontend
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
                    BackendEffect.None
            )

        CreateGroupRequest untrustedName untrustedDescription visibility ->
            userAuthorization
                sessionId
                model
                (\( userId, _ ) ->
                    case
                        ( Untrusted.validateGroupName untrustedName
                        , Untrusted.description untrustedDescription
                        )
                    of
                        ( Just groupName, Just description ) ->
                            addGroup clientId userId groupName description visibility model

                        _ ->
                            logUntrusted
                )

        ChangeNameRequest untrustedName ->
            case Untrusted.validateName untrustedName of
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

        ChangeDescriptionRequest untrustedDescription ->
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

        ChangeEmailAddressRequest untrustedEmailAddress ->
            case Untrusted.validateEmailAddress untrustedEmailAddress of
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

        SendDeleteUserEmailRequest ->
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
                        , BackendEffect.None
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

        ChangeProfileImageRequest untrustedProfileImage ->
            userAuthorization
                sessionId
                model
                (\( userId, user ) ->
                    case Untrusted.validateProfileImage untrustedProfileImage of
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
                (\( userId, _ ) ->
                    ( model
                    , Dict.toList model.groups
                        |> List.filter
                            (\( _, group ) -> Group.ownerId group == userId)
                        |> GetMyGroupsResponse
                        |> BackendEffect.SendToFrontend clientId
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
                    |> BackendEffect.SendToFrontend clientId
                )

            else
                ( model, BackendEffect.None )

        GroupRequest groupId (GroupPage.ChangeGroupNameRequest untrustedName) ->
            case Untrusted.validateGroupName untrustedName of
                Just name ->
                    userWithGroupAuthorization
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
                    userWithGroupAuthorization
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
                    userWithGroupAuthorization
                        sessionId
                        groupId
                        model
                        (\( userId, _, group ) ->
                            if Group.totalEvents group > 1000 then
                                ( model
                                , BackendEffect.SendToFrontend clientId (CreateEventResponse groupId (Err TooManyEvents))
                                )

                            else if Duration.from model.time startTime |> Quantity.lessThanZero then
                                ( model
                                , BackendEffect.SendToFrontend
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
                                in
                                case Group.addEvent newEvent group of
                                    Ok newGroup ->
                                        ( { model | groups = Dict.insert groupId newGroup model.groups }
                                        , sendToFrontends
                                            (getClientIdsForUser userId model)
                                            (CreateEventResponse groupId (Ok newEvent))
                                        )

                                    Err overlappingEvents ->
                                        ( model
                                        , BackendEffect.SendToFrontend
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
                            , BackendEffect.SendToFrontend
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
                    userWithGroupAuthorization
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
                                    , BackendEffect.SendToFrontend
                                        clientId
                                        (EditEventResponse groupId eventId (Err error) model.time)
                                    )
                        )

                _ ->
                    logUntrusted

        GroupRequest groupId (GroupPage.ChangeEventCancellationStatusRequest eventId cancellationStatus) ->
            userWithGroupAuthorization
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
                            , BackendEffect.SendToFrontend
                                clientId
                                (ChangeEventCancellationStatusResponse groupId eventId (Err error) model.time)
                            )
                )

        GroupRequest groupId (GroupPage.ChangeGroupVisibilityRequest groupVisibility) ->
            userWithGroupAuthorization
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
                            ( model, BackendEffect.None )
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
    -> ( BackendModel, BackendEffect ToFrontend BackendMsg )
handleDeleteUserRequest clientId maybeDeleteUserTokenData model =
    case maybeDeleteUserTokenData of
        Just { creationTime, userId } ->
            if Duration.from creationTime model.time |> Quantity.lessThan Duration.hour then
                ( deleteUser userId model
                , sendToFrontends (getClientIdsForUser userId model) (DeleteUserResponse (Ok ()))
                )

            else
                ( model, BackendEffect.SendToFrontend clientId (DeleteUserResponse (Err ())) )

        Nothing ->
            ( model, BackendEffect.SendToFrontend clientId (DeleteUserResponse (Err ())) )


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
    -> ( BackendModel, BackendEffect ToFrontend BackendMsg )
loginWithToken sessionId clientId maybeJoinEvent maybeLoginTokenData model =
    let
        loginResponse : ( Id UserId, BackendUser ) -> BackendEffect ToFrontend BackendMsg
        loginResponse ( userId, userEntry ) =
            case Dict.get sessionId model.connections of
                Just clientIds ->
                    { userId = userId, user = userEntry, isAdmin = isAdmin userEntry }
                        |> Ok
                        |> LoginWithTokenResponse
                        |> sendToFrontends (List.Nonempty.toList clientIds)

                Nothing ->
                    BackendEffect.None

        addSession : Id UserId -> BackendModel -> BackendModel
        addSession userId model_ =
            { model_ | sessions = BiDict.insert sessionId userId model_.sessions }

        joinEventHelper : Id UserId -> BackendModel -> ( BackendModel, BackendEffect ToFrontend BackendMsg )
        joinEventHelper userId model_ =
            case maybeJoinEvent of
                Just joinEvent_ ->
                    joinEvent clientId userId joinEvent_ model_

                Nothing ->
                    ( model_, BackendEffect.None )
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
                        , BackendEffect.Batch [ loginResponse ( userId, user ), effects ]
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
                                }

                            ( model3, effects ) =
                                { model2 | users = Dict.insert userId newUser model2.users }
                                    |> addSession userId
                                    |> joinEventHelper userId
                        in
                        ( model3
                        , BackendEffect.Batch [ loginResponse ( userId, newUser ), effects ]
                        )

            else
                ( model, Err () |> LoginWithTokenResponse |> BackendEffect.SendToFrontend clientId )

        Nothing ->
            ( model, Err () |> LoginWithTokenResponse |> BackendEffect.SendToFrontend clientId )


joinEvent : ClientId -> Id UserId -> ( Id GroupId, EventId ) -> BackendModel -> ( BackendModel, BackendEffect ToFrontend BackendMsg )
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
                    , BackendEffect.SendToFrontend clientId (JoinEventResponse groupId eventId (Err error))
                    )

        Nothing ->
            ( model, BackendEffect.None )


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
    (Maybe DeleteUserTokenData -> BackendModel -> ( BackendModel, BackendEffect ToFrontend BackendMsg ))
    -> Id DeleteUserToken
    -> BackendModel
    -> ( BackendModel, BackendEffect ToFrontend BackendMsg )
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
    -> ( BackendModel, BackendEffect ToFrontend BackendMsg )
addGroup clientId userId name description visibility model =
    if Dict.values model.groups |> List.any (Group.name >> GroupName.namesMatch name) then
        ( model, Err GroupNameAlreadyInUse |> CreateGroupResponse |> BackendEffect.SendToFrontend clientId )

    else
        let
            ( model2, groupId ) =
                Id.getUniqueShortId (\id_ model_ -> Dict.member id_ model_.groups |> not) model

            newGroup =
                Group.init userId name description visibility model2.time
        in
        ( { model2 | groups = Dict.insert groupId newGroup model2.groups }
        , Ok ( groupId, newGroup ) |> CreateGroupResponse |> BackendEffect.SendToFrontend clientId
        )


userAuthorization :
    SessionId
    -> BackendModel
    -> (( Id UserId, BackendUser ) -> ( BackendModel, BackendEffect ToFrontend BackendMsg ))
    -> ( BackendModel, BackendEffect ToFrontend BackendMsg )
userAuthorization sessionId model updateFunc =
    case checkLogin sessionId model of
        Just { userId, user } ->
            updateFunc ( userId, user )

        Nothing ->
            ( model, BackendEffect.None )


userWithGroupAuthorization :
    SessionId
    -> Id GroupId
    -> BackendModel
    -> (( Id UserId, BackendUser, Group ) -> ( BackendModel, BackendEffect ToFrontend BackendMsg ))
    -> ( BackendModel, BackendEffect ToFrontend BackendMsg )
userWithGroupAuthorization sessionId groupId model updateFunc =
    case checkLogin sessionId model of
        Just { userId, user } ->
            case getGroup groupId model of
                Just group ->
                    if Group.ownerId group == userId || isAdmin user then
                        updateFunc ( userId, user, group )

                    else
                        ( model, BackendEffect.None )

                Nothing ->
                    ( model, BackendEffect.None )

        Nothing ->
            ( model, BackendEffect.None )


adminAuthorization :
    SessionId
    -> BackendModel
    -> (( Id UserId, BackendUser ) -> ( BackendModel, BackendEffect ToFrontend BackendMsg ))
    -> ( BackendModel, BackendEffect ToFrontend BackendMsg )
adminAuthorization sessionId model updateFunc =
    case checkLogin sessionId model of
        Just checkLogin_ ->
            if checkLogin_.isAdmin then
                updateFunc ( checkLogin_.userId, checkLogin_.user )

            else
                ( model, BackendEffect.None )

        Nothing ->
            ( model, BackendEffect.None )


isAdmin : BackendUser -> Bool
isAdmin user =
    EmailAddress.toString user.emailAddress == Env.adminEmailAddress


checkLogin : SessionId -> BackendModel -> Maybe { userId : Id UserId, user : BackendUser, isAdmin : Bool }
checkLogin sessionId model =
    case BiDict.get sessionId model.sessions of
        Just userId ->
            case Dict.get userId model.users of
                Just user ->
                    Just { userId = userId, user = user, isAdmin = isAdmin user }

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


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

        --_ =
        --    Debug.log "login" loginLink
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

        --_ =
        --    Debug.log "delete user" deleteUserLink
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
               )
            ++ [ Email.Html.br [] []
               , Email.Html.br [] []
               , Email.Html.a
                    [ Email.Html.Attributes.href groupRoute ]
                    [ Email.Html.text "Click here to go to their group page" ]
               ]
        )
