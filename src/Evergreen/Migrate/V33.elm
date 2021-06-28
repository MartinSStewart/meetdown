module Evergreen.Migrate.V33 exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc as BiDict
import Evergreen.V30.Address
import Evergreen.V30.Description
import Evergreen.V30.EmailAddress
import Evergreen.V30.Event
import Evergreen.V30.EventDuration
import Evergreen.V30.EventName
import Evergreen.V30.Group
import Evergreen.V30.GroupName
import Evergreen.V30.Id
import Evergreen.V30.Link
import Evergreen.V30.MaxAttendees
import Evergreen.V30.Name
import Evergreen.V30.ProfileImage
import Evergreen.V30.Route
import Evergreen.V30.Types as Old
import Evergreen.V30.Untrusted
import Evergreen.V33.Address
import Evergreen.V33.Description
import Evergreen.V33.EmailAddress
import Evergreen.V33.Event
import Evergreen.V33.EventDuration
import Evergreen.V33.EventName
import Evergreen.V33.Group
import Evergreen.V33.GroupName
import Evergreen.V33.Id
import Evergreen.V33.Link
import Evergreen.V33.MaxAttendees
import Evergreen.V33.Name
import Evergreen.V33.ProfileImage
import Evergreen.V33.Route
import Evergreen.V33.Types as New
import Evergreen.V33.Untrusted
import Lamdera.Migrations exposing (..)
import List.Nonempty


frontendModel : Old.FrontendModel -> ModelMigration New.FrontendModel New.FrontendMsg
frontendModel old =
    ModelUnchanged


migrateName : Evergreen.V30.Name.Name -> Evergreen.V33.Name.Name
migrateName (Evergreen.V30.Name.Name name) =
    Evergreen.V33.Name.Name name


migrateDescription : Evergreen.V30.Description.Description -> Evergreen.V33.Description.Description
migrateDescription (Evergreen.V30.Description.Description name) =
    Evergreen.V33.Description.Description name


migrateProfileImage : Evergreen.V30.ProfileImage.ProfileImage -> Evergreen.V33.ProfileImage.ProfileImage
migrateProfileImage a =
    case a of
        Evergreen.V30.ProfileImage.DefaultImage ->
            Evergreen.V33.ProfileImage.DefaultImage

        Evergreen.V30.ProfileImage.CustomImage b ->
            Evergreen.V33.ProfileImage.CustomImage b


migrateBackendUser : Old.BackendUser -> New.BackendUser
migrateBackendUser backendUser =
    { name = migrateName backendUser.name
    , description = migrateDescription backendUser.description
    , emailAddress = migrateEmailAddress backendUser.emailAddress
    , profileImage = migrateProfileImage backendUser.profileImage
    , timezone = backendUser.timezone
    , allowEventReminders = backendUser.allowEventReminders
    }


migrateId : Evergreen.V30.Id.Id a -> Evergreen.V33.Id.Id b
migrateId (Evergreen.V30.Id.Id id) =
    Evergreen.V33.Id.Id id


migrateUserId : Evergreen.V30.Id.Id Evergreen.V30.Id.UserId -> Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
migrateUserId (Evergreen.V30.Id.Id id) =
    Evergreen.V33.Id.Id id


migrateSessionIdFirst4Chars : Evergreen.V30.Id.SessionIdFirst4Chars -> Evergreen.V33.Id.SessionIdFirst4Chars
migrateSessionIdFirst4Chars (Evergreen.V30.Id.SessionIdFirst4Chars id) =
    Evergreen.V33.Id.SessionIdFirst4Chars id


migrateSessionId : Evergreen.V30.Id.SessionId -> Evergreen.V33.Id.SessionId
migrateSessionId (Evergreen.V30.Id.SessionId id) =
    Evergreen.V33.Id.SessionId id


migrateClientId : Evergreen.V30.Id.ClientId -> Evergreen.V33.Id.ClientId
migrateClientId (Evergreen.V30.Id.ClientId id) =
    Evergreen.V33.Id.ClientId id


migrateGroupName : Evergreen.V30.GroupName.GroupName -> Evergreen.V33.GroupName.GroupName
migrateGroupName (Evergreen.V30.GroupName.GroupName id) =
    Evergreen.V33.GroupName.GroupName id


migrateEventId : Evergreen.V30.Group.EventId -> Evergreen.V33.Group.EventId
migrateEventId (Evergreen.V30.Group.EventId id) =
    Evergreen.V33.Group.EventId id


migrateGroupId : Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId -> Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId
migrateGroupId (Evergreen.V30.Id.Id id) =
    Evergreen.V33.Id.Id id


migrateEventName : Evergreen.V30.EventName.EventName -> Evergreen.V33.EventName.EventName
migrateEventName (Evergreen.V30.EventName.EventName a) =
    Evergreen.V33.EventName.EventName a


migrateLink : Evergreen.V30.Link.Link -> Evergreen.V33.Link.Link
migrateLink (Evergreen.V30.Link.Link a) =
    Evergreen.V33.Link.Link a


migrateAddress : Evergreen.V30.Address.Address -> Evergreen.V33.Address.Address
migrateAddress (Evergreen.V30.Address.Address a) =
    Evergreen.V33.Address.Address a


migrateEventType : Evergreen.V30.Event.EventType -> Evergreen.V33.Event.EventType
migrateEventType a =
    case a of
        Evergreen.V30.Event.MeetOnline maybeLink ->
            Maybe.map migrateLink maybeLink |> Evergreen.V33.Event.MeetOnline

        Evergreen.V30.Event.MeetInPerson maybeAddress ->
            Maybe.map migrateAddress maybeAddress |> Evergreen.V33.Event.MeetInPerson


migrateEventDuration : Evergreen.V30.EventDuration.EventDuration -> Evergreen.V33.EventDuration.EventDuration
migrateEventDuration (Evergreen.V30.EventDuration.EventDuration a) =
    Evergreen.V33.EventDuration.EventDuration a


migrateCancellationStatus : Evergreen.V30.Event.CancellationStatus -> Evergreen.V33.Event.CancellationStatus
migrateCancellationStatus a =
    case a of
        Evergreen.V30.Event.EventCancelled ->
            Evergreen.V33.Event.EventCancelled

        Evergreen.V30.Event.EventUncancelled ->
            Evergreen.V33.Event.EventUncancelled


migrateMaxAttendees : Evergreen.V30.MaxAttendees.MaxAttendees -> Evergreen.V33.MaxAttendees.MaxAttendees
migrateMaxAttendees a =
    case a of
        Evergreen.V30.MaxAttendees.NoLimit ->
            Evergreen.V33.MaxAttendees.NoLimit

        Evergreen.V30.MaxAttendees.MaxAttendees b ->
            Evergreen.V33.MaxAttendees.MaxAttendees b


migrateEvent : Evergreen.V30.Event.Event -> Evergreen.V33.Event.Event
migrateEvent (Evergreen.V30.Event.Event event) =
    Evergreen.V33.Event.Event
        { name = migrateEventName event.name
        , description = migrateDescription event.description
        , eventType = migrateEventType event.eventType
        , attendees = AssocSet.map migrateUserId event.attendees
        , startTime = event.startTime
        , duration = migrateEventDuration event.duration
        , cancellationStatus = Maybe.map (Tuple.mapFirst migrateCancellationStatus) event.cancellationStatus
        , createdAt = event.createdAt
        , maxAttendees = migrateMaxAttendees event.maxAttendees
        }


migrateGroupVisibility : Evergreen.V30.Group.GroupVisibility -> Evergreen.V33.Group.GroupVisibility
migrateGroupVisibility a =
    case a of
        Evergreen.V30.Group.UnlistedGroup ->
            Evergreen.V33.Group.UnlistedGroup

        Evergreen.V30.Group.PublicGroup ->
            Evergreen.V33.Group.PublicGroup


migrateGroup : Evergreen.V30.Group.Group -> Evergreen.V33.Group.Group
migrateGroup (Evergreen.V30.Group.Group group) =
    Evergreen.V33.Group.Group
        { ownerId = migrateUserId group.ownerId
        , name = migrateGroupName group.name
        , description = migrateDescription group.description
        , events =
            AssocList.toList group.events
                |> List.map (Tuple.mapBoth migrateEventId migrateEvent)
                |> AssocList.fromList
        , visibility = migrateGroupVisibility group.visibility
        , eventCounter = group.eventCounter
        , createdAt = group.createdAt
        , pendingReview = group.pendingReview
        }


migrateUntrusted : (a -> b) -> Evergreen.V30.Untrusted.Untrusted a -> Evergreen.V33.Untrusted.Untrusted b
migrateUntrusted mapFunc (Evergreen.V30.Untrusted.Untrusted a) =
    Evergreen.V33.Untrusted.Untrusted (mapFunc a)


migrateRoute : Evergreen.V30.Route.Route -> Evergreen.V33.Route.Route
migrateRoute a =
    case a of
        Evergreen.V30.Route.HomepageRoute ->
            Evergreen.V33.Route.HomepageRoute

        Evergreen.V30.Route.GroupRoute groupId groupName ->
            Evergreen.V33.Route.GroupRoute (migrateGroupId groupId) (migrateGroupName groupName)

        Evergreen.V30.Route.AdminRoute ->
            Evergreen.V33.Route.AdminRoute

        Evergreen.V30.Route.CreateGroupRoute ->
            Evergreen.V33.Route.CreateGroupRoute

        Evergreen.V30.Route.SearchGroupsRoute string ->
            Evergreen.V33.Route.SearchGroupsRoute string

        Evergreen.V30.Route.MyGroupsRoute ->
            Evergreen.V33.Route.MyGroupsRoute

        Evergreen.V30.Route.MyProfileRoute ->
            Evergreen.V33.Route.MyProfileRoute

        Evergreen.V30.Route.UserRoute userId name ->
            Evergreen.V33.Route.UserRoute (migrateUserId userId) (migrateName name)

        Evergreen.V30.Route.PrivacyRoute ->
            Evergreen.V33.Route.PrivacyRoute

        Evergreen.V30.Route.TermsOfServiceRoute ->
            Evergreen.V33.Route.TermsOfServiceRoute

        Evergreen.V30.Route.CodeOfConductRoute ->
            Evergreen.V33.Route.CodeOfConductRoute


migrateToBackend : Old.ToBackend -> New.ToBackend
migrateToBackend toBackend_ =
    case toBackend_ of
        Old.GetGroupRequest a ->
            New.GetGroupRequest (migrateGroupId a)

        Old.GetUserRequest a ->
            New.GetUserRequest (migrateUserId a)

        Old.CheckLoginRequest ->
            New.CheckLoginRequest

        Old.LoginWithTokenRequest a b ->
            New.LoginWithTokenRequest (migrateId a) (Maybe.map (Tuple.mapBoth migrateGroupId migrateEventId) b)

        Old.GetLoginTokenRequest a b c ->
            New.GetLoginTokenRequest
                (migrateRoute a)
                (migrateUntrusted migrateEmailAddress b)
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
            New.ChangeEmailAddressRequest (migrateUntrusted migrateEmailAddress a)

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


migrateEmailAddress : Evergreen.V30.EmailAddress.EmailAddress -> Evergreen.V33.EmailAddress.EmailAddress
migrateEmailAddress (Evergreen.V30.EmailAddress.EmailAddress { domain, localPart, tags, tld }) =
    Evergreen.V33.EmailAddress.EmailAddress { domain = domain, localPart = localPart, tags = tags, tld = tld }


migrateDeleteUserToken : Old.DeleteUserTokenData -> New.DeleteUserTokenData
migrateDeleteUserToken a =
    { creationTime = a.creationTime
    , userId = migrateUserId a.userId
    }


migrateLoginTokenData : Old.LoginTokenData -> New.LoginTokenData
migrateLoginTokenData { creationTime, emailAddress } =
    New.LoginTokenData creationTime (migrateEmailAddress emailAddress)


migrateLog : Old.Log -> New.Log
migrateLog log =
    case log of
        Old.LogUntrustedCheckFailed a b c ->
            New.LogUntrustedCheckFailed a (migrateToBackend b) (migrateSessionIdFirst4Chars c)

        Old.LogLoginEmail posix result emailAddress ->
            New.LogLoginEmail posix result (migrateEmailAddress emailAddress)

        Old.LogDeleteAccountEmail posix result id ->
            New.LogDeleteAccountEmail posix result (migrateId id)

        Old.LogEventReminderEmail posix result id groupId eventId ->
            New.LogEventReminderEmail posix result (migrateId id) (migrateGroupId groupId) (migrateEventId eventId)

        Old.LogLoginTokenEmailRequestRateLimited a b c ->
            New.LogLoginTokenEmailRequestRateLimited a (migrateEmailAddress b) (migrateSessionIdFirst4Chars c)

        Old.LogDeleteAccountEmailRequestRateLimited a b c ->
            New.LogDeleteAccountEmailRequestRateLimited a (migrateId b) (migrateSessionIdFirst4Chars c)


migrateBackendModel : Old.BackendModel -> New.BackendModel
migrateBackendModel old =
    { users =
        AssocList.toList old.users
            |> List.map (Tuple.mapBoth migrateUserId migrateBackendUser)
            |> AssocList.fromList
    , groups =
        AssocList.toList old.groups
            |> List.map (Tuple.mapBoth migrateGroupId migrateGroup)
            |> AssocList.fromList
    , sessions =
        BiDict.toList old.sessions
            |> List.map (Tuple.mapBoth migrateSessionId migrateUserId)
            |> BiDict.fromList
    , loginAttempts = AssocList.toList old.loginAttempts |> List.map (Tuple.mapFirst migrateSessionId) |> AssocList.fromList
    , connections =
        AssocList.toList old.connections
            |> List.map (Tuple.mapBoth migrateSessionId (List.Nonempty.map migrateClientId))
            |> AssocList.fromList
    , logs = Array.map migrateLog old.logs
    , time = old.time
    , secretCounter = old.secretCounter
    , pendingLoginTokens =
        AssocList.toList old.pendingLoginTokens
            |> List.map (Tuple.mapBoth migrateId migrateLoginTokenData)
            |> AssocList.fromList
    , pendingDeleteUserTokens =
        AssocList.toList old.pendingDeleteUserTokens
            |> List.map (Tuple.mapBoth migrateId migrateDeleteUserToken)
            |> AssocList.fromList
    }


backendModel : Old.BackendModel -> ModelMigration New.BackendModel New.BackendMsg
backendModel old =
    ModelMigrated ( migrateBackendModel old, Cmd.none )


frontendMsg : Old.FrontendMsg -> MsgMigration New.FrontendMsg New.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend : Old.ToBackend -> MsgMigration New.ToBackend New.BackendMsg
toBackend old =
    MsgUnchanged


backendMsg : Old.BackendMsg -> MsgMigration New.BackendMsg New.BackendMsg
backendMsg old =
    MsgOldValueIgnored


toFrontend : Old.ToFrontend -> MsgMigration New.ToFrontend New.FrontendMsg
toFrontend old =
    MsgOldValueIgnored
