module Evergreen.Migrate.V62 exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc as BiDict
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
import Evergreen.V61.Types as Old
import Evergreen.V61.Untrusted
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
import Evergreen.V62.Types as New
import Evergreen.V62.Untrusted
import Lamdera.Migrations exposing (..)
import List.Nonempty


frontendModel : Old.FrontendModel -> ModelMigration New.FrontendModel New.FrontendMsg
frontendModel old =
    ModelUnchanged


migrateName : Evergreen.V61.Name.Name -> Evergreen.V62.Name.Name
migrateName (Evergreen.V61.Name.Name name) =
    Evergreen.V62.Name.Name name


migrateDescription : Evergreen.V61.Description.Description -> Evergreen.V62.Description.Description
migrateDescription (Evergreen.V61.Description.Description name) =
    Evergreen.V62.Description.Description name


migrateProfileImage : Evergreen.V61.ProfileImage.ProfileImage -> Evergreen.V62.ProfileImage.ProfileImage
migrateProfileImage a =
    case a of
        Evergreen.V61.ProfileImage.DefaultImage ->
            Evergreen.V62.ProfileImage.DefaultImage

        Evergreen.V61.ProfileImage.CustomImage b ->
            Evergreen.V62.ProfileImage.CustomImage b


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


migrateId : Evergreen.V61.Id.Id a -> Evergreen.V62.Id.Id b
migrateId (Evergreen.V61.Id.Id id) =
    Evergreen.V62.Id.Id id


migrateUserId : Evergreen.V61.Id.Id Evergreen.V61.Id.UserId -> Evergreen.V62.Id.Id Evergreen.V62.Id.UserId
migrateUserId (Evergreen.V61.Id.Id id) =
    Evergreen.V62.Id.Id id


migrateSessionIdFirst4Chars : Evergreen.V61.Id.SessionIdFirst4Chars -> Evergreen.V62.Id.SessionIdFirst4Chars
migrateSessionIdFirst4Chars (Evergreen.V61.Id.SessionIdFirst4Chars id) =
    Evergreen.V62.Id.SessionIdFirst4Chars id


migrateGroupName : Evergreen.V61.GroupName.GroupName -> Evergreen.V62.GroupName.GroupName
migrateGroupName (Evergreen.V61.GroupName.GroupName id) =
    Evergreen.V62.GroupName.GroupName id


migrateEventId : Evergreen.V61.Group.EventId -> Evergreen.V62.Group.EventId
migrateEventId (Evergreen.V61.Group.EventId id) =
    Evergreen.V62.Group.EventId id


migrateGroupId : Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId -> Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId
migrateGroupId (Evergreen.V61.Id.Id id) =
    Evergreen.V62.Id.Id id


migrateEventName : Evergreen.V61.EventName.EventName -> Evergreen.V62.EventName.EventName
migrateEventName (Evergreen.V61.EventName.EventName a) =
    Evergreen.V62.EventName.EventName a


migrateLink : Evergreen.V61.Link.Link -> Evergreen.V62.Link.Link
migrateLink (Evergreen.V61.Link.Link a) =
    Evergreen.V62.Link.Link a


migrateAddress : Evergreen.V61.Address.Address -> Evergreen.V62.Address.Address
migrateAddress (Evergreen.V61.Address.Address a) =
    Evergreen.V62.Address.Address a


migrateEventType : Evergreen.V61.Event.EventType -> Evergreen.V62.Event.EventType
migrateEventType a =
    case a of
        Evergreen.V61.Event.MeetOnline maybeLink ->
            Maybe.map migrateLink maybeLink |> Evergreen.V62.Event.MeetOnline

        Evergreen.V61.Event.MeetInPerson maybeAddress ->
            Maybe.map migrateAddress maybeAddress |> Evergreen.V62.Event.MeetInPerson

        Evergreen.V61.Event.MeetOnlineAndInPerson maybeLink maybeAddress ->
            Evergreen.V62.Event.MeetOnlineAndInPerson
                (Maybe.map migrateLink maybeLink)
                (Maybe.map migrateAddress maybeAddress)


migrateEventDuration : Evergreen.V61.EventDuration.EventDuration -> Evergreen.V62.EventDuration.EventDuration
migrateEventDuration (Evergreen.V61.EventDuration.EventDuration a) =
    Evergreen.V62.EventDuration.EventDuration a


migrateCancellationStatus : Evergreen.V61.Event.CancellationStatus -> Evergreen.V62.Event.CancellationStatus
migrateCancellationStatus a =
    case a of
        Evergreen.V61.Event.EventCancelled ->
            Evergreen.V62.Event.EventCancelled

        Evergreen.V61.Event.EventUncancelled ->
            Evergreen.V62.Event.EventUncancelled


migrateMaxAttendees : Evergreen.V61.MaxAttendees.MaxAttendees -> Evergreen.V62.MaxAttendees.MaxAttendees
migrateMaxAttendees a =
    case a of
        Evergreen.V61.MaxAttendees.NoLimit ->
            Evergreen.V62.MaxAttendees.NoLimit

        Evergreen.V61.MaxAttendees.MaxAttendees b ->
            Evergreen.V62.MaxAttendees.MaxAttendees b


migrateEvent : Evergreen.V61.Event.Event -> Evergreen.V62.Event.Event
migrateEvent (Evergreen.V61.Event.Event event) =
    Evergreen.V62.Event.Event
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


migrateGroupVisibility : Evergreen.V61.Group.GroupVisibility -> Evergreen.V62.Group.GroupVisibility
migrateGroupVisibility a =
    case a of
        Evergreen.V61.Group.UnlistedGroup ->
            Evergreen.V62.Group.UnlistedGroup

        Evergreen.V61.Group.PublicGroup ->
            Evergreen.V62.Group.PublicGroup


migrateGroup : Evergreen.V61.Group.Group -> Evergreen.V62.Group.Group
migrateGroup (Evergreen.V61.Group.Group group) =
    Evergreen.V62.Group.Group
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


migrateUntrusted : (a -> b) -> Evergreen.V61.Untrusted.Untrusted a -> Evergreen.V62.Untrusted.Untrusted b
migrateUntrusted mapFunc (Evergreen.V61.Untrusted.Untrusted a) =
    Evergreen.V62.Untrusted.Untrusted (mapFunc a)


migrateRoute : Evergreen.V61.Route.Route -> Evergreen.V62.Route.Route
migrateRoute a =
    case a of
        Evergreen.V61.Route.HomepageRoute ->
            Evergreen.V62.Route.HomepageRoute

        Evergreen.V61.Route.GroupRoute groupId groupName ->
            Evergreen.V62.Route.GroupRoute (migrateGroupId groupId) (migrateGroupName groupName)

        Evergreen.V61.Route.AdminRoute ->
            Evergreen.V62.Route.AdminRoute

        Evergreen.V61.Route.CreateGroupRoute ->
            Evergreen.V62.Route.CreateGroupRoute

        Evergreen.V61.Route.SearchGroupsRoute string ->
            Evergreen.V62.Route.SearchGroupsRoute string

        Evergreen.V61.Route.MyGroupsRoute ->
            Evergreen.V62.Route.MyGroupsRoute

        Evergreen.V61.Route.MyProfileRoute ->
            Evergreen.V62.Route.MyProfileRoute

        Evergreen.V61.Route.UserRoute userId name ->
            Evergreen.V62.Route.UserRoute (migrateUserId userId) (migrateName name)

        Evergreen.V61.Route.PrivacyRoute ->
            Evergreen.V62.Route.PrivacyRoute

        Evergreen.V61.Route.TermsOfServiceRoute ->
            Evergreen.V62.Route.TermsOfServiceRoute

        Evergreen.V61.Route.CodeOfConductRoute ->
            Evergreen.V62.Route.CodeOfConductRoute

        Evergreen.V61.Route.FrequentQuestionsRoute ->
            Evergreen.V62.Route.FrequentQuestionsRoute


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


migrateProfileFormToBackend : Evergreen.V61.ProfilePage.ToBackend -> Evergreen.V62.ProfilePage.ToBackend
migrateProfileFormToBackend profileForm =
    case profileForm of
        Evergreen.V61.ProfilePage.ChangeNameRequest a ->
            Evergreen.V62.ProfilePage.ChangeNameRequest (migrateUntrusted migrateName a)

        Evergreen.V61.ProfilePage.ChangeDescriptionRequest a ->
            Evergreen.V62.ProfilePage.ChangeDescriptionRequest (migrateUntrusted migrateDescription a)

        Evergreen.V61.ProfilePage.ChangeEmailAddressRequest a ->
            Evergreen.V62.ProfilePage.ChangeEmailAddressRequest (migrateUntrusted migrateEmailAddress a)

        Evergreen.V61.ProfilePage.SendDeleteUserEmailRequest ->
            Evergreen.V62.ProfilePage.SendDeleteUserEmailRequest

        Evergreen.V61.ProfilePage.ChangeProfileImageRequest a ->
            Evergreen.V62.ProfilePage.ChangeProfileImageRequest (migrateUntrusted migrateProfileImage a)


migrateGroupPageToBackend : Evergreen.V61.GroupPage.ToBackend -> Evergreen.V62.GroupPage.ToBackend
migrateGroupPageToBackend groupPage =
    case groupPage of
        Evergreen.V61.GroupPage.ChangeGroupNameRequest b ->
            Evergreen.V62.GroupPage.ChangeGroupNameRequest (migrateUntrusted migrateGroupName b)

        Evergreen.V61.GroupPage.ChangeGroupDescriptionRequest b ->
            Evergreen.V62.GroupPage.ChangeGroupDescriptionRequest (migrateUntrusted migrateDescription b)

        Evergreen.V61.GroupPage.CreateEventRequest b c d e f g ->
            Evergreen.V62.GroupPage.CreateEventRequest
                (migrateUntrusted migrateEventName b)
                (migrateUntrusted migrateDescription c)
                (migrateUntrusted migrateEventType d)
                e
                (migrateUntrusted migrateEventDuration f)
                (migrateUntrusted migrateMaxAttendees g)

        Evergreen.V61.GroupPage.EditEventRequest b c d e f g h ->
            Evergreen.V62.GroupPage.EditEventRequest
                (migrateEventId b)
                (migrateUntrusted migrateEventName c)
                (migrateUntrusted migrateDescription d)
                (migrateUntrusted migrateEventType e)
                f
                (migrateUntrusted migrateEventDuration g)
                (migrateUntrusted migrateMaxAttendees h)

        Evergreen.V61.GroupPage.JoinEventRequest b ->
            Evergreen.V62.GroupPage.JoinEventRequest (migrateEventId b)

        Evergreen.V61.GroupPage.LeaveEventRequest b ->
            Evergreen.V62.GroupPage.LeaveEventRequest (migrateEventId b)

        Evergreen.V61.GroupPage.ChangeEventCancellationStatusRequest b c ->
            Evergreen.V62.GroupPage.ChangeEventCancellationStatusRequest (migrateEventId b) (migrateCancellationStatus c)

        Evergreen.V61.GroupPage.ChangeGroupVisibilityRequest groupVisibility ->
            Evergreen.V62.GroupPage.ChangeGroupVisibilityRequest (migrateGroupVisibility groupVisibility)

        Evergreen.V61.GroupPage.DeleteGroupAdminRequest ->
            Evergreen.V62.GroupPage.DeleteGroupAdminRequest

        Evergreen.V61.GroupPage.SubscribeRequest ->
            Evergreen.V62.GroupPage.SubscribeRequest

        Evergreen.V61.GroupPage.UnsubscribeRequest ->
            Evergreen.V62.GroupPage.UnsubscribeRequest


migrateEmailAddress : Evergreen.V61.EmailAddress.EmailAddress -> Evergreen.V62.EmailAddress.EmailAddress
migrateEmailAddress (Evergreen.V61.EmailAddress.EmailAddress { domain, localPart, tags, tld }) =
    Evergreen.V62.EmailAddress.EmailAddress { domain = domain, localPart = localPart, tags = tags, tld = tld }


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
