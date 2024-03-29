module Evergreen.Migrate.V69 exposing (..)

{-| This migration file was automatically generated by the lamdera compiler.

It includes:

  - A migration for each of the 6 Lamdera core types that has changed
  - A function named `migrate_ModuleName_TypeName` for each changed/custom type

Expect to see:

  - `Unimplementеd` values as placeholders wherever I was unable to figure out a clear migration path for you
  - `@NOTICE` comments for things you should know about, i.e. new custom type constructors that won't get any
    value mappings from the old type by default

You can edit this file however you wish! It won't be generated again.

See <https://dashboard.lamdera.app/docs/evergreen> for more info.

-}

import Array
import AssocList
import AssocSet
import BiDict.Assoc
import Evergreen.V68.Address
import Evergreen.V68.AdminStatus
import Evergreen.V68.Cache
import Evergreen.V68.CreateGroupPage
import Evergreen.V68.Description
import Evergreen.V68.EmailAddress
import Evergreen.V68.Event
import Evergreen.V68.EventDuration
import Evergreen.V68.EventName
import Evergreen.V68.FrontendUser
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
import Evergreen.V68.TimeZone
import Evergreen.V68.Types
import Evergreen.V68.Untrusted
import Evergreen.V69.Address
import Evergreen.V69.AdminStatus
import Evergreen.V69.Cache
import Evergreen.V69.CreateGroupPage
import Evergreen.V69.Description
import Evergreen.V69.EmailAddress
import Evergreen.V69.Event
import Evergreen.V69.EventDuration
import Evergreen.V69.EventName
import Evergreen.V69.FrontendUser
import Evergreen.V69.Group
import Evergreen.V69.GroupName
import Evergreen.V69.GroupPage
import Evergreen.V69.Id
import Evergreen.V69.Link
import Evergreen.V69.MaxAttendees
import Evergreen.V69.Name
import Evergreen.V69.ProfileImage
import Evergreen.V69.ProfilePage
import Evergreen.V69.Route
import Evergreen.V69.TimeZone
import Evergreen.V69.Types
import Evergreen.V69.Untrusted
import Lamdera.Migrations exposing (..)
import List
import List.Nonempty
import Maybe


frontendModel : Evergreen.V68.Types.FrontendModel -> ModelMigration Evergreen.V69.Types.FrontendModel Evergreen.V69.Types.FrontendMsg
frontendModel old =
    ModelUnchanged


backendModel : Evergreen.V68.Types.BackendModel -> ModelMigration Evergreen.V69.Types.BackendModel Evergreen.V69.Types.BackendMsg
backendModel old =
    ModelMigrated ( migrate_Types_BackendModel old, Cmd.none )


frontendMsg : Evergreen.V68.Types.FrontendMsg -> MsgMigration Evergreen.V69.Types.FrontendMsg Evergreen.V69.Types.FrontendMsg
frontendMsg old =
    MsgOldValueIgnored


toBackend : Evergreen.V68.Types.ToBackend -> MsgMigration Evergreen.V69.Types.ToBackend Evergreen.V69.Types.BackendMsg
toBackend old =
    MsgOldValueIgnored


backendMsg : Evergreen.V68.Types.BackendMsg -> MsgMigration Evergreen.V69.Types.BackendMsg Evergreen.V69.Types.BackendMsg
backendMsg old =
    MsgUnchanged


toFrontend : Evergreen.V68.Types.ToFrontend -> MsgMigration Evergreen.V69.Types.ToFrontend Evergreen.V69.Types.FrontendMsg
toFrontend old =
    MsgOldValueIgnored


migrate_Types_BackendModel : Evergreen.V68.Types.BackendModel -> Evergreen.V69.Types.BackendModel
migrate_Types_BackendModel old =
    { users = old.users |> migrate_AssocList_Dict (migrate_Id_Id migrate_Id_UserId) migrate_Types_BackendUser
    , groups = old.groups |> migrate_AssocList_Dict (migrate_Id_Id migrate_Id_GroupId) migrate_Group_Group
    , deletedGroups = old.deletedGroups |> migrate_AssocList_Dict (migrate_Id_Id migrate_Id_GroupId) migrate_Group_Group
    , sessions = old.sessions |> migrate_BiDict_Assoc_BiDict identity (migrate_Id_Id migrate_Id_UserId)
    , loginAttempts = old.loginAttempts
    , connections = old.connections
    , logs = old.logs |> Array.map migrate_Types_Log
    , time = old.time
    , secretCounter = old.secretCounter
    , pendingLoginTokens = old.pendingLoginTokens |> migrate_AssocList_Dict (migrate_Id_Id migrate_Id_LoginToken) migrate_Types_LoginTokenData
    , pendingDeleteUserTokens = old.pendingDeleteUserTokens |> migrate_AssocList_Dict (migrate_Id_Id migrate_Id_DeleteUserToken) migrate_Types_DeleteUserTokenData
    }


migrate_Address_Address : Evergreen.V68.Address.Address -> Evergreen.V69.Address.Address
migrate_Address_Address old =
    case old of
        Evergreen.V68.Address.Address p0 ->
            Evergreen.V69.Address.Address p0


migrate_AssocList_Dict : (a_old -> a_new) -> (b_old -> b_new) -> AssocList.Dict a_old b_old -> AssocList.Dict a_new b_new
migrate_AssocList_Dict migrate_a migrate_b old =
    old
        |> AssocList.toList
        |> List.map (Tuple.mapBoth migrate_a migrate_b)
        |> AssocList.fromList


migrate_AssocSet_Set : (a_old -> a_new) -> AssocSet.Set a_old -> AssocSet.Set a_new
migrate_AssocSet_Set migrate_a old =
    old |> AssocSet.map migrate_a


migrate_BiDict_Assoc_BiDict : (a_old -> a_new) -> (b_old -> b_new) -> BiDict.Assoc.BiDict a_old b_old -> BiDict.Assoc.BiDict a_new b_new
migrate_BiDict_Assoc_BiDict migrate_a migrate_b old =
    BiDict.Assoc.toList old
        |> List.map (\( key, value ) -> ( migrate_a key, migrate_b value ))
        |> BiDict.Assoc.fromList


migrate_Description_Description : Evergreen.V68.Description.Description -> Evergreen.V69.Description.Description
migrate_Description_Description old =
    case old of
        Evergreen.V68.Description.Description p0 ->
            Evergreen.V69.Description.Description p0


migrate_EmailAddress_EmailAddress : Evergreen.V68.EmailAddress.EmailAddress -> Evergreen.V69.EmailAddress.EmailAddress
migrate_EmailAddress_EmailAddress old =
    case old of
        Evergreen.V68.EmailAddress.EmailAddress p0 ->
            Evergreen.V69.EmailAddress.EmailAddress p0


migrate_EventDuration_EventDuration : Evergreen.V68.EventDuration.EventDuration -> Evergreen.V69.EventDuration.EventDuration
migrate_EventDuration_EventDuration old =
    case old of
        Evergreen.V68.EventDuration.EventDuration p0 ->
            Evergreen.V69.EventDuration.EventDuration p0


migrate_EventName_EventName : Evergreen.V68.EventName.EventName -> Evergreen.V69.EventName.EventName
migrate_EventName_EventName old =
    case old of
        Evergreen.V68.EventName.EventName p0 ->
            Evergreen.V69.EventName.EventName p0


migrate_Event_CancellationStatus : Evergreen.V68.Event.CancellationStatus -> Evergreen.V69.Event.CancellationStatus
migrate_Event_CancellationStatus old =
    case old of
        Evergreen.V68.Event.EventCancelled ->
            Evergreen.V69.Event.EventCancelled

        Evergreen.V68.Event.EventUncancelled ->
            Evergreen.V69.Event.EventUncancelled


migrate_Event_Event : Evergreen.V68.Event.Event -> Evergreen.V69.Event.Event
migrate_Event_Event old =
    case old of
        Evergreen.V68.Event.Event p0 ->
            Evergreen.V69.Event.Event
                { name = p0.name |> migrate_EventName_EventName
                , description = p0.description |> migrate_Description_Description
                , eventType = p0.eventType |> migrate_Event_EventType
                , attendees = p0.attendees |> migrate_AssocSet_Set (migrate_Id_Id migrate_Id_UserId)
                , startTime = p0.startTime
                , duration = p0.duration |> migrate_EventDuration_EventDuration
                , cancellationStatus = p0.cancellationStatus |> Maybe.map (Tuple.mapFirst migrate_Event_CancellationStatus)
                , createdAt = p0.createdAt
                , maxAttendees = p0.maxAttendees |> migrate_MaxAttendees_MaxAttendees
                }


migrate_Event_EventType : Evergreen.V68.Event.EventType -> Evergreen.V69.Event.EventType
migrate_Event_EventType old =
    case old of
        Evergreen.V68.Event.MeetOnline p0 ->
            Evergreen.V69.Event.MeetOnline (p0 |> Maybe.map migrate_Link_Link)

        Evergreen.V68.Event.MeetInPerson p0 ->
            Evergreen.V69.Event.MeetInPerson (p0 |> Maybe.map migrate_Address_Address)

        Evergreen.V68.Event.MeetOnlineAndInPerson p0 p1 ->
            Evergreen.V69.Event.MeetOnlineAndInPerson (p0 |> Maybe.map migrate_Link_Link)
                (p1 |> Maybe.map migrate_Address_Address)


migrate_GroupName_GroupName : Evergreen.V68.GroupName.GroupName -> Evergreen.V69.GroupName.GroupName
migrate_GroupName_GroupName old =
    case old of
        Evergreen.V68.GroupName.GroupName p0 ->
            Evergreen.V69.GroupName.GroupName p0


migrate_GroupPage_ToBackend : Evergreen.V68.GroupPage.ToBackend -> Evergreen.V69.GroupPage.ToBackend
migrate_GroupPage_ToBackend old =
    case old of
        Evergreen.V68.GroupPage.ChangeGroupNameRequest p0 ->
            Evergreen.V69.GroupPage.ChangeGroupNameRequest (p0 |> migrate_Untrusted_Untrusted migrate_GroupName_GroupName)

        Evergreen.V68.GroupPage.ChangeGroupDescriptionRequest p0 ->
            Evergreen.V69.GroupPage.ChangeGroupDescriptionRequest (p0 |> migrate_Untrusted_Untrusted migrate_Description_Description)

        Evergreen.V68.GroupPage.ChangeGroupVisibilityRequest p0 ->
            Evergreen.V69.GroupPage.ChangeGroupVisibilityRequest (p0 |> migrate_Group_GroupVisibility)

        Evergreen.V68.GroupPage.CreateEventRequest p0 p1 p2 p3 p4 p5 ->
            Evergreen.V69.GroupPage.CreateEventRequest (p0 |> migrate_Untrusted_Untrusted migrate_EventName_EventName)
                (p1 |> migrate_Untrusted_Untrusted migrate_Description_Description)
                (p2 |> migrate_Untrusted_Untrusted migrate_Event_EventType)
                p3
                (p4 |> migrate_Untrusted_Untrusted migrate_EventDuration_EventDuration)
                (p5 |> migrate_Untrusted_Untrusted migrate_MaxAttendees_MaxAttendees)

        Evergreen.V68.GroupPage.EditEventRequest p0 p1 p2 p3 p4 p5 p6 ->
            Evergreen.V69.GroupPage.EditEventRequest (p0 |> migrate_Group_EventId)
                (p1 |> migrate_Untrusted_Untrusted migrate_EventName_EventName)
                (p2 |> migrate_Untrusted_Untrusted migrate_Description_Description)
                (p3 |> migrate_Untrusted_Untrusted migrate_Event_EventType)
                p4
                (p5 |> migrate_Untrusted_Untrusted migrate_EventDuration_EventDuration)
                (p6 |> migrate_Untrusted_Untrusted migrate_MaxAttendees_MaxAttendees)

        Evergreen.V68.GroupPage.JoinEventRequest p0 ->
            Evergreen.V69.GroupPage.JoinEventRequest (p0 |> migrate_Group_EventId)

        Evergreen.V68.GroupPage.LeaveEventRequest p0 ->
            Evergreen.V69.GroupPage.LeaveEventRequest (p0 |> migrate_Group_EventId)

        Evergreen.V68.GroupPage.ChangeEventCancellationStatusRequest p0 p1 ->
            Evergreen.V69.GroupPage.ChangeEventCancellationStatusRequest (p0 |> migrate_Group_EventId)
                (p1 |> migrate_Event_CancellationStatus)

        Evergreen.V68.GroupPage.DeleteGroupAdminRequest ->
            Evergreen.V69.GroupPage.DeleteGroupAdminRequest

        Evergreen.V68.GroupPage.SubscribeRequest ->
            Evergreen.V69.GroupPage.SubscribeRequest

        Evergreen.V68.GroupPage.UnsubscribeRequest ->
            Evergreen.V69.GroupPage.UnsubscribeRequest


migrate_Group_EventId : Evergreen.V68.Group.EventId -> Evergreen.V69.Group.EventId
migrate_Group_EventId old =
    case old of
        Evergreen.V68.Group.EventId p0 ->
            Evergreen.V69.Group.EventId p0


migrate_Group_Group : Evergreen.V68.Group.Group -> Evergreen.V69.Group.Group
migrate_Group_Group old =
    case old of
        Evergreen.V68.Group.Group p0 ->
            Evergreen.V69.Group.Group
                { ownerId = p0.ownerId |> migrate_Id_Id migrate_Id_UserId
                , name = p0.name |> migrate_GroupName_GroupName
                , description = p0.description |> migrate_Description_Description
                , events = p0.events |> migrate_AssocList_Dict migrate_Group_EventId migrate_Event_Event
                , visibility = p0.visibility |> migrate_Group_GroupVisibility
                , eventCounter = p0.eventCounter
                , createdAt = p0.createdAt
                , pendingReview = p0.pendingReview
                }


migrate_Group_GroupVisibility : Evergreen.V68.Group.GroupVisibility -> Evergreen.V69.Group.GroupVisibility
migrate_Group_GroupVisibility old =
    case old of
        Evergreen.V68.Group.UnlistedGroup ->
            Evergreen.V69.Group.UnlistedGroup

        Evergreen.V68.Group.PublicGroup ->
            Evergreen.V69.Group.PublicGroup


migrate_Id_DeleteUserToken : Evergreen.V68.Id.DeleteUserToken -> Evergreen.V69.Id.DeleteUserToken
migrate_Id_DeleteUserToken old =
    case old of
        Evergreen.V68.Id.DeleteUserToken p0 ->
            Evergreen.V69.Id.DeleteUserToken p0


migrate_Id_GroupId : Evergreen.V68.Id.GroupId -> Evergreen.V69.Id.GroupId
migrate_Id_GroupId old =
    case old of
        Evergreen.V68.Id.GroupId p0 ->
            Evergreen.V69.Id.GroupId p0


migrate_Id_Id : (a_old -> a_new) -> Evergreen.V68.Id.Id a_old -> Evergreen.V69.Id.Id a_new
migrate_Id_Id _ old =
    case old of
        Evergreen.V68.Id.Id p0 ->
            Evergreen.V69.Id.Id p0


migrate_Id_LoginToken : Evergreen.V68.Id.LoginToken -> Evergreen.V69.Id.LoginToken
migrate_Id_LoginToken old =
    case old of
        Evergreen.V68.Id.LoginToken p0 ->
            Evergreen.V69.Id.LoginToken p0


migrate_Id_SessionIdFirst4Chars : Evergreen.V68.Id.SessionIdFirst4Chars -> Evergreen.V69.Id.SessionIdFirst4Chars
migrate_Id_SessionIdFirst4Chars old =
    case old of
        Evergreen.V68.Id.SessionIdFirst4Chars p0 ->
            Evergreen.V69.Id.SessionIdFirst4Chars p0


migrate_Id_UserId : Evergreen.V68.Id.UserId -> Evergreen.V69.Id.UserId
migrate_Id_UserId old =
    case old of
        Evergreen.V68.Id.UserId p0 ->
            Evergreen.V69.Id.UserId p0


migrate_Link_Link : Evergreen.V68.Link.Link -> Evergreen.V69.Link.Link
migrate_Link_Link old =
    case old of
        Evergreen.V68.Link.Link p0 ->
            Evergreen.V69.Link.Link p0


migrate_List_Nonempty_Nonempty : (a_old -> a_new) -> List.Nonempty.Nonempty a_old -> List.Nonempty.Nonempty a_new
migrate_List_Nonempty_Nonempty migrate_a old =
    old |> List.Nonempty.map migrate_a


migrate_MaxAttendees_MaxAttendees : Evergreen.V68.MaxAttendees.MaxAttendees -> Evergreen.V69.MaxAttendees.MaxAttendees
migrate_MaxAttendees_MaxAttendees old =
    case old of
        Evergreen.V68.MaxAttendees.NoLimit ->
            Evergreen.V69.MaxAttendees.NoLimit

        Evergreen.V68.MaxAttendees.MaxAttendees p0 ->
            Evergreen.V69.MaxAttendees.MaxAttendees p0


migrate_Name_Name : Evergreen.V68.Name.Name -> Evergreen.V69.Name.Name
migrate_Name_Name old =
    case old of
        Evergreen.V68.Name.Name p0 ->
            Evergreen.V69.Name.Name p0


migrate_ProfileImage_ProfileImage : Evergreen.V68.ProfileImage.ProfileImage -> Evergreen.V69.ProfileImage.ProfileImage
migrate_ProfileImage_ProfileImage old =
    case old of
        Evergreen.V68.ProfileImage.DefaultImage ->
            Evergreen.V69.ProfileImage.DefaultImage

        Evergreen.V68.ProfileImage.CustomImage p0 ->
            Evergreen.V69.ProfileImage.CustomImage p0


migrate_ProfilePage_ToBackend : Evergreen.V68.ProfilePage.ToBackend -> Evergreen.V69.ProfilePage.ToBackend
migrate_ProfilePage_ToBackend old =
    case old of
        Evergreen.V68.ProfilePage.ChangeNameRequest p0 ->
            Evergreen.V69.ProfilePage.ChangeNameRequest (p0 |> migrate_Untrusted_Untrusted migrate_Name_Name)

        Evergreen.V68.ProfilePage.ChangeDescriptionRequest p0 ->
            Evergreen.V69.ProfilePage.ChangeDescriptionRequest (p0 |> migrate_Untrusted_Untrusted migrate_Description_Description)

        Evergreen.V68.ProfilePage.ChangeEmailAddressRequest p0 ->
            Evergreen.V69.ProfilePage.ChangeEmailAddressRequest (p0 |> migrate_Untrusted_Untrusted migrate_EmailAddress_EmailAddress)

        Evergreen.V68.ProfilePage.SendDeleteUserEmailRequest ->
            Evergreen.V69.ProfilePage.SendDeleteUserEmailRequest

        Evergreen.V68.ProfilePage.ChangeProfileImageRequest p0 ->
            Evergreen.V69.ProfilePage.ChangeProfileImageRequest (p0 |> migrate_Untrusted_Untrusted migrate_ProfileImage_ProfileImage)


migrate_Route_Route : Evergreen.V68.Route.Route -> Evergreen.V69.Route.Route
migrate_Route_Route old =
    case old of
        Evergreen.V68.Route.HomepageRoute ->
            Evergreen.V69.Route.HomepageRoute

        Evergreen.V68.Route.GroupRoute p0 p1 ->
            Evergreen.V69.Route.GroupRoute (p0 |> migrate_Id_Id migrate_Id_GroupId)
                (p1 |> migrate_GroupName_GroupName)

        Evergreen.V68.Route.AdminRoute ->
            Evergreen.V69.Route.AdminRoute

        Evergreen.V68.Route.CreateGroupRoute ->
            Evergreen.V69.Route.CreateGroupRoute

        Evergreen.V68.Route.SearchGroupsRoute p0 ->
            Evergreen.V69.Route.SearchGroupsRoute p0

        Evergreen.V68.Route.MyGroupsRoute ->
            Evergreen.V69.Route.MyGroupsRoute

        Evergreen.V68.Route.MyProfileRoute ->
            Evergreen.V69.Route.MyProfileRoute

        Evergreen.V68.Route.UserRoute p0 p1 ->
            Evergreen.V69.Route.UserRoute (p0 |> migrate_Id_Id migrate_Id_UserId)
                (p1 |> migrate_Name_Name)

        Evergreen.V68.Route.PrivacyRoute ->
            Evergreen.V69.Route.PrivacyRoute

        Evergreen.V68.Route.TermsOfServiceRoute ->
            Evergreen.V69.Route.TermsOfServiceRoute

        Evergreen.V68.Route.CodeOfConductRoute ->
            Evergreen.V69.Route.CodeOfConductRoute

        Evergreen.V68.Route.FrequentQuestionsRoute ->
            Evergreen.V69.Route.FrequentQuestionsRoute


migrate_Types_BackendUser : Evergreen.V68.Types.BackendUser -> Evergreen.V69.Types.BackendUser
migrate_Types_BackendUser old =
    { name = old.name |> migrate_Name_Name
    , description = old.description |> migrate_Description_Description
    , emailAddress = old.emailAddress |> migrate_EmailAddress_EmailAddress
    , profileImage = old.profileImage |> migrate_ProfileImage_ProfileImage
    , timezone = old.timezone
    , allowEventReminders = old.allowEventReminders
    , subscribedGroups = old.subscribedGroups |> migrate_AssocSet_Set (migrate_Id_Id migrate_Id_GroupId)
    }


migrate_Types_DeleteUserTokenData : Evergreen.V68.Types.DeleteUserTokenData -> Evergreen.V69.Types.DeleteUserTokenData
migrate_Types_DeleteUserTokenData old =
    { creationTime = old.creationTime
    , userId = old.userId |> migrate_Id_Id migrate_Id_UserId
    }


migrate_Types_Log : Evergreen.V68.Types.Log -> Evergreen.V69.Types.Log
migrate_Types_Log old =
    case old of
        Evergreen.V68.Types.LogUntrustedCheckFailed p0 p1 p2 ->
            Evergreen.V69.Types.LogUntrustedCheckFailed p0
                (p1 |> migrate_Types_ToBackend)
                (p2 |> migrate_Id_SessionIdFirst4Chars)

        Evergreen.V68.Types.LogLoginEmail p0 p1 p2 ->
            Evergreen.V69.Types.LogLoginEmail p0 p1 (p2 |> migrate_EmailAddress_EmailAddress)

        Evergreen.V68.Types.LogDeleteAccountEmail p0 p1 p2 ->
            Evergreen.V69.Types.LogDeleteAccountEmail p0 p1 (p2 |> migrate_Id_Id migrate_Id_UserId)

        Evergreen.V68.Types.LogEventReminderEmail p0 p1 p2 p3 p4 ->
            Evergreen.V69.Types.LogEventReminderEmail p0
                p1
                (p2 |> migrate_Id_Id migrate_Id_UserId)
                (p3 |> migrate_Id_Id migrate_Id_GroupId)
                (p4 |> migrate_Group_EventId)

        Evergreen.V68.Types.LogNewEventNotificationEmail p0 p1 p2 p3 ->
            Evergreen.V69.Types.LogNewEventNotificationEmail p0
                p1
                (p2 |> migrate_Id_Id migrate_Id_UserId)
                (p3 |> migrate_Id_Id migrate_Id_GroupId)

        Evergreen.V68.Types.LogLoginTokenEmailRequestRateLimited p0 p1 p2 ->
            Evergreen.V69.Types.LogLoginTokenEmailRequestRateLimited p0
                (p1 |> migrate_EmailAddress_EmailAddress)
                (p2 |> migrate_Id_SessionIdFirst4Chars)

        Evergreen.V68.Types.LogDeleteAccountEmailRequestRateLimited p0 p1 p2 ->
            Evergreen.V69.Types.LogDeleteAccountEmailRequestRateLimited p0
                (p1 |> migrate_Id_Id migrate_Id_UserId)
                (p2 |> migrate_Id_SessionIdFirst4Chars)


migrate_Types_LoginTokenData : Evergreen.V68.Types.LoginTokenData -> Evergreen.V69.Types.LoginTokenData
migrate_Types_LoginTokenData old =
    { creationTime = old.creationTime
    , emailAddress = old.emailAddress |> migrate_EmailAddress_EmailAddress
    }


migrate_Types_ToBackend : Evergreen.V68.Types.ToBackend -> Evergreen.V69.Types.ToBackend
migrate_Types_ToBackend old =
    case old of
        Evergreen.V68.Types.GetGroupRequest p0 ->
            Evergreen.V69.Types.GetGroupRequest (p0 |> migrate_Id_Id migrate_Id_GroupId)

        Evergreen.V68.Types.GetUserRequest p0 ->
            Evergreen.V69.Types.GetUserRequest (p0 |> migrate_List_Nonempty_Nonempty (migrate_Id_Id migrate_Id_UserId))

        Evergreen.V68.Types.CheckLoginRequest ->
            Evergreen.V69.Types.CheckLoginRequest

        Evergreen.V68.Types.LoginWithTokenRequest p0 p1 ->
            Evergreen.V69.Types.LoginWithTokenRequest (p0 |> migrate_Id_Id migrate_Id_LoginToken)
                (p1 |> Maybe.map (Tuple.mapBoth (migrate_Id_Id migrate_Id_GroupId) migrate_Group_EventId))

        Evergreen.V68.Types.GetLoginTokenRequest p0 p1 p2 ->
            Evergreen.V69.Types.GetLoginTokenRequest (p0 |> migrate_Route_Route)
                (p1 |> migrate_Untrusted_Untrusted migrate_EmailAddress_EmailAddress)
                (p2 |> Maybe.map (Tuple.mapBoth (migrate_Id_Id migrate_Id_GroupId) migrate_Group_EventId))

        Evergreen.V68.Types.GetAdminDataRequest ->
            Evergreen.V69.Types.GetAdminDataRequest

        Evergreen.V68.Types.LogoutRequest ->
            Evergreen.V69.Types.LogoutRequest

        Evergreen.V68.Types.CreateGroupRequest p0 p1 p2 ->
            Evergreen.V69.Types.CreateGroupRequest (p0 |> migrate_Untrusted_Untrusted migrate_GroupName_GroupName)
                (p1 |> migrate_Untrusted_Untrusted migrate_Description_Description)
                (p2 |> migrate_Group_GroupVisibility)

        Evergreen.V68.Types.DeleteUserRequest p0 ->
            Evergreen.V69.Types.DeleteUserRequest (p0 |> migrate_Id_Id migrate_Id_DeleteUserToken)

        Evergreen.V68.Types.GetMyGroupsRequest ->
            Evergreen.V69.Types.GetMyGroupsRequest

        Evergreen.V68.Types.SearchGroupsRequest p0 ->
            Evergreen.V69.Types.SearchGroupsRequest p0

        Evergreen.V68.Types.GroupRequest p0 p1 ->
            Evergreen.V69.Types.GroupRequest (p0 |> migrate_Id_Id migrate_Id_GroupId)
                (p1 |> migrate_GroupPage_ToBackend)

        Evergreen.V68.Types.ProfileFormRequest p0 ->
            Evergreen.V69.Types.ProfileFormRequest (p0 |> migrate_ProfilePage_ToBackend)


migrate_Untrusted_Untrusted : (a_old -> a_new) -> Evergreen.V68.Untrusted.Untrusted a_old -> Evergreen.V69.Untrusted.Untrusted a_new
migrate_Untrusted_Untrusted migrate_a old =
    case old of
        Evergreen.V68.Untrusted.Untrusted p0 ->
            Evergreen.V69.Untrusted.Untrusted (p0 |> migrate_a)
