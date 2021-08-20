module Evergreen.Migrate.V48 exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc as BiDict
import Evergreen.V46.Address
import Evergreen.V46.Description
import Evergreen.V46.EmailAddress
import Evergreen.V46.Event
import Evergreen.V46.EventDuration
import Evergreen.V46.EventName
import Evergreen.V46.Group
import Evergreen.V46.GroupName
import Evergreen.V46.Id
import Evergreen.V46.Link
import Evergreen.V46.MaxAttendees
import Evergreen.V46.Name
import Evergreen.V46.ProfileImage
import Evergreen.V46.Route
import Evergreen.V46.Types as Old
import Evergreen.V46.Untrusted
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
import Evergreen.V48.Types as New
import Evergreen.V48.Untrusted
import Http
import Lamdera.Migrations exposing (..)
import List.Nonempty


frontendModel : Old.FrontendModel -> ModelMigration New.FrontendModel New.FrontendMsg
frontendModel old =
    ModelUnchanged


migrateName : Evergreen.V46.Name.Name -> Evergreen.V48.Name.Name
migrateName (Evergreen.V46.Name.Name name) =
    Evergreen.V48.Name.Name name


migrateDescription : Evergreen.V46.Description.Description -> Evergreen.V48.Description.Description
migrateDescription (Evergreen.V46.Description.Description name) =
    Evergreen.V48.Description.Description name


migrateProfileImage : Evergreen.V46.ProfileImage.ProfileImage -> Evergreen.V48.ProfileImage.ProfileImage
migrateProfileImage a =
    case a of
        Evergreen.V46.ProfileImage.DefaultImage ->
            Evergreen.V48.ProfileImage.DefaultImage

        Evergreen.V46.ProfileImage.CustomImage b ->
            Evergreen.V48.ProfileImage.CustomImage b


migrateBackendUser : Old.BackendUser -> New.BackendUser
migrateBackendUser backendUser =
    { name = migrateName backendUser.name
    , description = migrateDescription backendUser.description
    , emailAddress = migrateEmailAddress backendUser.emailAddress
    , profileImage = migrateProfileImage backendUser.profileImage
    , timezone = backendUser.timezone
    , allowEventReminders = backendUser.allowEventReminders
    }


migrateId : Evergreen.V46.Id.Id a -> Evergreen.V48.Id.Id b
migrateId (Evergreen.V46.Id.Id id) =
    Evergreen.V48.Id.Id id


migrateUserId : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId -> Evergreen.V48.Id.Id Evergreen.V48.Id.UserId
migrateUserId (Evergreen.V46.Id.Id id) =
    Evergreen.V48.Id.Id id


migrateSessionIdFirst4Chars : Evergreen.V46.Id.SessionIdFirst4Chars -> Evergreen.V48.Id.SessionIdFirst4Chars
migrateSessionIdFirst4Chars (Evergreen.V46.Id.SessionIdFirst4Chars id) =
    Evergreen.V48.Id.SessionIdFirst4Chars id


migrateSessionId : Evergreen.V46.Id.SessionId -> Evergreen.V48.Effect.Lamdera.SessionId
migrateSessionId (Evergreen.V46.Id.SessionId id) =
    Evergreen.V48.Effect.Lamdera.SessionId id


migrateClientId : Evergreen.V46.Id.ClientId -> Evergreen.V48.Effect.Lamdera.ClientId
migrateClientId (Evergreen.V46.Id.ClientId id) =
    Evergreen.V48.Effect.Lamdera.ClientId id


migrateGroupName : Evergreen.V46.GroupName.GroupName -> Evergreen.V48.GroupName.GroupName
migrateGroupName (Evergreen.V46.GroupName.GroupName id) =
    Evergreen.V48.GroupName.GroupName id


migrateEventId : Evergreen.V46.Group.EventId -> Evergreen.V48.Group.EventId
migrateEventId (Evergreen.V46.Group.EventId id) =
    Evergreen.V48.Group.EventId id


migrateGroupId : Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId -> Evergreen.V48.Id.Id Evergreen.V48.Id.GroupId
migrateGroupId (Evergreen.V46.Id.Id id) =
    Evergreen.V48.Id.Id id


migrateEventName : Evergreen.V46.EventName.EventName -> Evergreen.V48.EventName.EventName
migrateEventName (Evergreen.V46.EventName.EventName a) =
    Evergreen.V48.EventName.EventName a


migrateLink : Evergreen.V46.Link.Link -> Evergreen.V48.Link.Link
migrateLink (Evergreen.V46.Link.Link a) =
    Evergreen.V48.Link.Link a


migrateAddress : Evergreen.V46.Address.Address -> Evergreen.V48.Address.Address
migrateAddress (Evergreen.V46.Address.Address a) =
    Evergreen.V48.Address.Address a


migrateEventType : Evergreen.V46.Event.EventType -> Evergreen.V48.Event.EventType
migrateEventType a =
    case a of
        Evergreen.V46.Event.MeetOnline maybeLink ->
            Maybe.map migrateLink maybeLink |> Evergreen.V48.Event.MeetOnline

        Evergreen.V46.Event.MeetInPerson maybeAddress ->
            Maybe.map migrateAddress maybeAddress |> Evergreen.V48.Event.MeetInPerson


migrateEventDuration : Evergreen.V46.EventDuration.EventDuration -> Evergreen.V48.EventDuration.EventDuration
migrateEventDuration (Evergreen.V46.EventDuration.EventDuration a) =
    Evergreen.V48.EventDuration.EventDuration a


migrateCancellationStatus : Evergreen.V46.Event.CancellationStatus -> Evergreen.V48.Event.CancellationStatus
migrateCancellationStatus a =
    case a of
        Evergreen.V46.Event.EventCancelled ->
            Evergreen.V48.Event.EventCancelled

        Evergreen.V46.Event.EventUncancelled ->
            Evergreen.V48.Event.EventUncancelled


migrateMaxAttendees : Evergreen.V46.MaxAttendees.MaxAttendees -> Evergreen.V48.MaxAttendees.MaxAttendees
migrateMaxAttendees a =
    case a of
        Evergreen.V46.MaxAttendees.NoLimit ->
            Evergreen.V48.MaxAttendees.NoLimit

        Evergreen.V46.MaxAttendees.MaxAttendees b ->
            Evergreen.V48.MaxAttendees.MaxAttendees b


migrateEvent : Evergreen.V46.Event.Event -> Evergreen.V48.Event.Event
migrateEvent (Evergreen.V46.Event.Event event) =
    Evergreen.V48.Event.Event
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


migrateGroupVisibility : Evergreen.V46.Group.GroupVisibility -> Evergreen.V48.Group.GroupVisibility
migrateGroupVisibility a =
    case a of
        Evergreen.V46.Group.UnlistedGroup ->
            Evergreen.V48.Group.UnlistedGroup

        Evergreen.V46.Group.PublicGroup ->
            Evergreen.V48.Group.PublicGroup


migrateGroup : Evergreen.V46.Group.Group -> Evergreen.V48.Group.Group
migrateGroup (Evergreen.V46.Group.Group group) =
    Evergreen.V48.Group.Group
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


migrateUntrusted : (a -> b) -> Evergreen.V46.Untrusted.Untrusted a -> Evergreen.V48.Untrusted.Untrusted b
migrateUntrusted mapFunc (Evergreen.V46.Untrusted.Untrusted a) =
    Evergreen.V48.Untrusted.Untrusted (mapFunc a)


migrateRoute : Evergreen.V46.Route.Route -> Evergreen.V48.Route.Route
migrateRoute a =
    case a of
        Evergreen.V46.Route.HomepageRoute ->
            Evergreen.V48.Route.HomepageRoute

        Evergreen.V46.Route.GroupRoute groupId groupName ->
            Evergreen.V48.Route.GroupRoute (migrateGroupId groupId) (migrateGroupName groupName)

        Evergreen.V46.Route.AdminRoute ->
            Evergreen.V48.Route.AdminRoute

        Evergreen.V46.Route.CreateGroupRoute ->
            Evergreen.V48.Route.CreateGroupRoute

        Evergreen.V46.Route.SearchGroupsRoute string ->
            Evergreen.V48.Route.SearchGroupsRoute string

        Evergreen.V46.Route.MyGroupsRoute ->
            Evergreen.V48.Route.MyGroupsRoute

        Evergreen.V46.Route.MyProfileRoute ->
            Evergreen.V48.Route.MyProfileRoute

        Evergreen.V46.Route.UserRoute userId name ->
            Evergreen.V48.Route.UserRoute (migrateUserId userId) (migrateName name)

        Evergreen.V46.Route.PrivacyRoute ->
            Evergreen.V48.Route.PrivacyRoute

        Evergreen.V46.Route.TermsOfServiceRoute ->
            Evergreen.V48.Route.TermsOfServiceRoute

        Evergreen.V46.Route.CodeOfConductRoute ->
            Evergreen.V48.Route.CodeOfConductRoute

        Evergreen.V46.Route.FrequentQuestionsRoute ->
            Evergreen.V48.Route.FrequentQuestionsRoute


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
            Evergreen.V48.ProfilePage.ChangeNameRequest (migrateUntrusted migrateName a) |> New.ProfileFormRequest

        Old.ChangeDescriptionRequest a ->
            Evergreen.V48.ProfilePage.ChangeDescriptionRequest (migrateUntrusted migrateDescription a) |> New.ProfileFormRequest

        Old.ChangeEmailAddressRequest a ->
            Evergreen.V48.ProfilePage.ChangeEmailAddressRequest (migrateUntrusted migrateEmailAddress a) |> New.ProfileFormRequest

        Old.SendDeleteUserEmailRequest ->
            Evergreen.V48.ProfilePage.SendDeleteUserEmailRequest |> New.ProfileFormRequest

        Old.DeleteUserRequest a ->
            New.DeleteUserRequest (migrateId a)

        Old.ChangeProfileImageRequest a ->
            Evergreen.V48.ProfilePage.ChangeProfileImageRequest (migrateUntrusted migrateProfileImage a) |> New.ProfileFormRequest

        Old.GetMyGroupsRequest ->
            New.GetMyGroupsRequest

        Old.SearchGroupsRequest a ->
            New.SearchGroupsRequest a

        Old.ChangeGroupNameRequest a b ->
            Evergreen.V48.GroupPage.ChangeGroupNameRequest (migrateUntrusted migrateGroupName b)
                |> New.GroupRequest (migrateGroupId a)

        Old.ChangeGroupDescriptionRequest a b ->
            Evergreen.V48.GroupPage.ChangeGroupDescriptionRequest (migrateUntrusted migrateDescription b)
                |> New.GroupRequest (migrateGroupId a)

        Old.CreateEventRequest a b c d e f g ->
            Evergreen.V48.GroupPage.CreateEventRequest
                (migrateUntrusted migrateEventName b)
                (migrateUntrusted migrateDescription c)
                (migrateUntrusted migrateEventType d)
                e
                (migrateUntrusted migrateEventDuration f)
                (migrateUntrusted migrateMaxAttendees g)
                |> New.GroupRequest (migrateGroupId a)

        Old.EditEventRequest a b c d e f g h ->
            Evergreen.V48.GroupPage.EditEventRequest
                (migrateEventId b)
                (migrateUntrusted migrateEventName c)
                (migrateUntrusted migrateDescription d)
                (migrateUntrusted migrateEventType e)
                f
                (migrateUntrusted migrateEventDuration g)
                (migrateUntrusted migrateMaxAttendees h)
                |> New.GroupRequest (migrateGroupId a)

        Old.JoinEventRequest a b ->
            Evergreen.V48.GroupPage.JoinEventRequest (migrateEventId b)
                |> New.GroupRequest (migrateGroupId a)

        Old.LeaveEventRequest a b ->
            Evergreen.V48.GroupPage.LeaveEventRequest (migrateEventId b)
                |> New.GroupRequest (migrateGroupId a)

        Old.ChangeEventCancellationStatusRequest a b c ->
            Evergreen.V48.GroupPage.ChangeEventCancellationStatusRequest (migrateEventId b) (migrateCancellationStatus c)
                |> New.GroupRequest (migrateGroupId a)

        Old.ChangeGroupVisibilityRequest a groupVisibility ->
            Evergreen.V48.GroupPage.ChangeGroupVisibilityRequest (migrateGroupVisibility groupVisibility)
                |> New.GroupRequest (migrateGroupId a)

        Old.DeleteGroupAdminRequest a ->
            Evergreen.V48.GroupPage.DeleteGroupAdminRequest
                |> New.GroupRequest (migrateGroupId a)


migrateEmailAddress : Evergreen.V46.EmailAddress.EmailAddress -> Evergreen.V48.EmailAddress.EmailAddress
migrateEmailAddress (Evergreen.V46.EmailAddress.EmailAddress { domain, localPart, tags, tld }) =
    Evergreen.V48.EmailAddress.EmailAddress { domain = domain, localPart = localPart, tags = tags, tld = tld }


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


migrateHttpError : Http.Error -> Evergreen.V48.Effect.Http.Error
migrateHttpError httpError =
    case httpError of
        Http.BadUrl url ->
            Evergreen.V48.Effect.Http.BadUrl url

        Http.Timeout ->
            Evergreen.V48.Effect.Http.Timeout

        Http.NetworkError ->
            Evergreen.V48.Effect.Http.NetworkError

        Http.BadStatus int ->
            Evergreen.V48.Effect.Http.BadStatus int

        Http.BadBody string ->
            Evergreen.V48.Effect.Http.BadBody string


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
