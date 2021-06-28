module Evergreen.Migrate.V37 exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc as BiDict
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
import Evergreen.V33.Types as Old
import Evergreen.V33.Untrusted
import Evergreen.V37.Address
import Evergreen.V37.Description
import Evergreen.V37.EmailAddress
import Evergreen.V37.Event
import Evergreen.V37.EventDuration
import Evergreen.V37.EventName
import Evergreen.V37.Group
import Evergreen.V37.GroupName
import Evergreen.V37.Id
import Evergreen.V37.Link
import Evergreen.V37.MaxAttendees
import Evergreen.V37.Name
import Evergreen.V37.ProfileImage
import Evergreen.V37.Route
import Evergreen.V37.Types as New
import Evergreen.V37.Untrusted
import Lamdera.Migrations exposing (..)
import List.Nonempty


frontendModel : Old.FrontendModel -> ModelMigration New.FrontendModel New.FrontendMsg
frontendModel old =
    ModelUnchanged


migrateName : Evergreen.V33.Name.Name -> Evergreen.V37.Name.Name
migrateName (Evergreen.V33.Name.Name name) =
    Evergreen.V37.Name.Name name


migrateDescription : Evergreen.V33.Description.Description -> Evergreen.V37.Description.Description
migrateDescription (Evergreen.V33.Description.Description name) =
    Evergreen.V37.Description.Description name


migrateProfileImage : Evergreen.V33.ProfileImage.ProfileImage -> Evergreen.V37.ProfileImage.ProfileImage
migrateProfileImage a =
    case a of
        Evergreen.V33.ProfileImage.DefaultImage ->
            Evergreen.V37.ProfileImage.DefaultImage

        Evergreen.V33.ProfileImage.CustomImage b ->
            Evergreen.V37.ProfileImage.CustomImage b


migrateBackendUser : Old.BackendUser -> New.BackendUser
migrateBackendUser backendUser =
    { name = migrateName backendUser.name
    , description = migrateDescription backendUser.description
    , emailAddress = migrateEmailAddress backendUser.emailAddress
    , profileImage = migrateProfileImage backendUser.profileImage
    , timezone = backendUser.timezone
    , allowEventReminders = backendUser.allowEventReminders
    }


migrateId : Evergreen.V33.Id.Id a -> Evergreen.V37.Id.Id b
migrateId (Evergreen.V33.Id.Id id) =
    Evergreen.V37.Id.Id id


migrateUserId : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId -> Evergreen.V37.Id.Id Evergreen.V37.Id.UserId
migrateUserId (Evergreen.V33.Id.Id id) =
    Evergreen.V37.Id.Id id


migrateSessionIdFirst4Chars : Evergreen.V33.Id.SessionIdFirst4Chars -> Evergreen.V37.Id.SessionIdFirst4Chars
migrateSessionIdFirst4Chars (Evergreen.V33.Id.SessionIdFirst4Chars id) =
    Evergreen.V37.Id.SessionIdFirst4Chars id


migrateSessionId : Evergreen.V33.Id.SessionId -> Evergreen.V37.Id.SessionId
migrateSessionId (Evergreen.V33.Id.SessionId id) =
    Evergreen.V37.Id.SessionId id


migrateClientId : Evergreen.V33.Id.ClientId -> Evergreen.V37.Id.ClientId
migrateClientId (Evergreen.V33.Id.ClientId id) =
    Evergreen.V37.Id.ClientId id


migrateGroupName : Evergreen.V33.GroupName.GroupName -> Evergreen.V37.GroupName.GroupName
migrateGroupName (Evergreen.V33.GroupName.GroupName id) =
    Evergreen.V37.GroupName.GroupName id


migrateEventId : Evergreen.V33.Group.EventId -> Evergreen.V37.Group.EventId
migrateEventId (Evergreen.V33.Group.EventId id) =
    Evergreen.V37.Group.EventId id


migrateGroupId : Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId -> Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId
migrateGroupId (Evergreen.V33.Id.Id id) =
    Evergreen.V37.Id.Id id


migrateEventName : Evergreen.V33.EventName.EventName -> Evergreen.V37.EventName.EventName
migrateEventName (Evergreen.V33.EventName.EventName a) =
    Evergreen.V37.EventName.EventName a


migrateLink : Evergreen.V33.Link.Link -> Evergreen.V37.Link.Link
migrateLink (Evergreen.V33.Link.Link a) =
    Evergreen.V37.Link.Link a


migrateAddress : Evergreen.V33.Address.Address -> Evergreen.V37.Address.Address
migrateAddress (Evergreen.V33.Address.Address a) =
    Evergreen.V37.Address.Address a


migrateEventType : Evergreen.V33.Event.EventType -> Evergreen.V37.Event.EventType
migrateEventType a =
    case a of
        Evergreen.V33.Event.MeetOnline maybeLink ->
            Maybe.map migrateLink maybeLink |> Evergreen.V37.Event.MeetOnline

        Evergreen.V33.Event.MeetInPerson maybeAddress ->
            Maybe.map migrateAddress maybeAddress |> Evergreen.V37.Event.MeetInPerson


migrateEventDuration : Evergreen.V33.EventDuration.EventDuration -> Evergreen.V37.EventDuration.EventDuration
migrateEventDuration (Evergreen.V33.EventDuration.EventDuration a) =
    Evergreen.V37.EventDuration.EventDuration a


migrateCancellationStatus : Evergreen.V33.Event.CancellationStatus -> Evergreen.V37.Event.CancellationStatus
migrateCancellationStatus a =
    case a of
        Evergreen.V33.Event.EventCancelled ->
            Evergreen.V37.Event.EventCancelled

        Evergreen.V33.Event.EventUncancelled ->
            Evergreen.V37.Event.EventUncancelled


migrateMaxAttendees : Evergreen.V33.MaxAttendees.MaxAttendees -> Evergreen.V37.MaxAttendees.MaxAttendees
migrateMaxAttendees a =
    case a of
        Evergreen.V33.MaxAttendees.NoLimit ->
            Evergreen.V37.MaxAttendees.NoLimit

        Evergreen.V33.MaxAttendees.MaxAttendees b ->
            Evergreen.V37.MaxAttendees.MaxAttendees b


migrateEvent : Evergreen.V33.Event.Event -> Evergreen.V37.Event.Event
migrateEvent (Evergreen.V33.Event.Event event) =
    Evergreen.V37.Event.Event
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


migrateGroupVisibility : Evergreen.V33.Group.GroupVisibility -> Evergreen.V37.Group.GroupVisibility
migrateGroupVisibility a =
    case a of
        Evergreen.V33.Group.UnlistedGroup ->
            Evergreen.V37.Group.UnlistedGroup

        Evergreen.V33.Group.PublicGroup ->
            Evergreen.V37.Group.PublicGroup


migrateGroup : Evergreen.V33.Group.Group -> Evergreen.V37.Group.Group
migrateGroup (Evergreen.V33.Group.Group group) =
    Evergreen.V37.Group.Group
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


migrateUntrusted : (a -> b) -> Evergreen.V33.Untrusted.Untrusted a -> Evergreen.V37.Untrusted.Untrusted b
migrateUntrusted mapFunc (Evergreen.V33.Untrusted.Untrusted a) =
    Evergreen.V37.Untrusted.Untrusted (mapFunc a)


migrateRoute : Evergreen.V33.Route.Route -> Evergreen.V37.Route.Route
migrateRoute a =
    case a of
        Evergreen.V33.Route.HomepageRoute ->
            Evergreen.V37.Route.HomepageRoute

        Evergreen.V33.Route.GroupRoute groupId groupName ->
            Evergreen.V37.Route.GroupRoute (migrateGroupId groupId) (migrateGroupName groupName)

        Evergreen.V33.Route.AdminRoute ->
            Evergreen.V37.Route.AdminRoute

        Evergreen.V33.Route.CreateGroupRoute ->
            Evergreen.V37.Route.CreateGroupRoute

        Evergreen.V33.Route.SearchGroupsRoute string ->
            Evergreen.V37.Route.SearchGroupsRoute string

        Evergreen.V33.Route.MyGroupsRoute ->
            Evergreen.V37.Route.MyGroupsRoute

        Evergreen.V33.Route.MyProfileRoute ->
            Evergreen.V37.Route.MyProfileRoute

        Evergreen.V33.Route.UserRoute userId name ->
            Evergreen.V37.Route.UserRoute (migrateUserId userId) (migrateName name)

        Evergreen.V33.Route.PrivacyRoute ->
            Evergreen.V37.Route.PrivacyRoute

        Evergreen.V33.Route.TermsOfServiceRoute ->
            Evergreen.V37.Route.TermsOfServiceRoute

        Evergreen.V33.Route.CodeOfConductRoute ->
            Evergreen.V37.Route.CodeOfConductRoute

        Evergreen.V33.Route.FrequentQuestionsRoute ->
            Evergreen.V37.Route.FrequentQuestionsRoute


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


migrateEmailAddress : Evergreen.V33.EmailAddress.EmailAddress -> Evergreen.V37.EmailAddress.EmailAddress
migrateEmailAddress (Evergreen.V33.EmailAddress.EmailAddress { domain, localPart, tags, tld }) =
    Evergreen.V37.EmailAddress.EmailAddress { domain = domain, localPart = localPart, tags = tags, tld = tld }


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
    , deletedGroups =
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
