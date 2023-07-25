module Evergreen.Migrate.V68 exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc as BiDict
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
import Evergreen.V63.Types as Old
import Evergreen.V63.Untrusted
import Evergreen.V68.Address
import Evergreen.V68.Description
import Evergreen.V68.EmailAddress
import Evergreen.V68.Event
import Evergreen.V68.EventDuration
import Evergreen.V68.EventName
import Evergreen.V68.Group
import Evergreen.V68.GroupName
import Evergreen.V68.GroupPage
import Evergreen.V68.Id
import Evergreen.V68.Link
import Evergreen.V68.MaxAttendees
import Evergreen.V68.Name
import Evergreen.V68.ProfileImage
import Evergreen.V68.ProfilePage
import Evergreen.V68.Route
import Evergreen.V68.Types as New
import Evergreen.V68.Untrusted
import Lamdera.Migrations exposing (..)
import List.Nonempty


frontendModel : Old.FrontendModel -> ModelMigration New.FrontendModel New.FrontendMsg
frontendModel old =
    ModelUnchanged


migrateName : Evergreen.V63.Name.Name -> Evergreen.V68.Name.Name
migrateName (Evergreen.V63.Name.Name name) =
    Evergreen.V68.Name.Name name


migrateDescription : Evergreen.V63.Description.Description -> Evergreen.V68.Description.Description
migrateDescription (Evergreen.V63.Description.Description name) =
    Evergreen.V68.Description.Description name


migrateProfileImage : Evergreen.V63.ProfileImage.ProfileImage -> Evergreen.V68.ProfileImage.ProfileImage
migrateProfileImage a =
    case a of
        Evergreen.V63.ProfileImage.DefaultImage ->
            Evergreen.V68.ProfileImage.DefaultImage

        Evergreen.V63.ProfileImage.CustomImage b ->
            Evergreen.V68.ProfileImage.CustomImage b


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


migrateId : Evergreen.V63.Id.Id a -> Evergreen.V68.Id.Id b
migrateId (Evergreen.V63.Id.Id id) =
    Evergreen.V68.Id.Id id


migrateUserId : Evergreen.V63.Id.Id Evergreen.V63.Id.UserId -> Evergreen.V68.Id.Id Evergreen.V68.Id.UserId
migrateUserId (Evergreen.V63.Id.Id id) =
    Evergreen.V68.Id.Id id


migrateSessionIdFirst4Chars : Evergreen.V63.Id.SessionIdFirst4Chars -> Evergreen.V68.Id.SessionIdFirst4Chars
migrateSessionIdFirst4Chars (Evergreen.V63.Id.SessionIdFirst4Chars id) =
    Evergreen.V68.Id.SessionIdFirst4Chars id


migrateGroupName : Evergreen.V63.GroupName.GroupName -> Evergreen.V68.GroupName.GroupName
migrateGroupName (Evergreen.V63.GroupName.GroupName id) =
    Evergreen.V68.GroupName.GroupName id


migrateEventId : Evergreen.V63.Group.EventId -> Evergreen.V68.Group.EventId
migrateEventId (Evergreen.V63.Group.EventId id) =
    Evergreen.V68.Group.EventId id


migrateGroupId : Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId -> Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId
migrateGroupId (Evergreen.V63.Id.Id id) =
    Evergreen.V68.Id.Id id


migrateEventName : Evergreen.V63.EventName.EventName -> Evergreen.V68.EventName.EventName
migrateEventName (Evergreen.V63.EventName.EventName a) =
    Evergreen.V68.EventName.EventName a


migrateLink : Evergreen.V63.Link.Link -> Evergreen.V68.Link.Link
migrateLink (Evergreen.V63.Link.Link a) =
    Evergreen.V68.Link.Link a


migrateAddress : Evergreen.V63.Address.Address -> Evergreen.V68.Address.Address
migrateAddress (Evergreen.V63.Address.Address a) =
    Evergreen.V68.Address.Address a


migrateEventType : Evergreen.V63.Event.EventType -> Evergreen.V68.Event.EventType
migrateEventType a =
    case a of
        Evergreen.V63.Event.MeetOnline maybeLink ->
            Maybe.map migrateLink maybeLink |> Evergreen.V68.Event.MeetOnline

        Evergreen.V63.Event.MeetInPerson maybeAddress ->
            Maybe.map migrateAddress maybeAddress |> Evergreen.V68.Event.MeetInPerson

        Evergreen.V63.Event.MeetOnlineAndInPerson maybeLink maybeAddress ->
            Evergreen.V68.Event.MeetOnlineAndInPerson
                (Maybe.map migrateLink maybeLink)
                (Maybe.map migrateAddress maybeAddress)


migrateEventDuration : Evergreen.V63.EventDuration.EventDuration -> Evergreen.V68.EventDuration.EventDuration
migrateEventDuration (Evergreen.V63.EventDuration.EventDuration a) =
    Evergreen.V68.EventDuration.EventDuration a


migrateCancellationStatus : Evergreen.V63.Event.CancellationStatus -> Evergreen.V68.Event.CancellationStatus
migrateCancellationStatus a =
    case a of
        Evergreen.V63.Event.EventCancelled ->
            Evergreen.V68.Event.EventCancelled

        Evergreen.V63.Event.EventUncancelled ->
            Evergreen.V68.Event.EventUncancelled


migrateMaxAttendees : Evergreen.V63.MaxAttendees.MaxAttendees -> Evergreen.V68.MaxAttendees.MaxAttendees
migrateMaxAttendees a =
    case a of
        Evergreen.V63.MaxAttendees.NoLimit ->
            Evergreen.V68.MaxAttendees.NoLimit

        Evergreen.V63.MaxAttendees.MaxAttendees b ->
            Evergreen.V68.MaxAttendees.MaxAttendees b


migrateEvent : Evergreen.V63.Event.Event -> Evergreen.V68.Event.Event
migrateEvent (Evergreen.V63.Event.Event event) =
    Evergreen.V68.Event.Event
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


migrateGroupVisibility : Evergreen.V63.Group.GroupVisibility -> Evergreen.V68.Group.GroupVisibility
migrateGroupVisibility a =
    case a of
        Evergreen.V63.Group.UnlistedGroup ->
            Evergreen.V68.Group.UnlistedGroup

        Evergreen.V63.Group.PublicGroup ->
            Evergreen.V68.Group.PublicGroup


migrateGroup : Evergreen.V63.Group.Group -> Evergreen.V68.Group.Group
migrateGroup (Evergreen.V63.Group.Group group) =
    Evergreen.V68.Group.Group
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


migrateUntrusted : (a -> b) -> Evergreen.V63.Untrusted.Untrusted a -> Evergreen.V68.Untrusted.Untrusted b
migrateUntrusted mapFunc (Evergreen.V63.Untrusted.Untrusted a) =
    Evergreen.V68.Untrusted.Untrusted (mapFunc a)


migrateRoute : Evergreen.V63.Route.Route -> Evergreen.V68.Route.Route
migrateRoute a =
    case a of
        Evergreen.V63.Route.HomepageRoute ->
            Evergreen.V68.Route.HomepageRoute

        Evergreen.V63.Route.GroupRoute groupId groupName ->
            Evergreen.V68.Route.GroupRoute (migrateGroupId groupId) (migrateGroupName groupName)

        Evergreen.V63.Route.AdminRoute ->
            Evergreen.V68.Route.AdminRoute

        Evergreen.V63.Route.CreateGroupRoute ->
            Evergreen.V68.Route.CreateGroupRoute

        Evergreen.V63.Route.SearchGroupsRoute string ->
            Evergreen.V68.Route.SearchGroupsRoute string

        Evergreen.V63.Route.MyGroupsRoute ->
            Evergreen.V68.Route.MyGroupsRoute

        Evergreen.V63.Route.MyProfileRoute ->
            Evergreen.V68.Route.MyProfileRoute

        Evergreen.V63.Route.UserRoute userId name ->
            Evergreen.V68.Route.UserRoute (migrateUserId userId) (migrateName name)

        Evergreen.V63.Route.PrivacyRoute ->
            Evergreen.V68.Route.PrivacyRoute

        Evergreen.V63.Route.TermsOfServiceRoute ->
            Evergreen.V68.Route.TermsOfServiceRoute

        Evergreen.V63.Route.CodeOfConductRoute ->
            Evergreen.V68.Route.CodeOfConductRoute

        Evergreen.V63.Route.FrequentQuestionsRoute ->
            Evergreen.V68.Route.FrequentQuestionsRoute


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


migrateProfileFormToBackend : Evergreen.V63.ProfilePage.ToBackend -> Evergreen.V68.ProfilePage.ToBackend
migrateProfileFormToBackend profileForm =
    case profileForm of
        Evergreen.V63.ProfilePage.ChangeNameRequest a ->
            Evergreen.V68.ProfilePage.ChangeNameRequest (migrateUntrusted migrateName a)

        Evergreen.V63.ProfilePage.ChangeDescriptionRequest a ->
            Evergreen.V68.ProfilePage.ChangeDescriptionRequest (migrateUntrusted migrateDescription a)

        Evergreen.V63.ProfilePage.ChangeEmailAddressRequest a ->
            Evergreen.V68.ProfilePage.ChangeEmailAddressRequest (migrateUntrusted migrateEmailAddress a)

        Evergreen.V63.ProfilePage.SendDeleteUserEmailRequest ->
            Evergreen.V68.ProfilePage.SendDeleteUserEmailRequest

        Evergreen.V63.ProfilePage.ChangeProfileImageRequest a ->
            Evergreen.V68.ProfilePage.ChangeProfileImageRequest (migrateUntrusted migrateProfileImage a)


migrateGroupPageToBackend : Evergreen.V63.GroupPage.ToBackend -> Evergreen.V68.GroupPage.ToBackend
migrateGroupPageToBackend groupPage =
    case groupPage of
        Evergreen.V63.GroupPage.ChangeGroupNameRequest b ->
            Evergreen.V68.GroupPage.ChangeGroupNameRequest (migrateUntrusted migrateGroupName b)

        Evergreen.V63.GroupPage.ChangeGroupDescriptionRequest b ->
            Evergreen.V68.GroupPage.ChangeGroupDescriptionRequest (migrateUntrusted migrateDescription b)

        Evergreen.V63.GroupPage.CreateEventRequest b c d e f g ->
            Evergreen.V68.GroupPage.CreateEventRequest
                (migrateUntrusted migrateEventName b)
                (migrateUntrusted migrateDescription c)
                (migrateUntrusted migrateEventType d)
                e
                (migrateUntrusted migrateEventDuration f)
                (migrateUntrusted migrateMaxAttendees g)

        Evergreen.V63.GroupPage.EditEventRequest b c d e f g h ->
            Evergreen.V68.GroupPage.EditEventRequest
                (migrateEventId b)
                (migrateUntrusted migrateEventName c)
                (migrateUntrusted migrateDescription d)
                (migrateUntrusted migrateEventType e)
                f
                (migrateUntrusted migrateEventDuration g)
                (migrateUntrusted migrateMaxAttendees h)

        Evergreen.V63.GroupPage.JoinEventRequest b ->
            Evergreen.V68.GroupPage.JoinEventRequest (migrateEventId b)

        Evergreen.V63.GroupPage.LeaveEventRequest b ->
            Evergreen.V68.GroupPage.LeaveEventRequest (migrateEventId b)

        Evergreen.V63.GroupPage.ChangeEventCancellationStatusRequest b c ->
            Evergreen.V68.GroupPage.ChangeEventCancellationStatusRequest (migrateEventId b) (migrateCancellationStatus c)

        Evergreen.V63.GroupPage.ChangeGroupVisibilityRequest groupVisibility ->
            Evergreen.V68.GroupPage.ChangeGroupVisibilityRequest (migrateGroupVisibility groupVisibility)

        Evergreen.V63.GroupPage.DeleteGroupAdminRequest ->
            Evergreen.V68.GroupPage.DeleteGroupAdminRequest

        Evergreen.V63.GroupPage.SubscribeRequest ->
            Evergreen.V68.GroupPage.SubscribeRequest

        Evergreen.V63.GroupPage.UnsubscribeRequest ->
            Evergreen.V68.GroupPage.UnsubscribeRequest


migrateEmailAddress : Evergreen.V63.EmailAddress.EmailAddress -> Evergreen.V68.EmailAddress.EmailAddress
migrateEmailAddress (Evergreen.V63.EmailAddress.EmailAddress { domain, localPart, tags, tld }) =
    Evergreen.V68.EmailAddress.EmailAddress { domain = domain, localPart = localPart, tags = tags, tld = tld }


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
