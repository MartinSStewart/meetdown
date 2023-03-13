module Evergreen.Migrate.V63 exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc as BiDict
import Evergreen.V62.Address
import Evergreen.V62.Description
import Evergreen.V62.EmailAddress
import Evergreen.V62.Event
import Evergreen.V62.EventDuration
import Evergreen.V62.EventName
import Evergreen.V62.Group
import Evergreen.V62.GroupName
import Evergreen.V62.GroupPage
import Evergreen.V62.Id
import Evergreen.V62.Link
import Evergreen.V62.MaxAttendees
import Evergreen.V62.Name
import Evergreen.V62.ProfileImage
import Evergreen.V62.ProfilePage
import Evergreen.V62.Route
import Evergreen.V62.Types as Old
import Evergreen.V62.Untrusted
import Evergreen.V63.Address
import Evergreen.V63.Description
import Evergreen.V63.EmailAddress
import Evergreen.V63.Event
import Evergreen.V63.EventDuration
import Evergreen.V63.EventName
import Evergreen.V63.Group
import Evergreen.V63.GroupName
import Evergreen.V63.GroupPage
import Evergreen.V63.Id
import Evergreen.V63.Link
import Evergreen.V63.MaxAttendees
import Evergreen.V63.Name
import Evergreen.V63.ProfileImage
import Evergreen.V63.ProfilePage
import Evergreen.V63.Route
import Evergreen.V63.Types as New
import Evergreen.V63.Untrusted
import Lamdera.Migrations exposing (..)
import List.Nonempty


frontendModel : Old.FrontendModel -> ModelMigration New.FrontendModel New.FrontendMsg
frontendModel old =
    ModelUnchanged


migrateName : Evergreen.V62.Name.Name -> Evergreen.V63.Name.Name
migrateName (Evergreen.V62.Name.Name name) =
    Evergreen.V63.Name.Name name


migrateDescription : Evergreen.V62.Description.Description -> Evergreen.V63.Description.Description
migrateDescription (Evergreen.V62.Description.Description name) =
    Evergreen.V63.Description.Description name


migrateProfileImage : Evergreen.V62.ProfileImage.ProfileImage -> Evergreen.V63.ProfileImage.ProfileImage
migrateProfileImage a =
    case a of
        Evergreen.V62.ProfileImage.DefaultImage ->
            Evergreen.V63.ProfileImage.DefaultImage

        Evergreen.V62.ProfileImage.CustomImage b ->
            Evergreen.V63.ProfileImage.CustomImage b


migrateBackendUser : Old.BackendUser -> New.BackendUser
migrateBackendUser backendUser =
    { name = migrateName backendUser.name
    , description = migrateDescription backendUser.description
    , emailAddress = migrateEmailAddress backendUser.emailAddress
    , profileImage = migrateProfileImage backendUser.profileImage
    , timezone = backendUser.timezone
    , allowEventReminders = backendUser.allowEventReminders
    , subscribedGroups = AssocSet.map migrateId backendUser.subscribedGroups
    }


migrateId : Evergreen.V62.Id.Id a -> Evergreen.V63.Id.Id b
migrateId (Evergreen.V62.Id.Id id) =
    Evergreen.V63.Id.Id id


migrateUserId : Evergreen.V62.Id.Id Evergreen.V62.Id.UserId -> Evergreen.V63.Id.Id Evergreen.V63.Id.UserId
migrateUserId (Evergreen.V62.Id.Id id) =
    Evergreen.V63.Id.Id id


migrateSessionIdFirst4Chars : Evergreen.V62.Id.SessionIdFirst4Chars -> Evergreen.V63.Id.SessionIdFirst4Chars
migrateSessionIdFirst4Chars (Evergreen.V62.Id.SessionIdFirst4Chars id) =
    Evergreen.V63.Id.SessionIdFirst4Chars id


migrateGroupName : Evergreen.V62.GroupName.GroupName -> Evergreen.V63.GroupName.GroupName
migrateGroupName (Evergreen.V62.GroupName.GroupName id) =
    Evergreen.V63.GroupName.GroupName id


migrateEventId : Evergreen.V62.Group.EventId -> Evergreen.V63.Group.EventId
migrateEventId (Evergreen.V62.Group.EventId id) =
    Evergreen.V63.Group.EventId id


migrateGroupId : Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId -> Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId
migrateGroupId (Evergreen.V62.Id.Id id) =
    Evergreen.V63.Id.Id id


migrateEventName : Evergreen.V62.EventName.EventName -> Evergreen.V63.EventName.EventName
migrateEventName (Evergreen.V62.EventName.EventName a) =
    Evergreen.V63.EventName.EventName a


migrateLink : Evergreen.V62.Link.Link -> Evergreen.V63.Link.Link
migrateLink (Evergreen.V62.Link.Link a) =
    Evergreen.V63.Link.Link a


migrateAddress : Evergreen.V62.Address.Address -> Evergreen.V63.Address.Address
migrateAddress (Evergreen.V62.Address.Address a) =
    Evergreen.V63.Address.Address a


migrateEventType : Evergreen.V62.Event.EventType -> Evergreen.V63.Event.EventType
migrateEventType a =
    case a of
        Evergreen.V62.Event.MeetOnline maybeLink ->
            Maybe.map migrateLink maybeLink |> Evergreen.V63.Event.MeetOnline

        Evergreen.V62.Event.MeetInPerson maybeAddress ->
            Maybe.map migrateAddress maybeAddress |> Evergreen.V63.Event.MeetInPerson

        Evergreen.V62.Event.MeetOnlineAndInPerson maybeLink maybeAddress ->
            Evergreen.V63.Event.MeetOnlineAndInPerson
                (Maybe.map migrateLink maybeLink)
                (Maybe.map migrateAddress maybeAddress)


migrateEventDuration : Evergreen.V62.EventDuration.EventDuration -> Evergreen.V63.EventDuration.EventDuration
migrateEventDuration (Evergreen.V62.EventDuration.EventDuration a) =
    Evergreen.V63.EventDuration.EventDuration a


migrateCancellationStatus : Evergreen.V62.Event.CancellationStatus -> Evergreen.V63.Event.CancellationStatus
migrateCancellationStatus a =
    case a of
        Evergreen.V62.Event.EventCancelled ->
            Evergreen.V63.Event.EventCancelled

        Evergreen.V62.Event.EventUncancelled ->
            Evergreen.V63.Event.EventUncancelled


migrateMaxAttendees : Evergreen.V62.MaxAttendees.MaxAttendees -> Evergreen.V63.MaxAttendees.MaxAttendees
migrateMaxAttendees a =
    case a of
        Evergreen.V62.MaxAttendees.NoLimit ->
            Evergreen.V63.MaxAttendees.NoLimit

        Evergreen.V62.MaxAttendees.MaxAttendees b ->
            Evergreen.V63.MaxAttendees.MaxAttendees b


migrateEvent : Evergreen.V62.Event.Event -> Evergreen.V63.Event.Event
migrateEvent (Evergreen.V62.Event.Event event) =
    Evergreen.V63.Event.Event
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


migrateGroupVisibility : Evergreen.V62.Group.GroupVisibility -> Evergreen.V63.Group.GroupVisibility
migrateGroupVisibility a =
    case a of
        Evergreen.V62.Group.UnlistedGroup ->
            Evergreen.V63.Group.UnlistedGroup

        Evergreen.V62.Group.PublicGroup ->
            Evergreen.V63.Group.PublicGroup


migrateGroup : Evergreen.V62.Group.Group -> Evergreen.V63.Group.Group
migrateGroup (Evergreen.V62.Group.Group group) =
    Evergreen.V63.Group.Group
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


migrateUntrusted : (a -> b) -> Evergreen.V62.Untrusted.Untrusted a -> Evergreen.V63.Untrusted.Untrusted b
migrateUntrusted mapFunc (Evergreen.V62.Untrusted.Untrusted a) =
    Evergreen.V63.Untrusted.Untrusted (mapFunc a)


migrateRoute : Evergreen.V62.Route.Route -> Evergreen.V63.Route.Route
migrateRoute a =
    case a of
        Evergreen.V62.Route.HomepageRoute ->
            Evergreen.V63.Route.HomepageRoute

        Evergreen.V62.Route.GroupRoute groupId groupName ->
            Evergreen.V63.Route.GroupRoute (migrateGroupId groupId) (migrateGroupName groupName)

        Evergreen.V62.Route.AdminRoute ->
            Evergreen.V63.Route.AdminRoute

        Evergreen.V62.Route.CreateGroupRoute ->
            Evergreen.V63.Route.CreateGroupRoute

        Evergreen.V62.Route.SearchGroupsRoute string ->
            Evergreen.V63.Route.SearchGroupsRoute string

        Evergreen.V62.Route.MyGroupsRoute ->
            Evergreen.V63.Route.MyGroupsRoute

        Evergreen.V62.Route.MyProfileRoute ->
            Evergreen.V63.Route.MyProfileRoute

        Evergreen.V62.Route.UserRoute userId name ->
            Evergreen.V63.Route.UserRoute (migrateUserId userId) (migrateName name)

        Evergreen.V62.Route.PrivacyRoute ->
            Evergreen.V63.Route.PrivacyRoute

        Evergreen.V62.Route.TermsOfServiceRoute ->
            Evergreen.V63.Route.TermsOfServiceRoute

        Evergreen.V62.Route.CodeOfConductRoute ->
            Evergreen.V63.Route.CodeOfConductRoute

        Evergreen.V62.Route.FrequentQuestionsRoute ->
            Evergreen.V63.Route.FrequentQuestionsRoute


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


migrateProfileFormToBackend : Evergreen.V62.ProfilePage.ToBackend -> Evergreen.V63.ProfilePage.ToBackend
migrateProfileFormToBackend profileForm =
    case profileForm of
        Evergreen.V62.ProfilePage.ChangeNameRequest a ->
            Evergreen.V63.ProfilePage.ChangeNameRequest (migrateUntrusted migrateName a)

        Evergreen.V62.ProfilePage.ChangeDescriptionRequest a ->
            Evergreen.V63.ProfilePage.ChangeDescriptionRequest (migrateUntrusted migrateDescription a)

        Evergreen.V62.ProfilePage.ChangeEmailAddressRequest a ->
            Evergreen.V63.ProfilePage.ChangeEmailAddressRequest (migrateUntrusted migrateEmailAddress a)

        Evergreen.V62.ProfilePage.SendDeleteUserEmailRequest ->
            Evergreen.V63.ProfilePage.SendDeleteUserEmailRequest

        Evergreen.V62.ProfilePage.ChangeProfileImageRequest a ->
            Evergreen.V63.ProfilePage.ChangeProfileImageRequest (migrateUntrusted migrateProfileImage a)


migrateGroupPageToBackend : Evergreen.V62.GroupPage.ToBackend -> Evergreen.V63.GroupPage.ToBackend
migrateGroupPageToBackend groupPage =
    case groupPage of
        Evergreen.V62.GroupPage.ChangeGroupNameRequest b ->
            Evergreen.V63.GroupPage.ChangeGroupNameRequest (migrateUntrusted migrateGroupName b)

        Evergreen.V62.GroupPage.ChangeGroupDescriptionRequest b ->
            Evergreen.V63.GroupPage.ChangeGroupDescriptionRequest (migrateUntrusted migrateDescription b)

        Evergreen.V62.GroupPage.CreateEventRequest b c d e f g ->
            Evergreen.V63.GroupPage.CreateEventRequest
                (migrateUntrusted migrateEventName b)
                (migrateUntrusted migrateDescription c)
                (migrateUntrusted migrateEventType d)
                e
                (migrateUntrusted migrateEventDuration f)
                (migrateUntrusted migrateMaxAttendees g)

        Evergreen.V62.GroupPage.EditEventRequest b c d e f g h ->
            Evergreen.V63.GroupPage.EditEventRequest
                (migrateEventId b)
                (migrateUntrusted migrateEventName c)
                (migrateUntrusted migrateDescription d)
                (migrateUntrusted migrateEventType e)
                f
                (migrateUntrusted migrateEventDuration g)
                (migrateUntrusted migrateMaxAttendees h)

        Evergreen.V62.GroupPage.JoinEventRequest b ->
            Evergreen.V63.GroupPage.JoinEventRequest (migrateEventId b)

        Evergreen.V62.GroupPage.LeaveEventRequest b ->
            Evergreen.V63.GroupPage.LeaveEventRequest (migrateEventId b)

        Evergreen.V62.GroupPage.ChangeEventCancellationStatusRequest b c ->
            Evergreen.V63.GroupPage.ChangeEventCancellationStatusRequest (migrateEventId b) (migrateCancellationStatus c)

        Evergreen.V62.GroupPage.ChangeGroupVisibilityRequest groupVisibility ->
            Evergreen.V63.GroupPage.ChangeGroupVisibilityRequest (migrateGroupVisibility groupVisibility)

        Evergreen.V62.GroupPage.DeleteGroupAdminRequest ->
            Evergreen.V63.GroupPage.DeleteGroupAdminRequest

        Evergreen.V62.GroupPage.SubscribeRequest ->
            Evergreen.V63.GroupPage.SubscribeRequest

        Evergreen.V62.GroupPage.UnsubscribeRequest ->
            Evergreen.V63.GroupPage.UnsubscribeRequest


migrateEmailAddress : Evergreen.V62.EmailAddress.EmailAddress -> Evergreen.V63.EmailAddress.EmailAddress
migrateEmailAddress (Evergreen.V62.EmailAddress.EmailAddress { domain, localPart, tags, tld }) =
    Evergreen.V63.EmailAddress.EmailAddress { domain = domain, localPart = localPart, tags = tags, tld = tld }


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
