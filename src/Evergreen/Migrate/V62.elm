module Evergreen.Migrate.V61 exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc as BiDict
import Evergreen.V56.Address
import Evergreen.V56.Description
import Evergreen.V56.EmailAddress
import Evergreen.V56.Event
import Evergreen.V56.EventDuration
import Evergreen.V56.EventName
import Evergreen.V56.Group
import Evergreen.V56.GroupName
import Evergreen.V56.GroupPage
import Evergreen.V56.Id
import Evergreen.V56.Link
import Evergreen.V56.MaxAttendees
import Evergreen.V56.Name
import Evergreen.V56.ProfileImage
import Evergreen.V56.ProfilePage
import Evergreen.V56.Route
import Evergreen.V56.Types as Old
import Evergreen.V56.Untrusted
import Evergreen.V61.Address
import Evergreen.V61.Description
import Evergreen.V61.EmailAddress
import Evergreen.V61.Event
import Evergreen.V61.EventDuration
import Evergreen.V61.EventName
import Evergreen.V61.Group
import Evergreen.V61.GroupName
import Evergreen.V61.GroupPage
import Evergreen.V61.Id
import Evergreen.V61.Link
import Evergreen.V61.MaxAttendees
import Evergreen.V61.Name
import Evergreen.V61.ProfileImage
import Evergreen.V61.ProfilePage
import Evergreen.V61.Route
import Evergreen.V61.Types as New
import Evergreen.V61.Untrusted
import Lamdera.Migrations exposing (..)
import List.Nonempty


frontendModel : Old.FrontendModel -> ModelMigration New.FrontendModel New.FrontendMsg
frontendModel old =
    ModelUnchanged


migrateName : Evergreen.V56.Name.Name -> Evergreen.V61.Name.Name
migrateName (Evergreen.V56.Name.Name name) =
    Evergreen.V61.Name.Name name


migrateDescription : Evergreen.V56.Description.Description -> Evergreen.V61.Description.Description
migrateDescription (Evergreen.V56.Description.Description name) =
    Evergreen.V61.Description.Description name


migrateProfileImage : Evergreen.V56.ProfileImage.ProfileImage -> Evergreen.V61.ProfileImage.ProfileImage
migrateProfileImage a =
    case a of
        Evergreen.V56.ProfileImage.DefaultImage ->
            Evergreen.V61.ProfileImage.DefaultImage

        Evergreen.V56.ProfileImage.CustomImage b ->
            Evergreen.V61.ProfileImage.CustomImage b


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


migrateId : Evergreen.V56.Id.Id a -> Evergreen.V61.Id.Id b
migrateId (Evergreen.V56.Id.Id id) =
    Evergreen.V61.Id.Id id


migrateUserId : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId -> Evergreen.V61.Id.Id Evergreen.V61.Id.UserId
migrateUserId (Evergreen.V56.Id.Id id) =
    Evergreen.V61.Id.Id id


migrateSessionIdFirst4Chars : Evergreen.V56.Id.SessionIdFirst4Chars -> Evergreen.V61.Id.SessionIdFirst4Chars
migrateSessionIdFirst4Chars (Evergreen.V56.Id.SessionIdFirst4Chars id) =
    Evergreen.V61.Id.SessionIdFirst4Chars id


migrateGroupName : Evergreen.V56.GroupName.GroupName -> Evergreen.V61.GroupName.GroupName
migrateGroupName (Evergreen.V56.GroupName.GroupName id) =
    Evergreen.V61.GroupName.GroupName id


migrateEventId : Evergreen.V56.Group.EventId -> Evergreen.V61.Group.EventId
migrateEventId (Evergreen.V56.Group.EventId id) =
    Evergreen.V61.Group.EventId id


migrateGroupId : Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId -> Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId
migrateGroupId (Evergreen.V56.Id.Id id) =
    Evergreen.V61.Id.Id id


migrateEventName : Evergreen.V56.EventName.EventName -> Evergreen.V61.EventName.EventName
migrateEventName (Evergreen.V56.EventName.EventName a) =
    Evergreen.V61.EventName.EventName a


migrateLink : Evergreen.V56.Link.Link -> Evergreen.V61.Link.Link
migrateLink (Evergreen.V56.Link.Link a) =
    Evergreen.V61.Link.Link a


migrateAddress : Evergreen.V56.Address.Address -> Evergreen.V61.Address.Address
migrateAddress (Evergreen.V56.Address.Address a) =
    Evergreen.V61.Address.Address a


migrateEventType : Evergreen.V56.Event.EventType -> Evergreen.V61.Event.EventType
migrateEventType a =
    case a of
        Evergreen.V56.Event.MeetOnline maybeLink ->
            Maybe.map migrateLink maybeLink |> Evergreen.V61.Event.MeetOnline

        Evergreen.V56.Event.MeetInPerson maybeAddress ->
            Maybe.map migrateAddress maybeAddress |> Evergreen.V61.Event.MeetInPerson


migrateEventDuration : Evergreen.V56.EventDuration.EventDuration -> Evergreen.V61.EventDuration.EventDuration
migrateEventDuration (Evergreen.V56.EventDuration.EventDuration a) =
    Evergreen.V61.EventDuration.EventDuration a


migrateCancellationStatus : Evergreen.V56.Event.CancellationStatus -> Evergreen.V61.Event.CancellationStatus
migrateCancellationStatus a =
    case a of
        Evergreen.V56.Event.EventCancelled ->
            Evergreen.V61.Event.EventCancelled

        Evergreen.V56.Event.EventUncancelled ->
            Evergreen.V61.Event.EventUncancelled


migrateMaxAttendees : Evergreen.V56.MaxAttendees.MaxAttendees -> Evergreen.V61.MaxAttendees.MaxAttendees
migrateMaxAttendees a =
    case a of
        Evergreen.V56.MaxAttendees.NoLimit ->
            Evergreen.V61.MaxAttendees.NoLimit

        Evergreen.V56.MaxAttendees.MaxAttendees b ->
            Evergreen.V61.MaxAttendees.MaxAttendees b


migrateEvent : Evergreen.V56.Event.Event -> Evergreen.V61.Event.Event
migrateEvent (Evergreen.V56.Event.Event event) =
    Evergreen.V61.Event.Event
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


migrateGroupVisibility : Evergreen.V56.Group.GroupVisibility -> Evergreen.V61.Group.GroupVisibility
migrateGroupVisibility a =
    case a of
        Evergreen.V56.Group.UnlistedGroup ->
            Evergreen.V61.Group.UnlistedGroup

        Evergreen.V56.Group.PublicGroup ->
            Evergreen.V61.Group.PublicGroup


migrateGroup : Evergreen.V56.Group.Group -> Evergreen.V61.Group.Group
migrateGroup (Evergreen.V56.Group.Group group) =
    Evergreen.V61.Group.Group
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


migrateUntrusted : (a -> b) -> Evergreen.V56.Untrusted.Untrusted a -> Evergreen.V61.Untrusted.Untrusted b
migrateUntrusted mapFunc (Evergreen.V56.Untrusted.Untrusted a) =
    Evergreen.V61.Untrusted.Untrusted (mapFunc a)


migrateRoute : Evergreen.V56.Route.Route -> Evergreen.V61.Route.Route
migrateRoute a =
    case a of
        Evergreen.V56.Route.HomepageRoute ->
            Evergreen.V61.Route.HomepageRoute

        Evergreen.V56.Route.GroupRoute groupId groupName ->
            Evergreen.V61.Route.GroupRoute (migrateGroupId groupId) (migrateGroupName groupName)

        Evergreen.V56.Route.AdminRoute ->
            Evergreen.V61.Route.AdminRoute

        Evergreen.V56.Route.CreateGroupRoute ->
            Evergreen.V61.Route.CreateGroupRoute

        Evergreen.V56.Route.SearchGroupsRoute string ->
            Evergreen.V61.Route.SearchGroupsRoute string

        Evergreen.V56.Route.MyGroupsRoute ->
            Evergreen.V61.Route.MyGroupsRoute

        Evergreen.V56.Route.MyProfileRoute ->
            Evergreen.V61.Route.MyProfileRoute

        Evergreen.V56.Route.UserRoute userId name ->
            Evergreen.V61.Route.UserRoute (migrateUserId userId) (migrateName name)

        Evergreen.V56.Route.PrivacyRoute ->
            Evergreen.V61.Route.PrivacyRoute

        Evergreen.V56.Route.TermsOfServiceRoute ->
            Evergreen.V61.Route.TermsOfServiceRoute

        Evergreen.V56.Route.CodeOfConductRoute ->
            Evergreen.V61.Route.CodeOfConductRoute

        Evergreen.V56.Route.FrequentQuestionsRoute ->
            Evergreen.V61.Route.FrequentQuestionsRoute


migrateToBackend : Old.ToBackend -> New.ToBackend
migrateToBackend toBackend_ =
    case toBackend_ of
        Old.GetGroupRequest a ->
            New.GetGroupRequest (migrateGroupId a)

        Old.GetUserRequest a ->
            New.GetUserRequest (List.Nonempty.map migrateUserId a)

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


migrateProfileFormToBackend : Evergreen.V56.ProfilePage.ToBackend -> Evergreen.V61.ProfilePage.ToBackend
migrateProfileFormToBackend profileForm =
    case profileForm of
        Evergreen.V56.ProfilePage.ChangeNameRequest a ->
            Evergreen.V61.ProfilePage.ChangeNameRequest (migrateUntrusted migrateName a)

        Evergreen.V56.ProfilePage.ChangeDescriptionRequest a ->
            Evergreen.V61.ProfilePage.ChangeDescriptionRequest (migrateUntrusted migrateDescription a)

        Evergreen.V56.ProfilePage.ChangeEmailAddressRequest a ->
            Evergreen.V61.ProfilePage.ChangeEmailAddressRequest (migrateUntrusted migrateEmailAddress a)

        Evergreen.V56.ProfilePage.SendDeleteUserEmailRequest ->
            Evergreen.V61.ProfilePage.SendDeleteUserEmailRequest

        Evergreen.V56.ProfilePage.ChangeProfileImageRequest a ->
            Evergreen.V61.ProfilePage.ChangeProfileImageRequest (migrateUntrusted migrateProfileImage a)


migrateGroupPageToBackend : Evergreen.V56.GroupPage.ToBackend -> Evergreen.V61.GroupPage.ToBackend
migrateGroupPageToBackend groupPage =
    case groupPage of
        Evergreen.V56.GroupPage.ChangeGroupNameRequest b ->
            Evergreen.V61.GroupPage.ChangeGroupNameRequest (migrateUntrusted migrateGroupName b)

        Evergreen.V56.GroupPage.ChangeGroupDescriptionRequest b ->
            Evergreen.V61.GroupPage.ChangeGroupDescriptionRequest (migrateUntrusted migrateDescription b)

        Evergreen.V56.GroupPage.CreateEventRequest b c d e f g ->
            Evergreen.V61.GroupPage.CreateEventRequest
                (migrateUntrusted migrateEventName b)
                (migrateUntrusted migrateDescription c)
                (migrateUntrusted migrateEventType d)
                e
                (migrateUntrusted migrateEventDuration f)
                (migrateUntrusted migrateMaxAttendees g)

        Evergreen.V56.GroupPage.EditEventRequest b c d e f g h ->
            Evergreen.V61.GroupPage.EditEventRequest
                (migrateEventId b)
                (migrateUntrusted migrateEventName c)
                (migrateUntrusted migrateDescription d)
                (migrateUntrusted migrateEventType e)
                f
                (migrateUntrusted migrateEventDuration g)
                (migrateUntrusted migrateMaxAttendees h)

        Evergreen.V56.GroupPage.JoinEventRequest b ->
            Evergreen.V61.GroupPage.JoinEventRequest (migrateEventId b)

        Evergreen.V56.GroupPage.LeaveEventRequest b ->
            Evergreen.V61.GroupPage.LeaveEventRequest (migrateEventId b)

        Evergreen.V56.GroupPage.ChangeEventCancellationStatusRequest b c ->
            Evergreen.V61.GroupPage.ChangeEventCancellationStatusRequest (migrateEventId b) (migrateCancellationStatus c)

        Evergreen.V56.GroupPage.ChangeGroupVisibilityRequest groupVisibility ->
            Evergreen.V61.GroupPage.ChangeGroupVisibilityRequest (migrateGroupVisibility groupVisibility)

        Evergreen.V56.GroupPage.DeleteGroupAdminRequest ->
            Evergreen.V61.GroupPage.DeleteGroupAdminRequest

        Evergreen.V56.GroupPage.SubscribeRequest ->
            Evergreen.V61.GroupPage.SubscribeRequest

        Evergreen.V56.GroupPage.UnsubscribeRequest ->
            Evergreen.V61.GroupPage.UnsubscribeRequest


migrateEmailAddress : Evergreen.V56.EmailAddress.EmailAddress -> Evergreen.V61.EmailAddress.EmailAddress
migrateEmailAddress (Evergreen.V56.EmailAddress.EmailAddress { domain, localPart, tags, tld }) =
    Evergreen.V61.EmailAddress.EmailAddress { domain = domain, localPart = localPart, tags = tags, tld = tld }


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

        Old.LogNewEventNotificationEmail a b c d ->
            New.LogNewEventNotificationEmail a b (migrateId c) (migrateId d)


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
