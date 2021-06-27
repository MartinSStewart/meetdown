module Evergreen.Migrate.V29 exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc as BiDict
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
import Evergreen.V27.Types as Old
import Evergreen.V27.Untrusted
import Evergreen.V29.Address
import Evergreen.V29.Description
import Evergreen.V29.EmailAddress
import Evergreen.V29.Event
import Evergreen.V29.EventDuration
import Evergreen.V29.EventName
import Evergreen.V29.Group
import Evergreen.V29.GroupName
import Evergreen.V29.Id
import Evergreen.V29.Link
import Evergreen.V29.MaxAttendees
import Evergreen.V29.Name
import Evergreen.V29.ProfileImage
import Evergreen.V29.Route
import Evergreen.V29.Types as New
import Evergreen.V29.Untrusted
import Lamdera.Migrations exposing (..)
import List.Nonempty


frontendModel : Old.FrontendModel -> ModelMigration New.FrontendModel New.FrontendMsg
frontendModel old =
    ModelUnchanged


migrateName : Evergreen.V27.Name.Name -> Evergreen.V29.Name.Name
migrateName (Evergreen.V27.Name.Name name) =
    Evergreen.V29.Name.Name name


migrateDescription : Evergreen.V27.Description.Description -> Evergreen.V29.Description.Description
migrateDescription (Evergreen.V27.Description.Description name) =
    Evergreen.V29.Description.Description name


migrateProfileImage : Evergreen.V27.ProfileImage.ProfileImage -> Evergreen.V29.ProfileImage.ProfileImage
migrateProfileImage a =
    case a of
        Evergreen.V27.ProfileImage.DefaultImage ->
            Evergreen.V29.ProfileImage.DefaultImage

        Evergreen.V27.ProfileImage.CustomImage b ->
            Evergreen.V29.ProfileImage.CustomImage b


migrateBackendUser : Old.BackendUser -> New.BackendUser
migrateBackendUser backendUser =
    { name = migrateName backendUser.name
    , description = migrateDescription backendUser.description
    , emailAddress = migrateEmailAddress backendUser.emailAddress
    , profileImage = migrateProfileImage backendUser.profileImage
    , timezone = backendUser.timezone
    , allowEventReminders = backendUser.allowEventReminders
    }


migrateId : Evergreen.V27.Id.Id a -> Evergreen.V29.Id.Id b
migrateId (Evergreen.V27.Id.Id id) =
    Evergreen.V29.Id.Id id


migrateUserId : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId -> Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
migrateUserId (Evergreen.V27.Id.Id id) =
    Evergreen.V29.Id.Id id


migrateSessionIdFirst4Chars : Evergreen.V27.Id.SessionIdFirst4Chars -> Evergreen.V29.Id.SessionIdFirst4Chars
migrateSessionIdFirst4Chars (Evergreen.V27.Id.SessionIdFirst4Chars id) =
    Evergreen.V29.Id.SessionIdFirst4Chars id


migrateSessionId : Evergreen.V27.Id.SessionId -> Evergreen.V29.Id.SessionId
migrateSessionId (Evergreen.V27.Id.SessionId id) =
    Evergreen.V29.Id.SessionId id


migrateClientId : Evergreen.V27.Id.ClientId -> Evergreen.V29.Id.ClientId
migrateClientId (Evergreen.V27.Id.ClientId id) =
    Evergreen.V29.Id.ClientId id


migrateGroupName : Evergreen.V27.GroupName.GroupName -> Evergreen.V29.GroupName.GroupName
migrateGroupName (Evergreen.V27.GroupName.GroupName id) =
    Evergreen.V29.GroupName.GroupName id


migrateEventId : Evergreen.V27.Group.EventId -> Evergreen.V29.Group.EventId
migrateEventId (Evergreen.V27.Group.EventId id) =
    Evergreen.V29.Group.EventId id


migrateGroupId : Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId -> Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId
migrateGroupId (Evergreen.V27.Id.Id id) =
    Evergreen.V29.Id.Id id


migrateEventName : Evergreen.V27.EventName.EventName -> Evergreen.V29.EventName.EventName
migrateEventName (Evergreen.V27.EventName.EventName a) =
    Evergreen.V29.EventName.EventName a


migrateLink : Evergreen.V27.Link.Link -> Evergreen.V29.Link.Link
migrateLink (Evergreen.V27.Link.Link a) =
    Evergreen.V29.Link.Link a


migrateAddress : Evergreen.V27.Address.Address -> Evergreen.V29.Address.Address
migrateAddress (Evergreen.V27.Address.Address a) =
    Evergreen.V29.Address.Address a


migrateEventType : Evergreen.V27.Event.EventType -> Evergreen.V29.Event.EventType
migrateEventType a =
    case a of
        Evergreen.V27.Event.MeetOnline maybeLink ->
            Maybe.map migrateLink maybeLink |> Evergreen.V29.Event.MeetOnline

        Evergreen.V27.Event.MeetInPerson maybeAddress ->
            Maybe.map migrateAddress maybeAddress |> Evergreen.V29.Event.MeetInPerson


migrateEventDuration : Evergreen.V27.EventDuration.EventDuration -> Evergreen.V29.EventDuration.EventDuration
migrateEventDuration (Evergreen.V27.EventDuration.EventDuration a) =
    Evergreen.V29.EventDuration.EventDuration a


migrateCancellationStatus : Evergreen.V27.Event.CancellationStatus -> Evergreen.V29.Event.CancellationStatus
migrateCancellationStatus a =
    case a of
        Evergreen.V27.Event.EventCancelled ->
            Evergreen.V29.Event.EventCancelled

        Evergreen.V27.Event.EventUncancelled ->
            Evergreen.V29.Event.EventUncancelled


migrateMaxAttendees : Evergreen.V27.MaxAttendees.MaxAttendees -> Evergreen.V29.MaxAttendees.MaxAttendees
migrateMaxAttendees a =
    case a of
        Evergreen.V27.MaxAttendees.NoLimit ->
            Evergreen.V29.MaxAttendees.NoLimit

        Evergreen.V27.MaxAttendees.MaxAttendees b ->
            Evergreen.V29.MaxAttendees.MaxAttendees b


migrateEvent : Evergreen.V27.Event.Event -> Evergreen.V29.Event.Event
migrateEvent (Evergreen.V27.Event.Event event) =
    Evergreen.V29.Event.Event
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


migrateGroupVisibility : Evergreen.V27.Group.GroupVisibility -> Evergreen.V29.Group.GroupVisibility
migrateGroupVisibility a =
    case a of
        Evergreen.V27.Group.UnlistedGroup ->
            Evergreen.V29.Group.UnlistedGroup

        Evergreen.V27.Group.PublicGroup ->
            Evergreen.V29.Group.PublicGroup


migrateGroup : Evergreen.V27.Group.Group -> Evergreen.V29.Group.Group
migrateGroup (Evergreen.V27.Group.Group group) =
    Evergreen.V29.Group.Group
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


migrateUntrusted : (a -> b) -> Evergreen.V27.Untrusted.Untrusted a -> Evergreen.V29.Untrusted.Untrusted b
migrateUntrusted mapFunc (Evergreen.V27.Untrusted.Untrusted a) =
    Evergreen.V29.Untrusted.Untrusted (mapFunc a)


migrateRoute : Evergreen.V27.Route.Route -> Evergreen.V29.Route.Route
migrateRoute a =
    case a of
        Evergreen.V27.Route.HomepageRoute ->
            Evergreen.V29.Route.HomepageRoute

        Evergreen.V27.Route.GroupRoute groupId groupName ->
            Evergreen.V29.Route.GroupRoute (migrateGroupId groupId) (migrateGroupName groupName)

        Evergreen.V27.Route.AdminRoute ->
            Evergreen.V29.Route.AdminRoute

        Evergreen.V27.Route.CreateGroupRoute ->
            Evergreen.V29.Route.CreateGroupRoute

        Evergreen.V27.Route.SearchGroupsRoute string ->
            Evergreen.V29.Route.SearchGroupsRoute string

        Evergreen.V27.Route.MyGroupsRoute ->
            Evergreen.V29.Route.MyGroupsRoute

        Evergreen.V27.Route.MyProfileRoute ->
            Evergreen.V29.Route.MyProfileRoute

        Evergreen.V27.Route.UserRoute userId name ->
            Evergreen.V29.Route.UserRoute (migrateUserId userId) (migrateName name)


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


migrateEmailAddress : Evergreen.V27.EmailAddress.EmailAddress -> Evergreen.V29.EmailAddress.EmailAddress
migrateEmailAddress (Evergreen.V27.EmailAddress.EmailAddress { domain, localPart, tags, tld }) =
    Evergreen.V29.EmailAddress.EmailAddress { domain = domain, localPart = localPart, tags = tags, tld = tld }


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
