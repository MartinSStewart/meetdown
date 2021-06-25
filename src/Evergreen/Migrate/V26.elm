module Evergreen.Migrate.V26 exposing (..)

import Array
import AssocList as Dict
import AssocSet as Set
import BiDict.Assoc as BiDict
import Evergreen.V25.Address
import Evergreen.V25.Description
import Evergreen.V25.Event
import Evergreen.V25.EventDuration
import Evergreen.V25.EventName
import Evergreen.V25.Group
import Evergreen.V25.GroupName
import Evergreen.V25.Id
import Evergreen.V25.Link
import Evergreen.V25.MaxAttendees
import Evergreen.V25.Name
import Evergreen.V25.ProfileImage
import Evergreen.V25.Route
import Evergreen.V25.Types as Old
import Evergreen.V25.Untrusted
import Evergreen.V26.Address
import Evergreen.V26.Description
import Evergreen.V26.Event
import Evergreen.V26.EventDuration
import Evergreen.V26.EventName
import Evergreen.V26.Group
import Evergreen.V26.GroupName
import Evergreen.V26.Id
import Evergreen.V26.Link
import Evergreen.V26.MaxAttendees
import Evergreen.V26.Name
import Evergreen.V26.ProfileImage
import Evergreen.V26.Route
import Evergreen.V26.Types as New
import Evergreen.V26.Untrusted
import Lamdera.Migrations exposing (..)
import List.Nonempty


frontendModel : Old.FrontendModel -> ModelMigration New.FrontendModel New.FrontendMsg
frontendModel old =
    ModelUnchanged


migrateName : Evergreen.V25.Name.Name -> Evergreen.V26.Name.Name
migrateName (Evergreen.V25.Name.Name name) =
    Evergreen.V26.Name.Name name


migrateDescription : Evergreen.V25.Description.Description -> Evergreen.V26.Description.Description
migrateDescription (Evergreen.V25.Description.Description name) =
    Evergreen.V26.Description.Description name


migrateProfileImage : Evergreen.V25.ProfileImage.ProfileImage -> Evergreen.V26.ProfileImage.ProfileImage
migrateProfileImage a =
    case a of
        Evergreen.V25.ProfileImage.DefaultImage ->
            Evergreen.V26.ProfileImage.DefaultImage

        Evergreen.V25.ProfileImage.CustomImage b ->
            Evergreen.V26.ProfileImage.CustomImage b


migrateBackendUser : Old.BackendUser -> New.BackendUser
migrateBackendUser backendUser =
    { name = migrateName backendUser.name
    , description = migrateDescription backendUser.description
    , emailAddress = backendUser.emailAddress
    , profileImage = migrateProfileImage backendUser.profileImage
    , timezone = backendUser.timezone
    , allowEventReminders = backendUser.allowEventReminders
    }


migrateId : Evergreen.V25.Id.Id a -> Evergreen.V26.Id.Id b
migrateId (Evergreen.V25.Id.Id id) =
    Evergreen.V26.Id.Id id


migrateUserId : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId -> Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
migrateUserId (Evergreen.V25.Id.Id id) =
    String.left 5 id |> Evergreen.V26.Id.Id


migrateSessionIdFirst4Chars : Evergreen.V25.Id.SessionIdFirst4Chars -> Evergreen.V26.Id.SessionIdFirst4Chars
migrateSessionIdFirst4Chars (Evergreen.V25.Id.SessionIdFirst4Chars id) =
    Evergreen.V26.Id.SessionIdFirst4Chars id


migrateSessionId : Evergreen.V25.Id.SessionId -> Evergreen.V26.Id.SessionId
migrateSessionId (Evergreen.V25.Id.SessionId id) =
    Evergreen.V26.Id.SessionId id


migrateClientId : Evergreen.V25.Id.ClientId -> Evergreen.V26.Id.ClientId
migrateClientId (Evergreen.V25.Id.ClientId id) =
    Evergreen.V26.Id.ClientId id


migrateGroupName : Evergreen.V25.GroupName.GroupName -> Evergreen.V26.GroupName.GroupName
migrateGroupName (Evergreen.V25.GroupName.GroupName id) =
    Evergreen.V26.GroupName.GroupName id


migrateEventId : Evergreen.V25.Group.EventId -> Evergreen.V26.Group.EventId
migrateEventId (Evergreen.V25.Group.EventId id) =
    Evergreen.V26.Group.EventId id


migrateGroupId : Evergreen.V25.Id.GroupId -> Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId
migrateGroupId (Evergreen.V25.Id.GroupId id) =
    Evergreen.V26.Id.Id ("1056" ++ String.fromInt id)


migrateEventName : Evergreen.V25.EventName.EventName -> Evergreen.V26.EventName.EventName
migrateEventName (Evergreen.V25.EventName.EventName a) =
    Evergreen.V26.EventName.EventName a


migrateLink : Evergreen.V25.Link.Link -> Evergreen.V26.Link.Link
migrateLink (Evergreen.V25.Link.Link a) =
    Evergreen.V26.Link.Link a


migrateAddress : Evergreen.V25.Address.Address -> Evergreen.V26.Address.Address
migrateAddress (Evergreen.V25.Address.Address a) =
    Evergreen.V26.Address.Address a


migrateEventType : Evergreen.V25.Event.EventType -> Evergreen.V26.Event.EventType
migrateEventType a =
    case a of
        Evergreen.V25.Event.MeetOnline maybeLink ->
            Maybe.map migrateLink maybeLink |> Evergreen.V26.Event.MeetOnline

        Evergreen.V25.Event.MeetInPerson maybeAddress ->
            Maybe.map migrateAddress maybeAddress |> Evergreen.V26.Event.MeetInPerson


migrateEventDuration : Evergreen.V25.EventDuration.EventDuration -> Evergreen.V26.EventDuration.EventDuration
migrateEventDuration (Evergreen.V25.EventDuration.EventDuration a) =
    Evergreen.V26.EventDuration.EventDuration a


migrateCancellationStatus : Evergreen.V25.Event.CancellationStatus -> Evergreen.V26.Event.CancellationStatus
migrateCancellationStatus a =
    case a of
        Evergreen.V25.Event.EventCancelled ->
            Evergreen.V26.Event.EventCancelled

        Evergreen.V25.Event.EventUncancelled ->
            Evergreen.V26.Event.EventUncancelled


migrateMaxAttendees : Evergreen.V25.MaxAttendees.MaxAttendees -> Evergreen.V26.MaxAttendees.MaxAttendees
migrateMaxAttendees a =
    case a of
        Evergreen.V25.MaxAttendees.NoLimit ->
            Evergreen.V26.MaxAttendees.NoLimit

        Evergreen.V25.MaxAttendees.MaxAttendees b ->
            Evergreen.V26.MaxAttendees.MaxAttendees b


migrateEvent : Evergreen.V25.Event.Event -> Evergreen.V26.Event.Event
migrateEvent (Evergreen.V25.Event.Event event) =
    Evergreen.V26.Event.Event
        { name = migrateEventName event.name
        , description = migrateDescription event.description
        , eventType = migrateEventType event.eventType
        , attendees = Set.map migrateId event.attendees
        , startTime = event.startTime
        , duration = migrateEventDuration event.duration
        , cancellationStatus = Maybe.map (Tuple.mapFirst migrateCancellationStatus) event.cancellationStatus
        , createdAt = event.createdAt
        , maxAttendees = migrateMaxAttendees event.maxAttendees
        }


migrateGroupVisibility : Evergreen.V25.Group.GroupVisibility -> Evergreen.V26.Group.GroupVisibility
migrateGroupVisibility a =
    case a of
        Evergreen.V25.Group.UnlistedGroup ->
            Evergreen.V26.Group.UnlistedGroup

        Evergreen.V25.Group.PublicGroup ->
            Evergreen.V26.Group.PublicGroup


migrateGroup : Evergreen.V25.Group.Group -> Evergreen.V26.Group.Group
migrateGroup (Evergreen.V25.Group.Group group) =
    Evergreen.V26.Group.Group
        { ownerId = migrateId group.ownerId
        , name = migrateGroupName group.name
        , description = migrateDescription group.description
        , events =
            Dict.toList group.events
                |> List.map (Tuple.mapBoth migrateEventId migrateEvent)
                |> Dict.fromList
        , visibility = migrateGroupVisibility group.visibility
        , eventCounter = group.eventCounter
        , createdAt = group.createdAt
        , pendingReview = group.pendingReview
        }


migrateUntrusted : (a -> b) -> Evergreen.V25.Untrusted.Untrusted a -> Evergreen.V26.Untrusted.Untrusted b
migrateUntrusted mapFunc (Evergreen.V25.Untrusted.Untrusted a) =
    Evergreen.V26.Untrusted.Untrusted (mapFunc a)


migrateRoute : Evergreen.V25.Route.Route -> Evergreen.V26.Route.Route
migrateRoute a =
    case a of
        Evergreen.V25.Route.HomepageRoute ->
            Evergreen.V26.Route.HomepageRoute

        Evergreen.V25.Route.GroupRoute groupId groupName ->
            Evergreen.V26.Route.GroupRoute (migrateGroupId groupId) (migrateGroupName groupName)

        Evergreen.V25.Route.AdminRoute ->
            Evergreen.V26.Route.AdminRoute

        Evergreen.V25.Route.CreateGroupRoute ->
            Evergreen.V26.Route.CreateGroupRoute

        Evergreen.V25.Route.SearchGroupsRoute string ->
            Evergreen.V26.Route.SearchGroupsRoute string

        Evergreen.V25.Route.MyGroupsRoute ->
            Evergreen.V26.Route.MyGroupsRoute

        Evergreen.V25.Route.MyProfileRoute ->
            Evergreen.V26.Route.MyProfileRoute

        Evergreen.V25.Route.UserRoute id ->
            Evergreen.V26.Route.UserRoute (migrateId id) (Evergreen.V26.Name.Name "temp")


migrateToBackend : Old.ToBackend -> New.ToBackend
migrateToBackend toBackend_ =
    case toBackend_ of
        Old.GetGroupRequest a ->
            New.GetGroupRequest (migrateGroupId a)

        Old.GetUserRequest a ->
            New.GetUserRequest (migrateId a)

        Old.CheckLoginRequest ->
            New.CheckLoginRequest

        Old.LoginWithTokenRequest a b ->
            New.LoginWithTokenRequest (migrateId a) (Maybe.map (Tuple.mapBoth migrateGroupId migrateEventId) b)

        Old.GetLoginTokenRequest a b c ->
            New.GetLoginTokenRequest
                (migrateRoute a)
                (migrateUntrusted identity b)
                (Maybe.map (Tuple.mapBoth migrateGroupId migrateEventId) c)

        Old.GetAdminDataRequest ->
            New.GetAdminDataRequest

        Old.LogoutRequest ->
            New.LogoutRequest

        Old.CreateGroupRequest a b c ->
            New.CreateGroupRequest
                (migrateUntrusted migrateGroupName a)
                (migrateUntrusted migrateDescription b)
                (migrateGroupVisibility c)

        Old.ChangeNameRequest a ->
            New.ChangeNameRequest (migrateUntrusted migrateName a)

        Old.ChangeDescriptionRequest a ->
            New.ChangeDescriptionRequest (migrateUntrusted migrateDescription a)

        Old.ChangeEmailAddressRequest a ->
            New.ChangeEmailAddressRequest (migrateUntrusted identity a)

        Old.SendDeleteUserEmailRequest ->
            New.SendDeleteUserEmailRequest

        Old.DeleteUserRequest a ->
            New.DeleteUserRequest (migrateId a)

        Old.ChangeProfileImageRequest a ->
            New.ChangeProfileImageRequest (migrateUntrusted migrateProfileImage a)

        Old.GetMyGroupsRequest ->
            New.GetMyGroupsRequest

        Old.SearchGroupsRequest a ->
            New.SearchGroupsRequest a

        Old.ChangeGroupNameRequest a b ->
            New.ChangeGroupNameRequest (migrateGroupId a) (migrateUntrusted migrateGroupName b)

        Old.ChangeGroupDescriptionRequest a b ->
            New.ChangeGroupDescriptionRequest (migrateGroupId a) (migrateUntrusted migrateDescription b)

        Old.CreateEventRequest a b c d e f g ->
            New.CreateEventRequest
                (migrateGroupId a)
                (migrateUntrusted migrateEventName b)
                (migrateUntrusted migrateDescription c)
                (migrateUntrusted migrateEventType d)
                e
                (migrateUntrusted migrateEventDuration f)
                (migrateUntrusted migrateMaxAttendees g)

        Old.EditEventRequest a b c d e f g h ->
            New.EditEventRequest
                (migrateGroupId a)
                (migrateEventId b)
                (migrateUntrusted migrateEventName c)
                (migrateUntrusted migrateDescription d)
                (migrateUntrusted migrateEventType e)
                f
                (migrateUntrusted migrateEventDuration g)
                (migrateUntrusted migrateMaxAttendees h)

        Old.JoinEventRequest a b ->
            New.JoinEventRequest (migrateGroupId a) (migrateEventId b)

        Old.LeaveEventRequest a b ->
            New.LeaveEventRequest (migrateGroupId a) (migrateEventId b)

        Old.ChangeEventCancellationStatusRequest a b c ->
            New.ChangeEventCancellationStatusRequest (migrateGroupId a) (migrateEventId b) (migrateCancellationStatus c)


migrateLog : Old.Log -> New.Log
migrateLog log =
    case log of
        Old.LogUntrustedCheckFailed a b c ->
            New.LogUntrustedCheckFailed a (migrateToBackend b) (migrateSessionIdFirst4Chars c)

        Old.LogLoginEmail posix result emailAddress ->
            New.LogLoginEmail posix result emailAddress

        Old.LogDeleteAccountEmail posix result id ->
            New.LogDeleteAccountEmail posix result (migrateId id)

        Old.LogEventReminderEmail posix result id groupId eventId ->
            New.LogEventReminderEmail posix result (migrateId id) (migrateGroupId groupId) (migrateEventId eventId)

        Old.LogLoginTokenEmailRequestRateLimited a b c ->
            New.LogLoginTokenEmailRequestRateLimited a b (migrateSessionIdFirst4Chars c)

        Old.LogDeleteAccountEmailRequestRateLimited a b c ->
            New.LogDeleteAccountEmailRequestRateLimited a (migrateId b) (migrateSessionIdFirst4Chars c)


migrateDeleteUserToken : Old.DeleteUserTokenData -> New.DeleteUserTokenData
migrateDeleteUserToken a =
    { creationTime = a.creationTime
    , userId = migrateId a.userId
    }


migrateBackendModel : Old.BackendModel -> New.BackendModel
migrateBackendModel old =
    { users =
        Dict.toList old.users
            |> List.map (Tuple.mapBoth migrateId migrateBackendUser)
            |> Dict.fromList
    , groups =
        Dict.toList old.groups
            |> List.map (Tuple.mapBoth migrateGroupId migrateGroup)
            |> Dict.fromList
    , sessions =
        BiDict.toList old.sessions
            |> List.map (Tuple.mapBoth migrateSessionId migrateId)
            |> BiDict.fromList
    , loginAttempts = Dict.toList old.loginAttempts |> List.map (Tuple.mapFirst migrateSessionId) |> Dict.fromList
    , connections =
        Dict.toList old.connections
            |> List.map (Tuple.mapBoth migrateSessionId (List.Nonempty.map migrateClientId))
            |> Dict.fromList
    , logs = Array.map migrateLog old.logs
    , time = old.time
    , secretCounter = old.secretCounter
    , pendingLoginTokens =
        Dict.toList old.pendingLoginTokens
            |> List.map (Tuple.mapFirst migrateId)
            |> Dict.fromList
    , pendingDeleteUserTokens =
        Dict.toList old.pendingDeleteUserTokens
            |> List.map (Tuple.mapBoth migrateId migrateDeleteUserToken)
            |> Dict.fromList
    }


backendModel : Old.BackendModel -> ModelMigration New.BackendModel New.BackendMsg
backendModel old =
    ModelMigrated ( migrateBackendModel old, Cmd.none )


frontendMsg : Old.FrontendMsg -> MsgMigration New.FrontendMsg New.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend : Old.ToBackend -> MsgMigration New.ToBackend New.BackendMsg
toBackend old =
    MsgMigrated ( migrateToBackend old, Cmd.none )


backendMsg : Old.BackendMsg -> MsgMigration New.BackendMsg New.BackendMsg
backendMsg old =
    MsgUnchanged


toFrontend : Old.ToFrontend -> MsgMigration New.ToFrontend New.FrontendMsg
toFrontend old =
    MsgUnchanged
