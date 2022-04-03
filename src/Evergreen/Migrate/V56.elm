module Evergreen.Migrate.V56 exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc as BiDict
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
import Evergreen.V50.Types as Old
import Evergreen.V50.Untrusted
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
import Evergreen.V56.Types as New
import Evergreen.V56.Untrusted
import Lamdera.Migrations exposing (..)
import List.Nonempty


frontendModel : Old.FrontendModel -> ModelMigration New.FrontendModel New.FrontendMsg
frontendModel old =
    ModelUnchanged


migrateName : Evergreen.V50.Name.Name -> Evergreen.V56.Name.Name
migrateName (Evergreen.V50.Name.Name name) =
    Evergreen.V56.Name.Name name


migrateDescription : Evergreen.V50.Description.Description -> Evergreen.V56.Description.Description
migrateDescription (Evergreen.V50.Description.Description name) =
    Evergreen.V56.Description.Description name


migrateProfileImage : Evergreen.V50.ProfileImage.ProfileImage -> Evergreen.V56.ProfileImage.ProfileImage
migrateProfileImage a =
    case a of
        Evergreen.V50.ProfileImage.DefaultImage ->
            Evergreen.V56.ProfileImage.DefaultImage

        Evergreen.V50.ProfileImage.CustomImage b ->
            Evergreen.V56.ProfileImage.CustomImage b


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


migrateId : Evergreen.V50.Id.Id a -> Evergreen.V56.Id.Id b
migrateId (Evergreen.V50.Id.Id id) =
    Evergreen.V56.Id.Id id


migrateUserId : Evergreen.V50.Id.Id Evergreen.V50.Id.UserId -> Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
migrateUserId (Evergreen.V50.Id.Id id) =
    Evergreen.V56.Id.Id id


migrateSessionIdFirst4Chars : Evergreen.V50.Id.SessionIdFirst4Chars -> Evergreen.V56.Id.SessionIdFirst4Chars
migrateSessionIdFirst4Chars (Evergreen.V50.Id.SessionIdFirst4Chars id) =
    Evergreen.V56.Id.SessionIdFirst4Chars id


migrateGroupName : Evergreen.V50.GroupName.GroupName -> Evergreen.V56.GroupName.GroupName
migrateGroupName (Evergreen.V50.GroupName.GroupName id) =
    Evergreen.V56.GroupName.GroupName id


migrateEventId : Evergreen.V50.Group.EventId -> Evergreen.V56.Group.EventId
migrateEventId (Evergreen.V50.Group.EventId id) =
    Evergreen.V56.Group.EventId id


migrateGroupId : Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId -> Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId
migrateGroupId (Evergreen.V50.Id.Id id) =
    Evergreen.V56.Id.Id id


migrateEventName : Evergreen.V50.EventName.EventName -> Evergreen.V56.EventName.EventName
migrateEventName (Evergreen.V50.EventName.EventName a) =
    Evergreen.V56.EventName.EventName a


migrateLink : Evergreen.V50.Link.Link -> Evergreen.V56.Link.Link
migrateLink (Evergreen.V50.Link.Link a) =
    Evergreen.V56.Link.Link a


migrateAddress : Evergreen.V50.Address.Address -> Evergreen.V56.Address.Address
migrateAddress (Evergreen.V50.Address.Address a) =
    Evergreen.V56.Address.Address a


migrateEventType : Evergreen.V50.Event.EventType -> Evergreen.V56.Event.EventType
migrateEventType a =
    case a of
        Evergreen.V50.Event.MeetOnline maybeLink ->
            Maybe.map migrateLink maybeLink |> Evergreen.V56.Event.MeetOnline

        Evergreen.V50.Event.MeetInPerson maybeAddress ->
            Maybe.map migrateAddress maybeAddress |> Evergreen.V56.Event.MeetInPerson


migrateEventDuration : Evergreen.V50.EventDuration.EventDuration -> Evergreen.V56.EventDuration.EventDuration
migrateEventDuration (Evergreen.V50.EventDuration.EventDuration a) =
    Evergreen.V56.EventDuration.EventDuration a


migrateCancellationStatus : Evergreen.V50.Event.CancellationStatus -> Evergreen.V56.Event.CancellationStatus
migrateCancellationStatus a =
    case a of
        Evergreen.V50.Event.EventCancelled ->
            Evergreen.V56.Event.EventCancelled

        Evergreen.V50.Event.EventUncancelled ->
            Evergreen.V56.Event.EventUncancelled


migrateMaxAttendees : Evergreen.V50.MaxAttendees.MaxAttendees -> Evergreen.V56.MaxAttendees.MaxAttendees
migrateMaxAttendees a =
    case a of
        Evergreen.V50.MaxAttendees.NoLimit ->
            Evergreen.V56.MaxAttendees.NoLimit

        Evergreen.V50.MaxAttendees.MaxAttendees b ->
            Evergreen.V56.MaxAttendees.MaxAttendees b


migrateEvent : Evergreen.V50.Event.Event -> Evergreen.V56.Event.Event
migrateEvent (Evergreen.V50.Event.Event event) =
    Evergreen.V56.Event.Event
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


migrateGroupVisibility : Evergreen.V50.Group.GroupVisibility -> Evergreen.V56.Group.GroupVisibility
migrateGroupVisibility a =
    case a of
        Evergreen.V50.Group.UnlistedGroup ->
            Evergreen.V56.Group.UnlistedGroup

        Evergreen.V50.Group.PublicGroup ->
            Evergreen.V56.Group.PublicGroup


migrateGroup : Evergreen.V50.Group.Group -> Evergreen.V56.Group.Group
migrateGroup (Evergreen.V50.Group.Group group) =
    Evergreen.V56.Group.Group
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


migrateUntrusted : (a -> b) -> Evergreen.V50.Untrusted.Untrusted a -> Evergreen.V56.Untrusted.Untrusted b
migrateUntrusted mapFunc (Evergreen.V50.Untrusted.Untrusted a) =
    Evergreen.V56.Untrusted.Untrusted (mapFunc a)


migrateRoute : Evergreen.V50.Route.Route -> Evergreen.V56.Route.Route
migrateRoute a =
    case a of
        Evergreen.V50.Route.HomepageRoute ->
            Evergreen.V56.Route.HomepageRoute

        Evergreen.V50.Route.GroupRoute groupId groupName ->
            Evergreen.V56.Route.GroupRoute (migrateGroupId groupId) (migrateGroupName groupName)

        Evergreen.V50.Route.AdminRoute ->
            Evergreen.V56.Route.AdminRoute

        Evergreen.V50.Route.CreateGroupRoute ->
            Evergreen.V56.Route.CreateGroupRoute

        Evergreen.V50.Route.SearchGroupsRoute string ->
            Evergreen.V56.Route.SearchGroupsRoute string

        Evergreen.V50.Route.MyGroupsRoute ->
            Evergreen.V56.Route.MyGroupsRoute

        Evergreen.V50.Route.MyProfileRoute ->
            Evergreen.V56.Route.MyProfileRoute

        Evergreen.V50.Route.UserRoute userId name ->
            Evergreen.V56.Route.UserRoute (migrateUserId userId) (migrateName name)

        Evergreen.V50.Route.PrivacyRoute ->
            Evergreen.V56.Route.PrivacyRoute

        Evergreen.V50.Route.TermsOfServiceRoute ->
            Evergreen.V56.Route.TermsOfServiceRoute

        Evergreen.V50.Route.CodeOfConductRoute ->
            Evergreen.V56.Route.CodeOfConductRoute

        Evergreen.V50.Route.FrequentQuestionsRoute ->
            Evergreen.V56.Route.FrequentQuestionsRoute


migrateToBackend : Old.ToBackend -> New.ToBackend
migrateToBackend toBackend_ =
    case toBackend_ of
        Old.GetGroupRequest a ->
            New.GetGroupRequest (migrateGroupId a)

        Old.GetUserRequest a ->
            New.GetUserRequest (List.Nonempty.fromElement (migrateUserId a))

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


migrateProfileFormToBackend : Evergreen.V50.ProfilePage.ToBackend -> Evergreen.V56.ProfilePage.ToBackend
migrateProfileFormToBackend profileForm =
    case profileForm of
        Evergreen.V50.ProfilePage.ChangeNameRequest a ->
            Evergreen.V56.ProfilePage.ChangeNameRequest (migrateUntrusted migrateName a)

        Evergreen.V50.ProfilePage.ChangeDescriptionRequest a ->
            Evergreen.V56.ProfilePage.ChangeDescriptionRequest (migrateUntrusted migrateDescription a)

        Evergreen.V50.ProfilePage.ChangeEmailAddressRequest a ->
            Evergreen.V56.ProfilePage.ChangeEmailAddressRequest (migrateUntrusted migrateEmailAddress a)

        Evergreen.V50.ProfilePage.SendDeleteUserEmailRequest ->
            Evergreen.V56.ProfilePage.SendDeleteUserEmailRequest

        Evergreen.V50.ProfilePage.ChangeProfileImageRequest a ->
            Evergreen.V56.ProfilePage.ChangeProfileImageRequest (migrateUntrusted migrateProfileImage a)


migrateGroupPageToBackend : Evergreen.V50.GroupPage.ToBackend -> Evergreen.V56.GroupPage.ToBackend
migrateGroupPageToBackend groupPage =
    case groupPage of
        Evergreen.V50.GroupPage.ChangeGroupNameRequest b ->
            Evergreen.V56.GroupPage.ChangeGroupNameRequest (migrateUntrusted migrateGroupName b)

        Evergreen.V50.GroupPage.ChangeGroupDescriptionRequest b ->
            Evergreen.V56.GroupPage.ChangeGroupDescriptionRequest (migrateUntrusted migrateDescription b)

        Evergreen.V50.GroupPage.CreateEventRequest b c d e f g ->
            Evergreen.V56.GroupPage.CreateEventRequest
                (migrateUntrusted migrateEventName b)
                (migrateUntrusted migrateDescription c)
                (migrateUntrusted migrateEventType d)
                e
                (migrateUntrusted migrateEventDuration f)
                (migrateUntrusted migrateMaxAttendees g)

        Evergreen.V50.GroupPage.EditEventRequest b c d e f g h ->
            Evergreen.V56.GroupPage.EditEventRequest
                (migrateEventId b)
                (migrateUntrusted migrateEventName c)
                (migrateUntrusted migrateDescription d)
                (migrateUntrusted migrateEventType e)
                f
                (migrateUntrusted migrateEventDuration g)
                (migrateUntrusted migrateMaxAttendees h)

        Evergreen.V50.GroupPage.JoinEventRequest b ->
            Evergreen.V56.GroupPage.JoinEventRequest (migrateEventId b)

        Evergreen.V50.GroupPage.LeaveEventRequest b ->
            Evergreen.V56.GroupPage.LeaveEventRequest (migrateEventId b)

        Evergreen.V50.GroupPage.ChangeEventCancellationStatusRequest b c ->
            Evergreen.V56.GroupPage.ChangeEventCancellationStatusRequest (migrateEventId b) (migrateCancellationStatus c)

        Evergreen.V50.GroupPage.ChangeGroupVisibilityRequest groupVisibility ->
            Evergreen.V56.GroupPage.ChangeGroupVisibilityRequest (migrateGroupVisibility groupVisibility)

        Evergreen.V50.GroupPage.DeleteGroupAdminRequest ->
            Evergreen.V56.GroupPage.DeleteGroupAdminRequest

        Evergreen.V50.GroupPage.SubscribeRequest ->
            Evergreen.V56.GroupPage.SubscribeRequest

        Evergreen.V50.GroupPage.UnsubscribeRequest ->
            Evergreen.V56.GroupPage.UnsubscribeRequest


migrateEmailAddress : Evergreen.V50.EmailAddress.EmailAddress -> Evergreen.V56.EmailAddress.EmailAddress
migrateEmailAddress (Evergreen.V50.EmailAddress.EmailAddress { domain, localPart, tags, tld }) =
    Evergreen.V56.EmailAddress.EmailAddress { domain = domain, localPart = localPart, tags = tags, tld = tld }


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
