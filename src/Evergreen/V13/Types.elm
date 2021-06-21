module Evergreen.V13.Types exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc
import Browser
import Browser.Navigation
import EmailAddress
import Evergreen.V13.CreateGroupPage
import Evergreen.V13.Description
import Evergreen.V13.Event
import Evergreen.V13.EventDuration
import Evergreen.V13.EventName
import Evergreen.V13.FrontendUser
import Evergreen.V13.Group
import Evergreen.V13.GroupName
import Evergreen.V13.GroupPage
import Evergreen.V13.Id
import Evergreen.V13.MaxAttendees
import Evergreen.V13.Name
import Evergreen.V13.ProfileImage
import Evergreen.V13.ProfilePage
import Evergreen.V13.Route
import Evergreen.V13.Untrusted
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
    , route : Evergreen.V13.Route.Route
    , routeToken : Evergreen.V13.Route.Token
    , windowSize : Maybe ( Quantity.Quantity Int Pixels.Pixels, Quantity.Quantity Int Pixels.Pixels )
    , time : Maybe Time.Posix
    , timezone : Maybe Time.Zone
    }


type ToBackend
    = GetGroupRequest Evergreen.V13.Id.GroupId
    | GetUserRequest (Evergreen.V13.Id.Id Evergreen.V13.Id.UserId)
    | CheckLoginRequest
    | LoginWithTokenRequest (Evergreen.V13.Id.Id Evergreen.V13.Id.LoginToken) (Maybe ( Evergreen.V13.Id.GroupId, Evergreen.V13.Group.EventId ))
    | GetLoginTokenRequest Evergreen.V13.Route.Route (Evergreen.V13.Untrusted.Untrusted EmailAddress.EmailAddress) (Maybe ( Evergreen.V13.Id.GroupId, Evergreen.V13.Group.EventId ))
    | GetAdminDataRequest
    | LogoutRequest
    | CreateGroupRequest (Evergreen.V13.Untrusted.Untrusted Evergreen.V13.GroupName.GroupName) (Evergreen.V13.Untrusted.Untrusted Evergreen.V13.Description.Description) Evergreen.V13.Group.GroupVisibility
    | ChangeNameRequest (Evergreen.V13.Untrusted.Untrusted Evergreen.V13.Name.Name)
    | ChangeDescriptionRequest (Evergreen.V13.Untrusted.Untrusted Evergreen.V13.Description.Description)
    | ChangeEmailAddressRequest (Evergreen.V13.Untrusted.Untrusted EmailAddress.EmailAddress)
    | SendDeleteUserEmailRequest
    | DeleteUserRequest (Evergreen.V13.Id.Id Evergreen.V13.Id.DeleteUserToken)
    | ChangeProfileImageRequest (Evergreen.V13.Untrusted.Untrusted Evergreen.V13.ProfileImage.ProfileImage)
    | GetMyGroupsRequest
    | SearchGroupsRequest String
    | ChangeGroupNameRequest Evergreen.V13.Id.GroupId (Evergreen.V13.Untrusted.Untrusted Evergreen.V13.GroupName.GroupName)
    | ChangeGroupDescriptionRequest Evergreen.V13.Id.GroupId (Evergreen.V13.Untrusted.Untrusted Evergreen.V13.Description.Description)
    | CreateEventRequest Evergreen.V13.Id.GroupId (Evergreen.V13.Untrusted.Untrusted Evergreen.V13.EventName.EventName) (Evergreen.V13.Untrusted.Untrusted Evergreen.V13.Description.Description) (Evergreen.V13.Untrusted.Untrusted Evergreen.V13.Event.EventType) Time.Posix (Evergreen.V13.Untrusted.Untrusted Evergreen.V13.EventDuration.EventDuration) (Evergreen.V13.Untrusted.Untrusted Evergreen.V13.MaxAttendees.MaxAttendees)
    | EditEventRequest Evergreen.V13.Id.GroupId Evergreen.V13.Group.EventId (Evergreen.V13.Untrusted.Untrusted Evergreen.V13.EventName.EventName) (Evergreen.V13.Untrusted.Untrusted Evergreen.V13.Description.Description) (Evergreen.V13.Untrusted.Untrusted Evergreen.V13.Event.EventType) Time.Posix (Evergreen.V13.Untrusted.Untrusted Evergreen.V13.EventDuration.EventDuration) (Evergreen.V13.Untrusted.Untrusted Evergreen.V13.MaxAttendees.MaxAttendees)
    | JoinEventRequest Evergreen.V13.Id.GroupId Evergreen.V13.Group.EventId
    | LeaveEventRequest Evergreen.V13.Id.GroupId Evergreen.V13.Group.EventId
    | ChangeEventCancellationStatusRequest Evergreen.V13.Id.GroupId Evergreen.V13.Group.EventId Evergreen.V13.Event.CancellationStatus


type Log
    = LogUntrustedCheckFailed Time.Posix ToBackend Evergreen.V13.Id.SessionIdLast4Chars
    | LogLoginEmail Time.Posix (Result SendGrid.Error ()) EmailAddress.EmailAddress
    | LogDeleteAccountEmail Time.Posix (Result SendGrid.Error ()) (Evergreen.V13.Id.Id Evergreen.V13.Id.UserId)
    | LogEventReminderEmail Time.Posix (Result SendGrid.Error ()) (Evergreen.V13.Id.Id Evergreen.V13.Id.UserId) Evergreen.V13.Id.GroupId Evergreen.V13.Group.EventId
    | LogLoginTokenRequestRateLimited Time.Posix EmailAddress.EmailAddress Evergreen.V13.Id.SessionIdLast4Chars


type alias AdminModel =
    { cachedEmailAddress : AssocList.Dict (Evergreen.V13.Id.Id Evergreen.V13.Id.UserId) EmailAddress.EmailAddress
    , logs : Array.Array Log
    }


type alias LoggedIn_ =
    { userId : Evergreen.V13.Id.Id Evergreen.V13.Id.UserId
    , emailAddress : EmailAddress.EmailAddress
    , profileForm : Evergreen.V13.ProfilePage.Model
    , myGroups : Maybe (AssocSet.Set Evergreen.V13.Id.GroupId)
    , adminState : Maybe AdminModel
    }


type LoginStatus
    = LoginStatusPending
    | LoggedIn LoggedIn_
    | NotLoggedIn
        { showLogin : Bool
        , joiningEvent : Maybe ( Evergreen.V13.Id.GroupId, Evergreen.V13.Group.EventId )
        }


type GroupCache
    = GroupNotFound
    | GroupFound Evergreen.V13.Group.Group
    | GroupRequestPending


type UserCache
    = UserNotFound
    | UserFound Evergreen.V13.FrontendUser.FrontendUser
    | UserRequestPending


type alias LoginForm =
    { email : String
    , pressedSubmitEmail : Bool
    , emailSent : Maybe EmailAddress.EmailAddress
    }


type alias LoadedFrontend =
    { navigationKey : NavigationKey
    , loginStatus : LoginStatus
    , route : Evergreen.V13.Route.Route
    , cachedGroups : AssocList.Dict Evergreen.V13.Id.GroupId GroupCache
    , cachedUsers : AssocList.Dict (Evergreen.V13.Id.Id Evergreen.V13.Id.UserId) UserCache
    , time : Time.Posix
    , timezone : Time.Zone
    , lastConnectionCheck : Time.Posix
    , loginForm : LoginForm
    , logs : Maybe (Array.Array Log)
    , hasLoginTokenError : Bool
    , groupForm : Evergreen.V13.CreateGroupPage.Model
    , groupCreated : Bool
    , accountDeletedResult : Maybe (Result () ())
    , searchText : String
    , searchList : List Evergreen.V13.Id.GroupId
    , windowWidth : Quantity.Quantity Int Pixels.Pixels
    , windowHeight : Quantity.Quantity Int Pixels.Pixels
    , groupPage : AssocList.Dict Evergreen.V13.Id.GroupId Evergreen.V13.GroupPage.Model
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias BackendUser =
    { name : Evergreen.V13.Name.Name
    , description : Evergreen.V13.Description.Description
    , emailAddress : EmailAddress.EmailAddress
    , profileImage : Evergreen.V13.ProfileImage.ProfileImage
    , timezone : Time.Zone
    , allowEventReminders : Bool
    }


type alias LoginTokenData =
    { creationTime : Time.Posix
    , emailAddress : EmailAddress.EmailAddress
    }


type alias DeleteUserTokenData =
    { creationTime : Time.Posix
    , userId : Evergreen.V13.Id.Id Evergreen.V13.Id.UserId
    }


type alias BackendModel =
    { users : AssocList.Dict (Evergreen.V13.Id.Id Evergreen.V13.Id.UserId) BackendUser
    , groups : AssocList.Dict Evergreen.V13.Id.GroupId Evergreen.V13.Group.Group
    , groupIdCounter : Int
    , sessions : BiDict.Assoc.BiDict Evergreen.V13.Id.SessionId (Evergreen.V13.Id.Id Evergreen.V13.Id.UserId)
    , loginAttempts : AssocList.Dict Evergreen.V13.Id.SessionId (List.Nonempty.Nonempty Time.Posix)
    , connections : AssocList.Dict Evergreen.V13.Id.SessionId (List.Nonempty.Nonempty Evergreen.V13.Id.ClientId)
    , logs : Array.Array Log
    , time : Time.Posix
    , secretCounter : Int
    , pendingLoginTokens : AssocList.Dict (Evergreen.V13.Id.Id Evergreen.V13.Id.LoginToken) LoginTokenData
    , pendingDeleteUserTokens : AssocList.Dict (Evergreen.V13.Id.Id Evergreen.V13.Id.DeleteUserToken) DeleteUserTokenData
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
    | GroupFormMsg Evergreen.V13.CreateGroupPage.Msg
    | ProfileFormMsg Evergreen.V13.ProfilePage.Msg
    | CroppedImage
        { requestId : Int
        , croppedImageUrl : String
        }
    | TypedSearchText String
    | SubmittedSearchBox
    | GroupPageMsg Evergreen.V13.GroupPage.Msg
    | GotWindowSize (Quantity.Quantity Int Pixels.Pixels) (Quantity.Quantity Int Pixels.Pixels)
    | GotTimeZone (Result TimeZone.Error ( String, Time.Zone ))


type BackendMsg
    = SentLoginEmail EmailAddress.EmailAddress (Result SendGrid.Error ())
    | SentDeleteUserEmail (Evergreen.V13.Id.Id Evergreen.V13.Id.UserId) (Result SendGrid.Error ())
    | SentEventReminderEmail (Evergreen.V13.Id.Id Evergreen.V13.Id.UserId) Evergreen.V13.Id.GroupId Evergreen.V13.Group.EventId (Result SendGrid.Error ())
    | BackendGotTime Time.Posix
    | Connected Evergreen.V13.Id.SessionId Evergreen.V13.Id.ClientId
    | Disconnected Evergreen.V13.Id.SessionId Evergreen.V13.Id.ClientId


type GroupRequest
    = GroupNotFound_
    | GroupFound_ Evergreen.V13.Group.Group (AssocList.Dict (Evergreen.V13.Id.Id Evergreen.V13.Id.UserId) Evergreen.V13.FrontendUser.FrontendUser)


type ToFrontend
    = GetGroupResponse Evergreen.V13.Id.GroupId GroupRequest
    | GetUserResponse (Evergreen.V13.Id.Id Evergreen.V13.Id.UserId) (Result () Evergreen.V13.FrontendUser.FrontendUser)
    | CheckLoginResponse (Maybe ( Evergreen.V13.Id.Id Evergreen.V13.Id.UserId, BackendUser ))
    | LoginWithTokenResponse (Result () ( Evergreen.V13.Id.Id Evergreen.V13.Id.UserId, BackendUser ))
    | GetAdminDataResponse (Array.Array Log)
    | CreateGroupResponse (Result Evergreen.V13.CreateGroupPage.CreateGroupError ( Evergreen.V13.Id.GroupId, Evergreen.V13.Group.Group ))
    | LogoutResponse
    | ChangeNameResponse Evergreen.V13.Name.Name
    | ChangeDescriptionResponse Evergreen.V13.Description.Description
    | ChangeEmailAddressResponse EmailAddress.EmailAddress
    | DeleteUserResponse (Result () ())
    | ChangeProfileImageResponse Evergreen.V13.ProfileImage.ProfileImage
    | GetMyGroupsResponse (List ( Evergreen.V13.Id.GroupId, Evergreen.V13.Group.Group ))
    | SearchGroupsResponse String (List ( Evergreen.V13.Id.GroupId, Evergreen.V13.Group.Group ))
    | ChangeGroupNameResponse Evergreen.V13.Id.GroupId Evergreen.V13.GroupName.GroupName
    | ChangeGroupDescriptionResponse Evergreen.V13.Id.GroupId Evergreen.V13.Description.Description
    | CreateEventResponse Evergreen.V13.Id.GroupId (Result Evergreen.V13.GroupPage.CreateEventError Evergreen.V13.Event.Event)
    | EditEventResponse Evergreen.V13.Id.GroupId Evergreen.V13.Group.EventId (Result Evergreen.V13.Group.EditEventError Evergreen.V13.Event.Event) Time.Posix
    | JoinEventResponse Evergreen.V13.Id.GroupId Evergreen.V13.Group.EventId (Result Evergreen.V13.Group.JoinEventError ())
    | LeaveEventResponse Evergreen.V13.Id.GroupId Evergreen.V13.Group.EventId (Result () ())
    | ChangeEventCancellationStatusResponse Evergreen.V13.Id.GroupId Evergreen.V13.Group.EventId (Result Evergreen.V13.Group.EditCancellationStatusError Evergreen.V13.Event.CancellationStatus) Time.Posix
