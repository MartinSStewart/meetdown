module Evergreen.Migrate.V50 exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc as BiDict
import Evergreen.V49.Address
import Evergreen.V49.Description
import Evergreen.V49.EmailAddress
import Evergreen.V49.Event
import Evergreen.V49.EventDuration
import Evergreen.V49.EventName
import Evergreen.V49.Group
import Evergreen.V49.GroupName
import Evergreen.V49.GroupPage
import Evergreen.V49.Id
import Evergreen.V49.Link
import Evergreen.V49.MaxAttendees
import Evergreen.V49.Name
import Evergreen.V49.ProfileImage
import Evergreen.V49.ProfilePage
import Evergreen.V49.Route
import Evergreen.V49.Types as Old
import Evergreen.V49.Untrusted
import Evergreen.V50.Address
import Evergreen.V50.Description
import Evergreen.V50.EmailAddress
import Evergreen.V50.Event
import Evergreen.V50.EventDuration
import Evergreen.V50.EventName
import Evergreen.V50.Group
import Evergreen.V50.GroupName
import Evergreen.V50.GroupPage
import Evergreen.V50.Id
import Evergreen.V50.Link
import Evergreen.V50.MaxAttendees
import Evergreen.V50.Name
import Evergreen.V50.ProfileImage
import Evergreen.V50.ProfilePage
import Evergreen.V50.Route
import Evergreen.V50.Types as New
import Evergreen.V50.Untrusted
import Lamdera.Migrations exposing (..)


frontendModel : Old.FrontendModel -> ModelMigration New.FrontendModel New.FrontendMsg
frontendModel old =
    ModelUnchanged


migrateName : Evergreen.V49.Name.Name -> Evergreen.V50.Name.Name
migrateName (Evergreen.V49.Name.Name name) =
    Evergreen.V50.Name.Name name


migrateDescription : Evergreen.V49.Description.Description -> Evergreen.V50.Description.Description
migrateDescription (Evergreen.V49.Description.Description name) =
    Evergreen.V50.Description.Description name


migrateProfileImage : Evergreen.V49.ProfileImage.ProfileImage -> Evergreen.V50.ProfileImage.ProfileImage
migrateProfileImage a =
    case a of
        Evergreen.V49.ProfileImage.DefaultImage ->
            Evergreen.V50.ProfileImage.DefaultImage

        Evergreen.V49.ProfileImage.CustomImage b ->
            Evergreen.V50.ProfileImage.CustomImage b


migrateBackendUser : Old.BackendUser -> New.BackendUser
migrateBackendUser backendUser =
    { name = migrateName backendUser.name
    , description = migrateDescription backendUser.description
    , emailAddress = migrateEmailAddress backendUser.emailAddress
    , profileImage = migrateProfileImage backendUser.profileImage
    , timezone = backendUser.timezone
    , allowEventReminders = backendUser.allowEventReminders
    , subscribedGroups = AssocSet.empty
    }


migrateId : Evergreen.V49.Id.Id a -> Evergreen.V50.Id.Id b
migrateId (Evergreen.V49.Id.Id id) =
    Evergreen.V50.Id.Id id


migrateUserId : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId -> Evergreen.V50.Id.Id Evergreen.V50.Id.UserId
migrateUserId (Evergreen.V49.Id.Id id) =
    Evergreen.V50.Id.Id id


migrateSessionIdFirst4Chars : Evergreen.V49.Id.SessionIdFirst4Chars -> Evergreen.V50.Id.SessionIdFirst4Chars
migrateSessionIdFirst4Chars (Evergreen.V49.Id.SessionIdFirst4Chars id) =
    Evergreen.V50.Id.SessionIdFirst4Chars id


migrateGroupName : Evergreen.V49.GroupName.GroupName -> Evergreen.V50.GroupName.GroupName
migrateGroupName (Evergreen.V49.GroupName.GroupName id) =
    Evergreen.V50.GroupName.GroupName id


migrateEventId : Evergreen.V49.Group.EventId -> Evergreen.V50.Group.EventId
migrateEventId (Evergreen.V49.Group.EventId id) =
    Evergreen.V50.Group.EventId id


migrateGroupId : Evergreen.V49.Id.Id Evergreen.V49.Id.GroupId -> Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId
migrateGroupId (Evergreen.V49.Id.Id id) =
    Evergreen.V50.Id.Id id


migrateEventName : Evergreen.V49.EventName.EventName -> Evergreen.V50.EventName.EventName
migrateEventName (Evergreen.V49.EventName.EventName a) =
    Evergreen.V50.EventName.EventName a


migrateLink : Evergreen.V49.Link.Link -> Evergreen.V50.Link.Link
migrateLink (Evergreen.V49.Link.Link a) =
    Evergreen.V50.Link.Link a


migrateAddress : Evergreen.V49.Address.Address -> Evergreen.V50.Address.Address
migrateAddress (Evergreen.V49.Address.Address a) =
    Evergreen.V50.Address.Address a


migrateEventType : Evergreen.V49.Event.EventType -> Evergreen.V50.Event.EventType
migrateEventType a =
    case a of
        Evergreen.V49.Event.MeetOnline maybeLink ->
            Maybe.map migrateLink maybeLink |> Evergreen.V50.Event.MeetOnline

        Evergreen.V49.Event.MeetInPerson maybeAddress ->
            Maybe.map migrateAddress maybeAddress |> Evergreen.V50.Event.MeetInPerson


migrateEventDuration : Evergreen.V49.EventDuration.EventDuration -> Evergreen.V50.EventDuration.EventDuration
migrateEventDuration (Evergreen.V49.EventDuration.EventDuration a) =
    Evergreen.V50.EventDuration.EventDuration a


migrateCancellationStatus : Evergreen.V49.Event.CancellationStatus -> Evergreen.V50.Event.CancellationStatus
migrateCancellationStatus a =
    case a of
        Evergreen.V49.Event.EventCancelled ->
            Evergreen.V50.Event.EventCancelled

        Evergreen.V49.Event.EventUncancelled ->
            Evergreen.V50.Event.EventUncancelled


migrateMaxAttendees : Evergreen.V49.MaxAttendees.MaxAttendees -> Evergreen.V50.MaxAttendees.MaxAttendees
migrateMaxAttendees a =
    case a of
        Evergreen.V49.MaxAttendees.NoLimit ->
            Evergreen.V50.MaxAttendees.NoLimit

        Evergreen.V49.MaxAttendees.MaxAttendees b ->
            Evergreen.V50.MaxAttendees.MaxAttendees b


migrateEvent : Evergreen.V49.Event.Event -> Evergreen.V50.Event.Event
migrateEvent (Evergreen.V49.Event.Event event) =
    Evergreen.V50.Event.Event
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


migrateGroupVisibility : Evergreen.V49.Group.GroupVisibility -> Evergreen.V50.Group.GroupVisibility
migrateGroupVisibility a =
    case a of
        Evergreen.V49.Group.UnlistedGroup ->
            Evergreen.V50.Group.UnlistedGroup

        Evergreen.V49.Group.PublicGroup ->
            Evergreen.V50.Group.PublicGroup


migrateGroup : Evergreen.V49.Group.Group -> Evergreen.V50.Group.Group
migrateGroup (Evergreen.V49.Group.Group group) =
    Evergreen.V50.Group.Group
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


migrateUntrusted : (a -> b) -> Evergreen.V49.Untrusted.Untrusted a -> Evergreen.V50.Untrusted.Untrusted b
migrateUntrusted mapFunc (Evergreen.V49.Untrusted.Untrusted a) =
    Evergreen.V50.Untrusted.Untrusted (mapFunc a)


migrateRoute : Evergreen.V49.Route.Route -> Evergreen.V50.Route.Route
migrateRoute a =
    case a of
        Evergreen.V49.Route.HomepageRoute ->
            Evergreen.V50.Route.HomepageRoute

        Evergreen.V49.Route.GroupRoute groupId groupName ->
            Evergreen.V50.Route.GroupRoute (migrateGroupId groupId) (migrateGroupName groupName)

        Evergreen.V49.Route.AdminRoute ->
            Evergreen.V50.Route.AdminRoute

        Evergreen.V49.Route.CreateGroupRoute ->
            Evergreen.V50.Route.CreateGroupRoute

        Evergreen.V49.Route.SearchGroupsRoute string ->
            Evergreen.V50.Route.SearchGroupsRoute string

        Evergreen.V49.Route.MyGroupsRoute ->
            Evergreen.V50.Route.MyGroupsRoute

        Evergreen.V49.Route.MyProfileRoute ->
            Evergreen.V50.Route.MyProfileRoute

        Evergreen.V49.Route.UserRoute userId name ->
            Evergreen.V50.Route.UserRoute (migrateUserId userId) (migrateName name)

        Evergreen.V49.Route.PrivacyRoute ->
            Evergreen.V50.Route.PrivacyRoute

        Evergreen.V49.Route.TermsOfServiceRoute ->
            Evergreen.V50.Route.TermsOfServiceRoute

        Evergreen.V49.Route.CodeOfConductRoute ->
            Evergreen.V50.Route.CodeOfConductRoute

        Evergreen.V49.Route.FrequentQuestionsRoute ->
            Evergreen.V50.Route.FrequentQuestionsRoute


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

        Old.DeleteUserRequest a ->
            New.DeleteUserRequest (migrateId a)

        Old.GetMyGroupsRequest ->
            New.GetMyGroupsRequest

        Old.SearchGroupsRequest a ->
            New.SearchGroupsRequest a

        Old.GroupRequest id b ->
            New.GroupRequest (migrateId id) (migrateGroupPageToBackend b)

        Old.ProfileFormRequest b ->
            New.ProfileFormRequest (migrateProfileFormToBackend b)


migrateProfileFormToBackend : Evergreen.V49.ProfilePage.ToBackend -> Evergreen.V50.ProfilePage.ToBackend
migrateProfileFormToBackend profileForm =
    case profileForm of
        Evergreen.V49.ProfilePage.ChangeNameRequest a ->
            Evergreen.V50.ProfilePage.ChangeNameRequest (migrateUntrusted migrateName a)

        Evergreen.V49.ProfilePage.ChangeDescriptionRequest a ->
            Evergreen.V50.ProfilePage.ChangeDescriptionRequest (migrateUntrusted migrateDescription a)

        Evergreen.V49.ProfilePage.ChangeEmailAddressRequest a ->
            Evergreen.V50.ProfilePage.ChangeEmailAddressRequest (migrateUntrusted migrateEmailAddress a)

        Evergreen.V49.ProfilePage.SendDeleteUserEmailRequest ->
            Evergreen.V50.ProfilePage.SendDeleteUserEmailRequest

        Evergreen.V49.ProfilePage.ChangeProfileImageRequest a ->
            Evergreen.V50.ProfilePage.ChangeProfileImageRequest (migrateUntrusted migrateProfileImage a)


migrateGroupPageToBackend : Evergreen.V49.GroupPage.ToBackend -> Evergreen.V50.GroupPage.ToBackend
migrateGroupPageToBackend groupPage =
    case groupPage of
        Evergreen.V49.GroupPage.ChangeGroupNameRequest b ->
            Evergreen.V50.GroupPage.ChangeGroupNameRequest (migrateUntrusted migrateGroupName b)

        Evergreen.V49.GroupPage.ChangeGroupDescriptionRequest b ->
            Evergreen.V50.GroupPage.ChangeGroupDescriptionRequest (migrateUntrusted migrateDescription b)

        Evergreen.V49.GroupPage.CreateEventRequest b c d e f g ->
            Evergreen.V50.GroupPage.CreateEventRequest
                (migrateUntrusted migrateEventName b)
                (migrateUntrusted migrateDescription c)
                (migrateUntrusted migrateEventType d)
                e
                (migrateUntrusted migrateEventDuration f)
                (migrateUntrusted migrateMaxAttendees g)

        Evergreen.V49.GroupPage.EditEventRequest b c d e f g h ->
            Evergreen.V50.GroupPage.EditEventRequest
                (migrateEventId b)
                (migrateUntrusted migrateEventName c)
                (migrateUntrusted migrateDescription d)
                (migrateUntrusted migrateEventType e)
                f
                (migrateUntrusted migrateEventDuration g)
                (migrateUntrusted migrateMaxAttendees h)

        Evergreen.V49.GroupPage.JoinEventRequest b ->
            Evergreen.V50.GroupPage.JoinEventRequest (migrateEventId b)

        Evergreen.V49.GroupPage.LeaveEventRequest b ->
            Evergreen.V50.GroupPage.LeaveEventRequest (migrateEventId b)

        Evergreen.V49.GroupPage.ChangeEventCancellationStatusRequest b c ->
            Evergreen.V50.GroupPage.ChangeEventCancellationStatusRequest (migrateEventId b) (migrateCancellationStatus c)

        Evergreen.V49.GroupPage.ChangeGroupVisibilityRequest groupVisibility ->
            Evergreen.V50.GroupPage.ChangeGroupVisibilityRequest (migrateGroupVisibility groupVisibility)

        Evergreen.V49.GroupPage.DeleteGroupAdminRequest ->
            Evergreen.V50.GroupPage.DeleteGroupAdminRequest


migrateEmailAddress : Evergreen.V49.EmailAddress.EmailAddress -> Evergreen.V50.EmailAddress.EmailAddress
migrateEmailAddress (Evergreen.V49.EmailAddress.EmailAddress { domain, localPart, tags, tld }) =
    Evergreen.V50.EmailAddress.EmailAddress { domain = domain, localPart = localPart, tags = tags, tld = tld }


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
            New.LogLoginEmail posix (Result.mapError identity result) (migrateEmailAddress emailAddress)

        Old.LogDeleteAccountEmail posix result id ->
            New.LogDeleteAccountEmail posix (Result.mapError identity result) (migrateId id)

        Old.LogEventReminderEmail posix result id groupId eventId ->
            New.LogEventReminderEmail posix (Result.mapError identity result) (migrateId id) (migrateGroupId groupId) (migrateEventId eventId)

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
            |> List.map (Tuple.mapSecond migrateUserId)
            |> BiDict.fromList
    , loginAttempts = old.loginAttempts
    , connections = old.connections
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
    MsgUnchanged


toFrontend : Old.ToFrontend -> MsgMigration New.ToFrontend New.FrontendMsg
toFrontend old =
    MsgUnchanged
