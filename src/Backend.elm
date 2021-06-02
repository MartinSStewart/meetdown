module Backend exposing (app, init, update, updateFromFrontend)

import Array
import AssocList as Dict exposing (Dict)
import AssocSet as Set
import BackendEffect exposing (BackendEffect)
import BackendSub exposing (BackendSub)
import BiDict.Assoc as BiDict
import CreateGroupForm exposing (CreateGroupError(..))
import Description exposing (Description)
import Duration
import Event exposing (Event)
import Group exposing (Group, GroupVisibility)
import GroupName exposing (GroupName)
import GroupPage exposing (CreateEventError(..))
import Id exposing (ClientId, DeleteUserToken, GroupId, Id, LoginToken, SessionId, UserId)
import Lamdera
import List.Extra as List
import List.Nonempty
import Name
import ProfileImage
import Quantity
import Time
import Toop exposing (T3(..), T4(..), T5(..))
import Types exposing (..)
import Untrusted


app =
    Lamdera.backend
        { init = init |> Tuple.mapSecond BackendEffect.toCmd
        , update = \msg model -> update msg model |> Tuple.mapSecond BackendEffect.toCmd
        , updateFromFrontend =
            \sessionId clientId toBackend model ->
                updateFromFrontend
                    (Id.sessionIdFromString sessionId)
                    (Id.clientIdFromString clientId)
                    toBackend
                    model
                    |> Tuple.mapSecond BackendEffect.toCmd
        , subscriptions = subscriptions >> BackendSub.toSub
        }


init : ( BackendModel, BackendEffect )
init =
    ( { users = Dict.empty
      , groups = Dict.empty
      , groupIdCounter = 0
      , sessions = BiDict.empty
      , connections = Dict.empty
      , logs = Array.empty
      , time = Time.millisToPosix 0
      , secretCounter = 0
      , pendingLoginTokens = Dict.empty
      , pendingDeleteUserTokens = Dict.empty
      }
    , BackendEffect.getTime BackendGotTime
    )


subscriptions : BackendModel -> BackendSub
subscriptions _ =
    BackendSub.batch
        [ BackendSub.timeEvery (Duration.seconds 15) BackendGotTime
        , BackendSub.onConnect Connected
        , BackendSub.onDisconnect Disconnected
        ]


update : BackendMsg -> BackendModel -> ( BackendModel, BackendEffect )
update msg model =
    case msg of
        SentLoginEmail emailAddress result ->
            ( addLog (SendGridSendEmail model.time result emailAddress) model, BackendEffect.none )

        BackendGotTime time ->
            ( { model | time = time }, BackendEffect.none )

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
            , BackendEffect.none
            )

        Disconnected sessionId clientId ->
            ( { model
                | connections =
                    Dict.update sessionId
                        (Maybe.andThen (List.Nonempty.toList >> List.remove clientId >> List.Nonempty.fromList))
                        model.connections
              }
            , BackendEffect.none
            )

        SentDeleteUserEmail emailAddress result ->
            ( addLog (SendGridSendEmail model.time result emailAddress) model, BackendEffect.none )


addLog : Log -> BackendModel -> BackendModel
addLog log model =
    { model | logs = Array.push log model.logs }


updateFromFrontend : SessionId -> ClientId -> ToBackend -> BackendModel -> ( BackendModel, BackendEffect )
updateFromFrontend sessionId clientId (ToBackend msgs) model =
    List.Nonempty.foldl
        (\msg ( newModel, effects ) ->
            updateFromRequest sessionId clientId msg newModel
                |> Tuple.mapSecond (\a -> BackendEffect.batch [ a, effects ])
        )
        ( model, BackendEffect.none )
        msgs


updateFromRequest : SessionId -> ClientId -> ToBackendRequest -> BackendModel -> ( BackendModel, BackendEffect )
updateFromRequest sessionId clientId msg model =
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
                                    Dict.singleton (Group.ownerId group) (userToFrontend user)
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
                |> BackendEffect.sendToFrontend clientId
            )

        CheckLoginRequest ->
            ( model, checkLogin sessionId model |> CheckLoginResponse |> BackendEffect.sendToFrontend clientId )

        GetLoginTokenRequest route untrustedEmail ->
            case Untrusted.validateEmailAddress untrustedEmail of
                Just email ->
                    let
                        ( model2, loginToken ) =
                            Id.getUniqueId model
                    in
                    ( { model2
                        | pendingLoginTokens =
                            Dict.insert
                                loginToken
                                { creationTime = model2.time, emailAddress = email }
                                model2.pendingLoginTokens
                      }
                    , BackendEffect.sendLoginEmail (SentLoginEmail email) email route loginToken
                    )

                Nothing ->
                    ( addLog (UntrustedCheckFailed model.time msg) model
                    , BackendEffect.none
                    )

        GetAdminDataRequest ->
            adminAuthorization
                sessionId
                model
                (\_ ->
                    ( model, BackendEffect.sendToFrontend clientId (GetAdminDataResponse model.logs) )
                )

        LoginWithTokenRequest loginToken ->
            getAndRemoveLoginToken (loginWithToken sessionId clientId) loginToken model

        LogoutRequest ->
            ( { model | sessions = BiDict.remove sessionId model.sessions }
            , case Dict.get sessionId model.connections of
                Just clientIds ->
                    BackendEffect.sendToFrontends (List.Nonempty.toList clientIds) LogoutResponse

                Nothing ->
                    BackendEffect.none
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
                            ( addLog (UntrustedCheckFailed model.time msg) model
                            , BackendEffect.none
                            )
                )

        ChangeNameRequest untrustedName ->
            case Untrusted.validateName untrustedName of
                Just name ->
                    userAuthorization
                        sessionId
                        model
                        (\( userId, user ) ->
                            ( { model | users = Dict.insert userId { user | name = name } model.users }
                            , BackendEffect.sendToFrontends
                                (getClientIdsForUser userId model)
                                (ChangeNameResponse name)
                            )
                        )

                Nothing ->
                    ( addLog (UntrustedCheckFailed model.time msg) model
                    , BackendEffect.none
                    )

        ChangeDescriptionRequest untrustedDescription ->
            case Untrusted.description untrustedDescription of
                Just description ->
                    userAuthorization
                        sessionId
                        model
                        (\( userId, user ) ->
                            ( { model | users = Dict.insert userId { user | description = description } model.users }
                            , BackendEffect.sendToFrontends
                                (getClientIdsForUser userId model)
                                (ChangeDescriptionResponse description)
                            )
                        )

                Nothing ->
                    ( addLog (UntrustedCheckFailed model.time msg) model
                    , BackendEffect.none
                    )

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
                            , BackendEffect.sendToFrontends
                                (getClientIdsForUser userId model)
                                (ChangeEmailAddressResponse emailAddress)
                            )
                        )

                Nothing ->
                    ( addLog (UntrustedCheckFailed model.time msg) model
                    , BackendEffect.none
                    )

        SendDeleteUserEmailRequest ->
            userAuthorization
                sessionId
                model
                (\( userId, user ) ->
                    let
                        ( model2, deleteUserToken ) =
                            Id.getUniqueId model
                    in
                    ( { model2
                        | pendingDeleteUserTokens =
                            Dict.insert
                                deleteUserToken
                                { creationTime = model.time, userId = userId }
                                model2.pendingDeleteUserTokens
                      }
                    , BackendEffect.sendDeleteUserEmail
                        (SentDeleteUserEmail user.emailAddress)
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
                            , BackendEffect.sendToFrontends (getClientIdsForUser userId model) response
                            )

                        Nothing ->
                            ( addLog (UntrustedCheckFailed model.time msg) model
                            , BackendEffect.none
                            )
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
                        |> BackendEffect.sendToFrontend clientId
                    )
                )

        SearchGroupsRequest searchText ->
            if String.length searchText < 1000 then
                ( model
                , Dict.toList model.groups
                    |> List.filter (Tuple.second >> Group.visibility >> (==) Group.PublicGroup)
                    |> SearchGroupsResponse searchText
                    |> BackendEffect.sendToFrontend clientId
                )

            else
                ( model, BackendEffect.none )

        ChangeGroupNameRequest groupId untrustedName ->
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
                            , BackendEffect.sendToFrontends
                                (getClientIdsForUser userId model)
                                (ChangeGroupNameResponse groupId name)
                            )
                        )

                Nothing ->
                    ( addLog (UntrustedCheckFailed model.time msg) model
                    , BackendEffect.none
                    )

        ChangeGroupDescriptionRequest groupId untrustedDescription ->
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
                            , BackendEffect.sendToFrontends
                                (getClientIdsForUser userId model)
                                (ChangeGroupDescriptionResponse groupId description)
                            )
                        )

                Nothing ->
                    ( addLog (UntrustedCheckFailed model.time msg) model
                    , BackendEffect.none
                    )

        CreateEventRequest groupId eventName_ description_ eventType_ startTime eventDuration_ ->
            case
                T4
                    (Untrusted.eventName eventName_)
                    (Untrusted.description description_)
                    (Untrusted.eventType eventType_)
                    (Untrusted.eventDuration eventDuration_)
            of
                T4 (Just eventName) (Just description) (Just eventType) (Just eventDuration) ->
                    userWithGroupAuthorization
                        sessionId
                        groupId
                        model
                        (\( userId, _, group ) ->
                            if Group.totalEvents group > 1000 then
                                ( model
                                , BackendEffect.sendToFrontend clientId (CreateEventResponse groupId (Err TooManyEvents))
                                )

                            else if Duration.from model.time startTime |> Quantity.lessThanZero then
                                ( model
                                , BackendEffect.sendToFrontend
                                    clientId
                                    (CreateEventResponse groupId (Err EventStartsInThePast))
                                )

                            else
                                let
                                    newEvent : Event
                                    newEvent =
                                        Event.newEvent eventName description eventType startTime eventDuration
                                            |> Event.addAttendee userId
                                in
                                case Group.addEvent newEvent group of
                                    Ok newGroup ->
                                        ( { model | groups = Dict.insert groupId newGroup model.groups }
                                        , BackendEffect.sendToFrontends
                                            (getClientIdsForUser userId model)
                                            (CreateEventResponse groupId (Ok newEvent))
                                        )

                                    Err overlappingEvents ->
                                        ( model
                                        , BackendEffect.sendToFrontend
                                            clientId
                                            (CreateEventResponse groupId (Err (EventOverlapsOtherEvents overlappingEvents)))
                                        )
                        )

                _ ->
                    ( addLog (UntrustedCheckFailed model.time msg) model
                    , BackendEffect.none
                    )

        JoinEventRequest groupId eventId ->
            userAuthorization
                sessionId
                model
                (\( userId, _ ) ->
                    case getGroup groupId model of
                        Just group ->
                            ( { model
                                | groups =
                                    Dict.insert groupId (Group.joinEvent userId eventId group) model.groups
                              }
                            , BackendEffect.sendToFrontends
                                (getClientIdsForUser userId model)
                                (JoinEventResponse groupId eventId (Ok ()))
                            )

                        Nothing ->
                            ( model
                            , BackendEffect.sendToFrontend
                                clientId
                                (JoinEventResponse groupId eventId (Err ()))
                            )
                )

        LeaveEventRequest groupId eventId ->
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
                            , BackendEffect.sendToFrontends
                                (getClientIdsForUser userId model)
                                (LeaveEventResponse groupId eventId (Ok ()))
                            )

                        Nothing ->
                            ( model
                            , BackendEffect.sendToFrontend
                                clientId
                                (LeaveEventResponse groupId eventId (Err ()))
                            )
                )


handleDeleteUserRequest : ClientId -> Maybe DeleteUserTokenData -> BackendModel -> ( BackendModel, BackendEffect )
handleDeleteUserRequest clientId maybeDeleteUserTokenData model =
    case maybeDeleteUserTokenData of
        Just { creationTime, userId } ->
            if Duration.from creationTime model.time |> Quantity.lessThan Duration.hour then
                ( deleteUser userId model
                , BackendEffect.sendToFrontends (getClientIdsForUser userId model) (DeleteUserResponse (Ok ()))
                )

            else
                ( model, BackendEffect.sendToFrontend clientId (DeleteUserResponse (Err ())) )

        Nothing ->
            ( model, BackendEffect.sendToFrontend clientId (DeleteUserResponse (Err ())) )


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


loginWithToken : SessionId -> ClientId -> Maybe LoginTokenData -> BackendModel -> ( BackendModel, BackendEffect )
loginWithToken sessionId clientId maybeLoginTokenData model =
    let
        loginResponse : ( Id UserId, BackendUser ) -> BackendEffect
        loginResponse userEntry =
            case Dict.get sessionId model.connections of
                Just clientIds ->
                    Ok userEntry
                        |> LoginWithTokenResponse
                        |> BackendEffect.sendToFrontends (List.Nonempty.toList clientIds)

                Nothing ->
                    BackendEffect.none

        addSession : Id UserId -> BackendModel -> BackendModel
        addSession userId model_ =
            { model_ | sessions = BiDict.insert sessionId userId model_.sessions }
    in
    case maybeLoginTokenData of
        Just { creationTime, emailAddress } ->
            if Duration.from creationTime model.time |> Quantity.lessThan Duration.hour then
                case Dict.toList model.users |> List.find (Tuple.second >> .emailAddress >> (==) emailAddress) of
                    Just userEntry ->
                        ( addSession (Tuple.first userEntry) model
                        , loginResponse userEntry
                        )

                    Nothing ->
                        let
                            ( model2, userId ) =
                                Id.getUniqueId model

                            newUser : BackendUser
                            newUser =
                                { name = Name.anonymous
                                , description = Description.empty
                                , emailAddress = emailAddress
                                , profileImage = ProfileImage.defaultImage
                                }
                        in
                        ( { model2 | users = Dict.insert userId newUser model2.users }
                            |> addSession userId
                        , loginResponse ( userId, newUser )
                        )

            else
                ( model, Err () |> LoginWithTokenResponse |> BackendEffect.sendToFrontend clientId )

        Nothing ->
            ( model, Err () |> LoginWithTokenResponse |> BackendEffect.sendToFrontend clientId )


getAndRemoveLoginToken :
    (Maybe LoginTokenData -> BackendModel -> ( BackendModel, BackendEffect ))
    -> Id LoginToken
    -> BackendModel
    -> ( BackendModel, BackendEffect )
getAndRemoveLoginToken updateFunc loginToken model =
    updateFunc
        (Dict.get loginToken model.pendingLoginTokens)
        { model | pendingLoginTokens = Dict.remove loginToken model.pendingLoginTokens }


getAndRemoveDeleteUserToken :
    (Maybe DeleteUserTokenData -> BackendModel -> ( BackendModel, BackendEffect ))
    -> Id DeleteUserToken
    -> BackendModel
    -> ( BackendModel, BackendEffect )
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
    -> ( BackendModel, BackendEffect )
addGroup clientId userId name description visibility model =
    if Dict.values model.groups |> List.any (Group.name >> GroupName.namesMatch name) then
        ( model, Err GroupNameAlreadyInUse |> CreateGroupResponse |> BackendEffect.sendToFrontend clientId )

    else
        let
            groupId =
                Id.groupIdFromInt model.groupIdCounter

            newGroup =
                Group.init userId name description visibility
        in
        ( { model | groupIdCounter = model.groupIdCounter + 1, groups = Dict.insert groupId newGroup model.groups }
        , Ok ( groupId, newGroup ) |> CreateGroupResponse |> BackendEffect.sendToFrontend clientId
        )


userAuthorization :
    SessionId
    -> BackendModel
    -> (( Id UserId, BackendUser ) -> ( BackendModel, BackendEffect ))
    -> ( BackendModel, BackendEffect )
userAuthorization sessionId model updateFunc =
    case checkLogin sessionId model of
        Just ( userId, user ) ->
            updateFunc ( userId, user )

        Nothing ->
            ( model, BackendEffect.none )


userWithGroupAuthorization :
    SessionId
    -> GroupId
    -> BackendModel
    -> (( Id UserId, BackendUser, Group ) -> ( BackendModel, BackendEffect ))
    -> ( BackendModel, BackendEffect )
userWithGroupAuthorization sessionId groupId model updateFunc =
    case checkLogin sessionId model of
        Just ( userId, user ) ->
            case getGroup groupId model of
                Just group ->
                    if Group.ownerId group == userId then
                        updateFunc ( userId, user, group )

                    else
                        ( model, BackendEffect.none )

                Nothing ->
                    ( model, BackendEffect.none )

        Nothing ->
            ( model, BackendEffect.none )


adminAuthorization :
    SessionId
    -> BackendModel
    -> (( Id UserId, BackendUser ) -> ( BackendModel, BackendEffect ))
    -> ( BackendModel, BackendEffect )
adminAuthorization sessionId model updateFunc =
    case checkLogin sessionId model of
        Just ( userId, user ) ->
            if Id.adminUserId == userId then
                updateFunc ( userId, user )

            else
                ( model, BackendEffect.none )

        Nothing ->
            ( model, BackendEffect.none )


checkLogin : SessionId -> BackendModel -> Maybe ( Id UserId, BackendUser )
checkLogin sessionId model =
    case BiDict.get sessionId model.sessions of
        Just userId ->
            case Dict.get userId model.users of
                Just user ->
                    Just ( userId, user )

                Nothing ->
                    Nothing

        Nothing ->
            Nothing


getGroup : GroupId -> BackendModel -> Maybe Group
getGroup groupId model =
    Dict.get groupId model.groups


getUser : Id UserId -> BackendModel -> Maybe BackendUser
getUser userId model =
    Dict.get userId model.users


getUserFromSessionId : SessionId -> BackendModel -> Maybe ( Id UserId, BackendUser )
getUserFromSessionId sessionId model =
    BiDict.get sessionId model.sessions
        |> Maybe.andThen (\userId -> getUser userId model |> Maybe.map (Tuple.pair userId))
