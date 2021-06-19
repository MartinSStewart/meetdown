module Evergreen.V12.Types exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc
import Browser
import Browser.Navigation
import EmailAddress
import Evergreen.V12.CreateGroupForm
import Evergreen.V12.Description
import Evergreen.V12.Event
import Evergreen.V12.EventDuration
import Evergreen.V12.EventName
import Evergreen.V12.FrontendUser
import Evergreen.V12.Group
import Evergreen.V12.GroupName
import Evergreen.V12.GroupPage
import Evergreen.V12.Id
import Evergreen.V12.MaxAttendees
import Evergreen.V12.Name
import Evergreen.V12.ProfileImage
import Evergreen.V12.ProfilePage
import Evergreen.V12.Route
import Evergreen.V12.Untrusted
import List.Nonempty
import Pixels
import Quantity
import SendGrid
import Time
import TimeZone
import Url


type NavigationKey
    = RealNavigationKey Browser.Navigation.Key
    | MockNavigationKey


type alias LoadingFrontend =
    { navigationKey : NavigationKey
    , route : Evergreen.V12.Route.Route
    , routeToken : Evergreen.V12.Route.Token
    , windowSize : Maybe ( Quantity.Quantity Int Pixels.Pixels, Quantity.Quantity Int Pixels.Pixels )
    , time : Maybe Time.Posix
    , timezone : Maybe Time.Zone
    }


type ToBackend
    = GetGroupRequest Evergreen.V12.Id.GroupId
    | GetUserRequest (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId)
    | CheckLoginRequest
    | LoginWithTokenRequest (Evergreen.V12.Id.Id Evergreen.V12.Id.LoginToken) (Maybe ( Evergreen.V12.Id.GroupId, Evergreen.V12.Group.EventId ))
    | GetLoginTokenRequest Evergreen.V12.Route.Route (Evergreen.V12.Untrusted.Untrusted EmailAddress.EmailAddress) (Maybe ( Evergreen.V12.Id.GroupId, Evergreen.V12.Group.EventId ))
    | GetAdminDataRequest
    | LogoutRequest
    | CreateGroupRequest (Evergreen.V12.Untrusted.Untrusted Evergreen.V12.GroupName.GroupName) (Evergreen.V12.Untrusted.Untrusted Evergreen.V12.Description.Description) Evergreen.V12.Group.GroupVisibility
    | ChangeNameRequest (Evergreen.V12.Untrusted.Untrusted Evergreen.V12.Name.Name)
    | ChangeDescriptionRequest (Evergreen.V12.Untrusted.Untrusted Evergreen.V12.Description.Description)
    | ChangeEmailAddressRequest (Evergreen.V12.Untrusted.Untrusted EmailAddress.EmailAddress)
    | SendDeleteUserEmailRequest
    | DeleteUserRequest (Evergreen.V12.Id.Id Evergreen.V12.Id.DeleteUserToken)
    | ChangeProfileImageRequest (Evergreen.V12.Untrusted.Untrusted Evergreen.V12.ProfileImage.ProfileImage)
    | GetMyGroupsRequest
    | SearchGroupsRequest String
    | ChangeGroupNameRequest Evergreen.V12.Id.GroupId (Evergreen.V12.Untrusted.Untrusted Evergreen.V12.GroupName.GroupName)
    | ChangeGroupDescriptionRequest Evergreen.V12.Id.GroupId (Evergreen.V12.Untrusted.Untrusted Evergreen.V12.Description.Description)
    | CreateEventRequest Evergreen.V12.Id.GroupId (Evergreen.V12.Untrusted.Untrusted Evergreen.V12.EventName.EventName) (Evergreen.V12.Untrusted.Untrusted Evergreen.V12.Description.Description) (Evergreen.V12.Untrusted.Untrusted Evergreen.V12.Event.EventType) Time.Posix (Evergreen.V12.Untrusted.Untrusted Evergreen.V12.EventDuration.EventDuration) (Evergreen.V12.Untrusted.Untrusted Evergreen.V12.MaxAttendees.MaxAttendees)
    | EditEventRequest Evergreen.V12.Id.GroupId Evergreen.V12.Group.EventId (Evergreen.V12.Untrusted.Untrusted Evergreen.V12.EventName.EventName) (Evergreen.V12.Untrusted.Untrusted Evergreen.V12.Description.Description) (Evergreen.V12.Untrusted.Untrusted Evergreen.V12.Event.EventType) Time.Posix (Evergreen.V12.Untrusted.Untrusted Evergreen.V12.EventDuration.EventDuration) (Evergreen.V12.Untrusted.Untrusted Evergreen.V12.MaxAttendees.MaxAttendees)
    | JoinEventRequest Evergreen.V12.Id.GroupId Evergreen.V12.Group.EventId
    | LeaveEventRequest Evergreen.V12.Id.GroupId Evergreen.V12.Group.EventId
    | ChangeEventCancellationStatusRequest Evergreen.V12.Id.GroupId Evergreen.V12.Group.EventId Evergreen.V12.Event.CancellationStatus


type Log
    = LogUntrustedCheckFailed Time.Posix ToBackend
    | LogLoginEmail Time.Posix (Result SendGrid.Error ()) EmailAddress.EmailAddress
    | LogDeleteAccountEmail Time.Posix (Result SendGrid.Error ()) (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId)
    | LogEventReminderEmail Time.Posix (Result SendGrid.Error ()) (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) Evergreen.V12.Id.GroupId Evergreen.V12.Group.EventId


type alias AdminModel =
    { cachedEmailAddress : AssocList.Dict (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) EmailAddress.EmailAddress
    , logs : Array.Array Log
    }


type alias LoggedIn_ =
    { userId : Evergreen.V12.Id.Id Evergreen.V12.Id.UserId
    , emailAddress : EmailAddress.EmailAddress
    , profileForm : Evergreen.V12.ProfilePage.Model
    , myGroups : Maybe (AssocSet.Set Evergreen.V12.Id.GroupId)
    , adminState : Maybe AdminModel
    }


type LoginStatus
    = LoginStatusPending
    | LoggedIn LoggedIn_
    | NotLoggedIn
        { showLogin : Bool
        , joiningEvent : Maybe ( Evergreen.V12.Id.GroupId, Evergreen.V12.Group.EventId )
        }


type GroupCache
    = GroupNotFound
    | GroupFound Evergreen.V12.Group.Group
    | GroupRequestPending


type UserCache
    = UserNotFound
    | UserFound Evergreen.V12.FrontendUser.FrontendUser
    | UserRequestPending


type alias LoginForm =
    { email : String
    , pressedSubmitEmail : Bool
    , emailSent : Maybe EmailAddress.EmailAddress
    }


type alias LoadedFrontend =
    { navigationKey : NavigationKey
    , loginStatus : LoginStatus
    , route : Evergreen.V12.Route.Route
    , cachedGroups : AssocList.Dict Evergreen.V12.Id.GroupId GroupCache
    , cachedUsers : AssocList.Dict (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) UserCache
    , time : Time.Posix
    , timezone : Time.Zone
    , lastConnectionCheck : Time.Posix
    , loginForm : LoginForm
    , logs : Maybe (Array.Array Log)
    , hasLoginTokenError : Bool
    , groupForm : Evergreen.V12.CreateGroupForm.Model
    , groupCreated : Bool
    , accountDeletedResult : Maybe (Result () ())
    , searchText : String
    , searchList : List Evergreen.V12.Id.GroupId
    , windowWidth : Quantity.Quantity Int Pixels.Pixels
    , windowHeight : Quantity.Quantity Int Pixels.Pixels
    , groupPage : AssocList.Dict Evergreen.V12.Id.GroupId Evergreen.V12.GroupPage.Model
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias BackendUser =
    { name : Evergreen.V12.Name.Name
    , description : Evergreen.V12.Description.Description
    , emailAddress : EmailAddress.EmailAddress
    , profileImage : Evergreen.V12.ProfileImage.ProfileImage
    , timezone : Time.Zone
    , allowEventReminders : Bool
    }


type alias LoginTokenData =
    { creationTime : Time.Posix
    , emailAddress : EmailAddress.EmailAddress
    }


type alias DeleteUserTokenData =
    { creationTime : Time.Posix
    , userId : Evergreen.V12.Id.Id Evergreen.V12.Id.UserId
    }


type alias BackendModel =
    { users : AssocList.Dict (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) BackendUser
    , groups : AssocList.Dict Evergreen.V12.Id.GroupId Evergreen.V12.Group.Group
    , groupIdCounter : Int
    , sessions : BiDict.Assoc.BiDict Evergreen.V12.Id.SessionId (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId)
    , connections : AssocList.Dict Evergreen.V12.Id.SessionId (List.Nonempty.Nonempty Evergreen.V12.Id.ClientId)
    , logs : Array.Array Log
    , time : Time.Posix
    , secretCounter : Int
    , pendingLoginTokens : AssocList.Dict (Evergreen.V12.Id.Id Evergreen.V12.Id.LoginToken) LoginTokenData
    , pendingDeleteUserTokens : AssocList.Dict (Evergreen.V12.Id.Id Evergreen.V12.Id.DeleteUserToken) DeleteUserTokenData
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Time.Posix
    | PressedLogin
    | PressedLogout
    | TypedEmail String
    | PressedSubmitLogin
    | PressedCancelLogin
    | PressedCreateGroup
    | GroupFormMsg Evergreen.V12.CreateGroupForm.Msg
    | ProfileFormMsg Evergreen.V12.ProfilePage.Msg
    | CroppedImage
        { requestId : Int
        , croppedImageUrl : String
        }
    | TypedSearchText String
    | SubmittedSearchBox
    | GroupPageMsg Evergreen.V12.GroupPage.Msg
    | GotWindowSize (Quantity.Quantity Int Pixels.Pixels) (Quantity.Quantity Int Pixels.Pixels)
    | GotTimeZone (Result TimeZone.Error ( String, Time.Zone ))


type BackendMsg
    = SentLoginEmail EmailAddress.EmailAddress (Result SendGrid.Error ())
    | SentDeleteUserEmail (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) (Result SendGrid.Error ())
    | SentEventReminderEmail (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) Evergreen.V12.Id.GroupId Evergreen.V12.Group.EventId (Result SendGrid.Error ())
    | BackendGotTime Time.Posix
    | Connected Evergreen.V12.Id.SessionId Evergreen.V12.Id.ClientId
    | Disconnected Evergreen.V12.Id.SessionId Evergreen.V12.Id.ClientId


type GroupRequest
    = GroupNotFound_
    | GroupFound_ Evergreen.V12.Group.Group (AssocList.Dict (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) Evergreen.V12.FrontendUser.FrontendUser)


type ToFrontend
    = GetGroupResponse Evergreen.V12.Id.GroupId GroupRequest
    | GetUserResponse (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId) (Result () Evergreen.V12.FrontendUser.FrontendUser)
    | CheckLoginResponse (Maybe ( Evergreen.V12.Id.Id Evergreen.V12.Id.UserId, BackendUser ))
    | LoginWithTokenResponse (Result () ( Evergreen.V12.Id.Id Evergreen.V12.Id.UserId, BackendUser ))
    | GetAdminDataResponse (Array.Array Log)
    | CreateGroupResponse (Result Evergreen.V12.CreateGroupForm.CreateGroupError ( Evergreen.V12.Id.GroupId, Evergreen.V12.Group.Group ))
    | LogoutResponse
    | ChangeNameResponse Evergreen.V12.Name.Name
    | ChangeDescriptionResponse Evergreen.V12.Description.Description
    | ChangeEmailAddressResponse EmailAddress.EmailAddress
    | DeleteUserResponse (Result () ())
    | ChangeProfileImageResponse Evergreen.V12.ProfileImage.ProfileImage
    | GetMyGroupsResponse (List ( Evergreen.V12.Id.GroupId, Evergreen.V12.Group.Group ))
    | SearchGroupsResponse String (List ( Evergreen.V12.Id.GroupId, Evergreen.V12.Group.Group ))
    | ChangeGroupNameResponse Evergreen.V12.Id.GroupId Evergreen.V12.GroupName.GroupName
    | ChangeGroupDescriptionResponse Evergreen.V12.Id.GroupId Evergreen.V12.Description.Description
    | CreateEventResponse Evergreen.V12.Id.GroupId (Result Evergreen.V12.GroupPage.CreateEventError Evergreen.V12.Event.Event)
    | EditEventResponse Evergreen.V12.Id.GroupId Evergreen.V12.Group.EventId (Result Evergreen.V12.Group.EditEventError Evergreen.V12.Event.Event) Time.Posix
    | JoinEventResponse Evergreen.V12.Id.GroupId Evergreen.V12.Group.EventId (Result Evergreen.V12.Group.JoinEventError ())
    | LeaveEventResponse Evergreen.V12.Id.GroupId Evergreen.V12.Group.EventId (Result () ())
    | ChangeEventCancellationStatusResponse Evergreen.V12.Id.GroupId Evergreen.V12.Group.EventId (Result Evergreen.V12.Group.EditCancellationStatusError Evergreen.V12.Event.CancellationStatus) Time.Posix
