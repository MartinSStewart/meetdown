module Evergreen.Migrate.V49 exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc as BiDict
import Effect.Http
import Effect.Lamdera
import Evergreen.V48.Address
import Evergreen.V48.Description
import Evergreen.V48.Effect.Http
import Evergreen.V48.Effect.Lamdera
import Evergreen.V48.EmailAddress
import Evergreen.V48.Event
import Evergreen.V48.EventDuration
import Evergreen.V48.EventName
import Evergreen.V48.Group
import Evergreen.V48.GroupName
import Evergreen.V48.GroupPage
import Evergreen.V48.Id
import Evergreen.V48.Link
import Evergreen.V48.MaxAttendees
import Evergreen.V48.Name
import Evergreen.V48.ProfileImage
import Evergreen.V48.ProfilePage
import Evergreen.V48.Route
import Evergreen.V48.Types as Old
import Evergreen.V48.Untrusted
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
import Evergreen.V49.Types as New
import Evergreen.V49.Untrusted
import Http
import Lamdera.Migrations exposing (..)
import List.Nonempty


frontendModel : Old.FrontendModel -> ModelMigration New.FrontendModel New.FrontendMsg
frontendModel old =
    ModelUnchanged


migrateName : Evergreen.V48.Name.Name -> Evergreen.V49.Name.Name
migrateName (Evergreen.V48.Name.Name name) =
    Evergreen.V49.Name.Name name


migrateDescription : Evergreen.V48.Description.Description -> Evergreen.V49.Description.Description
migrateDescription (Evergreen.V48.Description.Description name) =
    Evergreen.V49.Description.Description name


migrateProfileImage : Evergreen.V48.ProfileImage.ProfileImage -> Evergreen.V49.ProfileImage.ProfileImage
migrateProfileImage a =
    case a of
        Evergreen.V48.ProfileImage.DefaultImage ->
            Evergreen.V49.ProfileImage.DefaultImage

        Evergreen.V48.ProfileImage.CustomImage b ->
            Evergreen.V49.ProfileImage.CustomImage b


migrateBackendUser : Old.BackendUser -> New.BackendUser
migrateBackendUser backendUser =
    { name = migrateName backendUser.name
    , description = migrateDescription backendUser.description
    , emailAddress = migrateEmailAddress backendUser.emailAddress
    , profileImage = migrateProfileImage backendUser.profileImage
    , timezone = backendUser.timezone
    , allowEventReminders = backendUser.allowEventReminders
    }


migrateId : Evergreen.V48.Id.Id a -> Evergreen.V49.Id.Id b
migrateId (Evergreen.V48.Id.Id id) =
    Evergreen.V49.Id.Id id


migrateUserId : Evergreen.V48.Id.Id Evergreen.V48.Id.UserId -> Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
migrateUserId (Evergreen.V48.Id.Id id) =
    Evergreen.V49.Id.Id id


migrateSessionIdFirst4Chars : Evergreen.V48.Id.SessionIdFirst4Chars -> Evergreen.V49.Id.SessionIdFirst4Chars
migrateSessionIdFirst4Chars (Evergreen.V48.Id.SessionIdFirst4Chars id) =
    Evergreen.V49.Id.SessionIdFirst4Chars id


migrateGroupName : Evergreen.V48.GroupName.GroupName -> Evergreen.V49.GroupName.GroupName
migrateGroupName (Evergreen.V48.GroupName.GroupName id) =
    Evergreen.V49.GroupName.GroupName id


migrateEventId : Evergreen.V48.Group.EventId -> Evergreen.V49.Group.EventId
migrateEventId (Evergreen.V48.Group.EventId id) =
    Evergreen.V49.Group.EventId id


migrateGroupId : Evergreen.V48.Id.Id Evergreen.V48.Id.GroupId -> Evergreen.V49.Id.Id Evergreen.V49.Id.GroupId
migrateGroupId (Evergreen.V48.Id.Id id) =
    Evergreen.V49.Id.Id id


migrateEventName : Evergreen.V48.EventName.EventName -> Evergreen.V49.EventName.EventName
migrateEventName (Evergreen.V48.EventName.EventName a) =
    Evergreen.V49.EventName.EventName a


migrateLink : Evergreen.V48.Link.Link -> Evergreen.V49.Link.Link
migrateLink (Evergreen.V48.Link.Link a) =
    Evergreen.V49.Link.Link a


migrateAddress : Evergreen.V48.Address.Address -> Evergreen.V49.Address.Address
migrateAddress (Evergreen.V48.Address.Address a) =
    Evergreen.V49.Address.Address a


migrateEventType : Evergreen.V48.Event.EventType -> Evergreen.V49.Event.EventType
migrateEventType a =
    case a of
        Evergreen.V48.Event.MeetOnline maybeLink ->
            Maybe.map migrateLink maybeLink |> Evergreen.V49.Event.MeetOnline

        Evergreen.V48.Event.MeetInPerson maybeAddress ->
            Maybe.map migrateAddress maybeAddress |> Evergreen.V49.Event.MeetInPerson


migrateEventDuration : Evergreen.V48.EventDuration.EventDuration -> Evergreen.V49.EventDuration.EventDuration
migrateEventDuration (Evergreen.V48.EventDuration.EventDuration a) =
    Evergreen.V49.EventDuration.EventDuration a


migrateCancellationStatus : Evergreen.V48.Event.CancellationStatus -> Evergreen.V49.Event.CancellationStatus
migrateCancellationStatus a =
    case a of
        Evergreen.V48.Event.EventCancelled ->
            Evergreen.V49.Event.EventCancelled

        Evergreen.V48.Event.EventUncancelled ->
            Evergreen.V49.Event.EventUncancelled


migrateMaxAttendees : Evergreen.V48.MaxAttendees.MaxAttendees -> Evergreen.V49.MaxAttendees.MaxAttendees
migrateMaxAttendees a =
    case a of
        Evergreen.V48.MaxAttendees.NoLimit ->
            Evergreen.V49.MaxAttendees.NoLimit

        Evergreen.V48.MaxAttendees.MaxAttendees b ->
            Evergreen.V49.MaxAttendees.MaxAttendees b


migrateEvent : Evergreen.V48.Event.Event -> Evergreen.V49.Event.Event
migrateEvent (Evergreen.V48.Event.Event event) =
    Evergreen.V49.Event.Event
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


migrateGroupVisibility : Evergreen.V48.Group.GroupVisibility -> Evergreen.V49.Group.GroupVisibility
migrateGroupVisibility a =
    case a of
        Evergreen.V48.Group.UnlistedGroup ->
            Evergreen.V49.Group.UnlistedGroup

        Evergreen.V48.Group.PublicGroup ->
            Evergreen.V49.Group.PublicGroup


migrateGroup : Evergreen.V48.Group.Group -> Evergreen.V49.Group.Group
migrateGroup (Evergreen.V48.Group.Group group) =
    Evergreen.V49.Group.Group
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


migrateUntrusted : (a -> b) -> Evergreen.V48.Untrusted.Untrusted a -> Evergreen.V49.Untrusted.Untrusted b
migrateUntrusted mapFunc (Evergreen.V48.Untrusted.Untrusted a) =
    Evergreen.V49.Untrusted.Untrusted (mapFunc a)


migrateRoute : Evergreen.V48.Route.Route -> Evergreen.V49.Route.Route
migrateRoute a =
    case a of
        Evergreen.V48.Route.HomepageRoute ->
            Evergreen.V49.Route.HomepageRoute

        Evergreen.V48.Route.GroupRoute groupId groupName ->
            Evergreen.V49.Route.GroupRoute (migrateGroupId groupId) (migrateGroupName groupName)

        Evergreen.V48.Route.AdminRoute ->
            Evergreen.V49.Route.AdminRoute

        Evergreen.V48.Route.CreateGroupRoute ->
            Evergreen.V49.Route.CreateGroupRoute

        Evergreen.V48.Route.SearchGroupsRoute string ->
            Evergreen.V49.Route.SearchGroupsRoute string

        Evergreen.V48.Route.MyGroupsRoute ->
            Evergreen.V49.Route.MyGroupsRoute

        Evergreen.V48.Route.MyProfileRoute ->
            Evergreen.V49.Route.MyProfileRoute

        Evergreen.V48.Route.UserRoute userId name ->
            Evergreen.V49.Route.UserRoute (migrateUserId userId) (migrateName name)

        Evergreen.V48.Route.PrivacyRoute ->
            Evergreen.V49.Route.PrivacyRoute

        Evergreen.V48.Route.TermsOfServiceRoute ->
            Evergreen.V49.Route.TermsOfServiceRoute

        Evergreen.V48.Route.CodeOfConductRoute ->
            Evergreen.V49.Route.CodeOfConductRoute

        Evergreen.V48.Route.FrequentQuestionsRoute ->
            Evergreen.V49.Route.FrequentQuestionsRoute


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


migrateProfileFormToBackend : Evergreen.V48.ProfilePage.ToBackend -> Evergreen.V49.ProfilePage.ToBackend
migrateProfileFormToBackend profileForm =
    case profileForm of
        Evergreen.V48.ProfilePage.ChangeNameRequest a ->
            Evergreen.V49.ProfilePage.ChangeNameRequest (migrateUntrusted migrateName a)

        Evergreen.V48.ProfilePage.ChangeDescriptionRequest a ->
            Evergreen.V49.ProfilePage.ChangeDescriptionRequest (migrateUntrusted migrateDescription a)

        Evergreen.V48.ProfilePage.ChangeEmailAddressRequest a ->
            Evergreen.V49.ProfilePage.ChangeEmailAddressRequest (migrateUntrusted migrateEmailAddress a)

        Evergreen.V48.ProfilePage.SendDeleteUserEmailRequest ->
            Evergreen.V49.ProfilePage.SendDeleteUserEmailRequest

        Evergreen.V48.ProfilePage.ChangeProfileImageRequest a ->
            Evergreen.V49.ProfilePage.ChangeProfileImageRequest (migrateUntrusted migrateProfileImage a)


migrateGroupPageToBackend : Evergreen.V48.GroupPage.ToBackend -> Evergreen.V49.GroupPage.ToBackend
migrateGroupPageToBackend groupPage =
    case groupPage of
        Evergreen.V48.GroupPage.ChangeGroupNameRequest b ->
            Evergreen.V49.GroupPage.ChangeGroupNameRequest (migrateUntrusted migrateGroupName b)

        Evergreen.V48.GroupPage.ChangeGroupDescriptionRequest b ->
            Evergreen.V49.GroupPage.ChangeGroupDescriptionRequest (migrateUntrusted migrateDescription b)

        Evergreen.V48.GroupPage.CreateEventRequest b c d e f g ->
            Evergreen.V49.GroupPage.CreateEventRequest
                (migrateUntrusted migrateEventName b)
                (migrateUntrusted migrateDescription c)
                (migrateUntrusted migrateEventType d)
                e
                (migrateUntrusted migrateEventDuration f)
                (migrateUntrusted migrateMaxAttendees g)

        Evergreen.V48.GroupPage.EditEventRequest b c d e f g h ->
            Evergreen.V49.GroupPage.EditEventRequest
                (migrateEventId b)
                (migrateUntrusted migrateEventName c)
                (migrateUntrusted migrateDescription d)
                (migrateUntrusted migrateEventType e)
                f
                (migrateUntrusted migrateEventDuration g)
                (migrateUntrusted migrateMaxAttendees h)

        Evergreen.V48.GroupPage.JoinEventRequest b ->
            Evergreen.V49.GroupPage.JoinEventRequest (migrateEventId b)

        Evergreen.V48.GroupPage.LeaveEventRequest b ->
            Evergreen.V49.GroupPage.LeaveEventRequest (migrateEventId b)

        Evergreen.V48.GroupPage.ChangeEventCancellationStatusRequest b c ->
            Evergreen.V49.GroupPage.ChangeEventCancellationStatusRequest (migrateEventId b) (migrateCancellationStatus c)

        Evergreen.V48.GroupPage.ChangeGroupVisibilityRequest groupVisibility ->
            Evergreen.V49.GroupPage.ChangeGroupVisibilityRequest (migrateGroupVisibility groupVisibility)

        Evergreen.V48.GroupPage.DeleteGroupAdminRequest ->
            Evergreen.V49.GroupPage.DeleteGroupAdminRequest


migrateEmailAddress : Evergreen.V48.EmailAddress.EmailAddress -> Evergreen.V49.EmailAddress.EmailAddress
migrateEmailAddress (Evergreen.V48.EmailAddress.EmailAddress { domain, localPart, tags, tld }) =
    Evergreen.V49.EmailAddress.EmailAddress { domain = domain, localPart = localPart, tags = tags, tld = tld }


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
            New.LogLoginEmail posix (Result.mapError migrateHttpError result) (migrateEmailAddress emailAddress)

        Old.LogDeleteAccountEmail posix result id ->
            New.LogDeleteAccountEmail posix (Result.mapError migrateHttpError result) (migrateId id)

        Old.LogEventReminderEmail posix result id groupId eventId ->
            New.LogEventReminderEmail posix (Result.mapError migrateHttpError result) (migrateId id) (migrateGroupId groupId) (migrateEventId eventId)

        Old.LogLoginTokenEmailRequestRateLimited a b c ->
            New.LogLoginTokenEmailRequestRateLimited a (migrateEmailAddress b) (migrateSessionIdFirst4Chars c)

        Old.LogDeleteAccountEmailRequestRateLimited a b c ->
            New.LogDeleteAccountEmailRequestRateLimited a (migrateId b) (migrateSessionIdFirst4Chars c)


migrateHttpError : Evergreen.V48.Effect.Http.Error -> Effect.Http.Error
migrateHttpError httpError =
    case httpError of
        Evergreen.V48.Effect.Http.BadUrl url ->
            Effect.Http.BadUrl url

        Evergreen.V48.Effect.Http.Timeout ->
            Effect.Http.Timeout

        Evergreen.V48.Effect.Http.NetworkError ->
            Effect.Http.NetworkError

        Evergreen.V48.Effect.Http.BadStatus int ->
            Effect.Http.BadStatus int

        Evergreen.V48.Effect.Http.BadBody string ->
            Effect.Http.BadBody string


migrateSessionId : Evergreen.V48.Effect.Lamdera.SessionId -> Effect.Lamdera.SessionId
migrateSessionId (Evergreen.V48.Effect.Lamdera.SessionId id) =
    Effect.Lamdera.sessionIdFromString id


migrateClientId : Evergreen.V48.Effect.Lamdera.ClientId -> Effect.Lamdera.ClientId
migrateClientId (Evergreen.V48.Effect.Lamdera.ClientId id) =
    Effect.Lamdera.clientIdFromString id


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
    MsgUnchanged


toFrontend : Old.ToFrontend -> MsgMigration New.ToFrontend New.FrontendMsg
toFrontend old =
    MsgUnchanged
