module Evergreen.Migrate.V27 exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc as BiDict
import Dict
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
import Evergreen.V26.Types as Old
import Evergreen.V26.Untrusted
import Evergreen.V27.Address
import Evergreen.V27.Description
import Evergreen.V27.EmailAddress
import Evergreen.V27.Event
import Evergreen.V27.EventDuration
import Evergreen.V27.EventName
import Evergreen.V27.Group
import Evergreen.V27.GroupName
import Evergreen.V27.Id
import Evergreen.V27.Link
import Evergreen.V27.MaxAttendees
import Evergreen.V27.Name
import Evergreen.V27.ProfileImage
import Evergreen.V27.Route
import Evergreen.V27.Types as New
import Evergreen.V27.Untrusted
import Lamdera.Migrations exposing (..)
import List.Nonempty
import Set


frontendModel : Old.FrontendModel -> ModelMigration New.FrontendModel New.FrontendMsg
frontendModel old =
    ModelUnchanged


migrateName : Evergreen.V26.Name.Name -> Evergreen.V27.Name.Name
migrateName (Evergreen.V26.Name.Name name) =
    Evergreen.V27.Name.Name name


migrateDescription : Evergreen.V26.Description.Description -> Evergreen.V27.Description.Description
migrateDescription (Evergreen.V26.Description.Description name) =
    Evergreen.V27.Description.Description name


migrateProfileImage : Evergreen.V26.ProfileImage.ProfileImage -> Evergreen.V27.ProfileImage.ProfileImage
migrateProfileImage a =
    case a of
        Evergreen.V26.ProfileImage.DefaultImage ->
            Evergreen.V27.ProfileImage.DefaultImage

        Evergreen.V26.ProfileImage.CustomImage b ->
            Evergreen.V27.ProfileImage.CustomImage b


migrateBackendUser : Old.BackendUser -> New.BackendUser
migrateBackendUser backendUser =
    { name = migrateName backendUser.name
    , description = migrateDescription backendUser.description
    , emailAddress = migrateEmailAddress backendUser.emailAddress
    , profileImage = migrateProfileImage backendUser.profileImage
    , timezone = backendUser.timezone
    , allowEventReminders = backendUser.allowEventReminders
    }


migrateId : Evergreen.V26.Id.Id a -> Evergreen.V27.Id.Id b
migrateId (Evergreen.V26.Id.Id id) =
    Evergreen.V27.Id.Id id


migrateUserId : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId -> Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
migrateUserId (Evergreen.V26.Id.Id id) =
    Evergreen.V27.Id.Id id


migrateSessionIdFirst4Chars : Evergreen.V26.Id.SessionIdFirst4Chars -> Evergreen.V27.Id.SessionIdFirst4Chars
migrateSessionIdFirst4Chars (Evergreen.V26.Id.SessionIdFirst4Chars id) =
    Evergreen.V27.Id.SessionIdFirst4Chars id


migrateSessionId : Evergreen.V26.Id.SessionId -> Evergreen.V27.Id.SessionId
migrateSessionId (Evergreen.V26.Id.SessionId id) =
    Evergreen.V27.Id.SessionId id


migrateClientId : Evergreen.V26.Id.ClientId -> Evergreen.V27.Id.ClientId
migrateClientId (Evergreen.V26.Id.ClientId id) =
    Evergreen.V27.Id.ClientId id


migrateGroupName : Evergreen.V26.GroupName.GroupName -> Evergreen.V27.GroupName.GroupName
migrateGroupName (Evergreen.V26.GroupName.GroupName id) =
    Evergreen.V27.GroupName.GroupName id


migrateEventId : Evergreen.V26.Group.EventId -> Evergreen.V27.Group.EventId
migrateEventId (Evergreen.V26.Group.EventId id) =
    Evergreen.V27.Group.EventId id


migrateGroupId : Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId -> Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId
migrateGroupId (Evergreen.V26.Id.Id id) =
    Evergreen.V27.Id.Id id


migrateEventName : Evergreen.V26.EventName.EventName -> Evergreen.V27.EventName.EventName
migrateEventName (Evergreen.V26.EventName.EventName a) =
    Evergreen.V27.EventName.EventName a


migrateLink : Evergreen.V26.Link.Link -> Evergreen.V27.Link.Link
migrateLink (Evergreen.V26.Link.Link a) =
    Evergreen.V27.Link.Link a


migrateAddress : Evergreen.V26.Address.Address -> Evergreen.V27.Address.Address
migrateAddress (Evergreen.V26.Address.Address a) =
    Evergreen.V27.Address.Address a


migrateEventType : Evergreen.V26.Event.EventType -> Evergreen.V27.Event.EventType
migrateEventType a =
    case a of
        Evergreen.V26.Event.MeetOnline maybeLink ->
            Maybe.map migrateLink maybeLink |> Evergreen.V27.Event.MeetOnline

        Evergreen.V26.Event.MeetInPerson maybeAddress ->
            Maybe.map migrateAddress maybeAddress |> Evergreen.V27.Event.MeetInPerson


migrateEventDuration : Evergreen.V26.EventDuration.EventDuration -> Evergreen.V27.EventDuration.EventDuration
migrateEventDuration (Evergreen.V26.EventDuration.EventDuration a) =
    Evergreen.V27.EventDuration.EventDuration a


migrateCancellationStatus : Evergreen.V26.Event.CancellationStatus -> Evergreen.V27.Event.CancellationStatus
migrateCancellationStatus a =
    case a of
        Evergreen.V26.Event.EventCancelled ->
            Evergreen.V27.Event.EventCancelled

        Evergreen.V26.Event.EventUncancelled ->
            Evergreen.V27.Event.EventUncancelled


migrateMaxAttendees : Evergreen.V26.MaxAttendees.MaxAttendees -> Evergreen.V27.MaxAttendees.MaxAttendees
migrateMaxAttendees a =
    case a of
        Evergreen.V26.MaxAttendees.NoLimit ->
            Evergreen.V27.MaxAttendees.NoLimit

        Evergreen.V26.MaxAttendees.MaxAttendees b ->
            Evergreen.V27.MaxAttendees.MaxAttendees b


migrateEvent : Evergreen.V26.Event.Event -> Evergreen.V27.Event.Event
migrateEvent (Evergreen.V26.Event.Event event) =
    Evergreen.V27.Event.Event
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


migrateGroupVisibility : Evergreen.V26.Group.GroupVisibility -> Evergreen.V27.Group.GroupVisibility
migrateGroupVisibility a =
    case a of
        Evergreen.V26.Group.UnlistedGroup ->
            Evergreen.V27.Group.UnlistedGroup

        Evergreen.V26.Group.PublicGroup ->
            Evergreen.V27.Group.PublicGroup


migrateGroup : Evergreen.V26.Group.Group -> Evergreen.V27.Group.Group
migrateGroup (Evergreen.V26.Group.Group group) =
    Evergreen.V27.Group.Group
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


migrateUntrusted : (a -> b) -> Evergreen.V26.Untrusted.Untrusted a -> Evergreen.V27.Untrusted.Untrusted b
migrateUntrusted mapFunc (Evergreen.V26.Untrusted.Untrusted a) =
    Evergreen.V27.Untrusted.Untrusted (mapFunc a)


migrateRoute : Evergreen.V26.Route.Route -> Evergreen.V27.Route.Route
migrateRoute a =
    case a of
        Evergreen.V26.Route.HomepageRoute ->
            Evergreen.V27.Route.HomepageRoute

        Evergreen.V26.Route.GroupRoute groupId groupName ->
            Evergreen.V27.Route.GroupRoute (migrateGroupId groupId) (migrateGroupName groupName)

        Evergreen.V26.Route.AdminRoute ->
            Evergreen.V27.Route.AdminRoute

        Evergreen.V26.Route.CreateGroupRoute ->
            Evergreen.V27.Route.CreateGroupRoute

        Evergreen.V26.Route.SearchGroupsRoute string ->
            Evergreen.V27.Route.SearchGroupsRoute string

        Evergreen.V26.Route.MyGroupsRoute ->
            Evergreen.V27.Route.MyGroupsRoute

        Evergreen.V26.Route.MyProfileRoute ->
            Evergreen.V27.Route.MyProfileRoute

        Evergreen.V26.Route.UserRoute userId name ->
            Evergreen.V27.Route.UserRoute (migrateUserId userId) (migrateName name)


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


migrateEmailAddress : Old.EmailAddress -> Evergreen.V27.EmailAddress.EmailAddress
migrateEmailAddress (Old.EmailAddress { domain, localPart, tags, tld }) =
    Evergreen.V27.EmailAddress.EmailAddress { domain = domain, localPart = localPart, tags = tags, tld = tld }


migrateDeleteUserToken : Old.DeleteUserTokenData -> New.DeleteUserTokenData
migrateDeleteUserToken a =
    { creationTime = a.creationTime
    , userId = migrateUserId a.userId
    }


migrateLoginTokenData : Old.LoginTokenData -> New.LoginTokenData
migrateLoginTokenData { creationTime, emailAddress } =
    New.LoginTokenData creationTime (migrateEmailAddress emailAddress)


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
    , logs = Array.empty
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
