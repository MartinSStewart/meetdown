module Evergreen.V9.Types exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc
import Browser
import Browser.Navigation
import EmailAddress
import Evergreen.V9.CreateGroupForm
import Evergreen.V9.Description
import Evergreen.V9.Event
import Evergreen.V9.EventDuration
import Evergreen.V9.EventName
import Evergreen.V9.FrontendUser
import Evergreen.V9.Group
import Evergreen.V9.GroupName
import Evergreen.V9.GroupPage
import Evergreen.V9.Id
import Evergreen.V9.Name
import Evergreen.V9.ProfileForm
import Evergreen.V9.ProfileImage
import Evergreen.V9.Route
import Evergreen.V9.Untrusted
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
    , route : Evergreen.V9.Route.Route
    , routeToken : Evergreen.V9.Route.Token
    , windowSize : Maybe ( Quantity.Quantity Int Pixels.Pixels, Quantity.Quantity Int Pixels.Pixels )
    , time : Maybe Time.Posix
    , timezone : Maybe Time.Zone
    }


type ToBackend
    = GetGroupRequest Evergreen.V9.Id.GroupId
    | GetUserRequest (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId)
    | CheckLoginRequest
    | LoginWithTokenRequest (Evergreen.V9.Id.Id Evergreen.V9.Id.LoginToken) (Maybe ( Evergreen.V9.Id.GroupId, Evergreen.V9.Group.EventId ))
    | GetLoginTokenRequest Evergreen.V9.Route.Route (Evergreen.V9.Untrusted.Untrusted EmailAddress.EmailAddress) (Maybe ( Evergreen.V9.Id.GroupId, Evergreen.V9.Group.EventId ))
    | GetAdminDataRequest
    | LogoutRequest
    | CreateGroupRequest (Evergreen.V9.Untrusted.Untrusted Evergreen.V9.GroupName.GroupName) (Evergreen.V9.Untrusted.Untrusted Evergreen.V9.Description.Description) Evergreen.V9.Group.GroupVisibility
    | ChangeNameRequest (Evergreen.V9.Untrusted.Untrusted Evergreen.V9.Name.Name)
    | ChangeDescriptionRequest (Evergreen.V9.Untrusted.Untrusted Evergreen.V9.Description.Description)
    | ChangeEmailAddressRequest (Evergreen.V9.Untrusted.Untrusted EmailAddress.EmailAddress)
    | SendDeleteUserEmailRequest
    | DeleteUserRequest (Evergreen.V9.Id.Id Evergreen.V9.Id.DeleteUserToken)
    | ChangeProfileImageRequest (Evergreen.V9.Untrusted.Untrusted Evergreen.V9.ProfileImage.ProfileImage)
    | GetMyGroupsRequest
    | SearchGroupsRequest String
    | ChangeGroupNameRequest Evergreen.V9.Id.GroupId (Evergreen.V9.Untrusted.Untrusted Evergreen.V9.GroupName.GroupName)
    | ChangeGroupDescriptionRequest Evergreen.V9.Id.GroupId (Evergreen.V9.Untrusted.Untrusted Evergreen.V9.Description.Description)
    | CreateEventRequest Evergreen.V9.Id.GroupId (Evergreen.V9.Untrusted.Untrusted Evergreen.V9.EventName.EventName) (Evergreen.V9.Untrusted.Untrusted Evergreen.V9.Description.Description) (Evergreen.V9.Untrusted.Untrusted Evergreen.V9.Event.EventType) Time.Posix (Evergreen.V9.Untrusted.Untrusted Evergreen.V9.EventDuration.EventDuration)
    | EditEventRequest Evergreen.V9.Id.GroupId Evergreen.V9.Group.EventId (Evergreen.V9.Untrusted.Untrusted Evergreen.V9.EventName.EventName) (Evergreen.V9.Untrusted.Untrusted Evergreen.V9.Description.Description) (Evergreen.V9.Untrusted.Untrusted Evergreen.V9.Event.EventType) Time.Posix (Evergreen.V9.Untrusted.Untrusted Evergreen.V9.EventDuration.EventDuration)
    | JoinEventRequest Evergreen.V9.Id.GroupId Evergreen.V9.Group.EventId
    | LeaveEventRequest Evergreen.V9.Id.GroupId Evergreen.V9.Group.EventId
    | ChangeEventCancellationStatusRequest Evergreen.V9.Id.GroupId Evergreen.V9.Group.EventId Evergreen.V9.Event.CancellationStatus


type Log
    = LogUntrustedCheckFailed Time.Posix ToBackend
    | LogLoginEmail Time.Posix (Result SendGrid.Error ()) EmailAddress.EmailAddress
    | LogDeleteAccountEmail Time.Posix (Result SendGrid.Error ()) (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId)
    | LogEventReminderEmail Time.Posix (Result SendGrid.Error ()) (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId) Evergreen.V9.Id.GroupId Evergreen.V9.Group.EventId


type alias AdminModel =
    { cachedEmailAddress : AssocList.Dict (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId) EmailAddress.EmailAddress
    , logs : Array.Array Log
    }


type alias LoggedIn_ =
    { userId : Evergreen.V9.Id.Id Evergreen.V9.Id.UserId
    , emailAddress : EmailAddress.EmailAddress
    , profileForm : Evergreen.V9.ProfileForm.Model
    , myGroups : Maybe (AssocSet.Set Evergreen.V9.Id.GroupId)
    , adminState : Maybe AdminModel
    }


type LoginStatus
    = LoginStatusPending
    | LoggedIn LoggedIn_
    | NotLoggedIn
        { showLogin : Bool
        , joiningEvent : Maybe ( Evergreen.V9.Id.GroupId, Evergreen.V9.Group.EventId )
        }


type GroupCache
    = GroupNotFound
    | GroupFound Evergreen.V9.Group.Group
    | GroupRequestPending


type UserCache
    = UserNotFound
    | UserFound Evergreen.V9.FrontendUser.FrontendUser
    | UserRequestPending


type alias LoginForm =
    { email : String
    , pressedSubmitEmail : Bool
    , emailSent : Maybe EmailAddress.EmailAddress
    }


type alias LoadedFrontend =
    { navigationKey : NavigationKey
    , loginStatus : LoginStatus
    , route : Evergreen.V9.Route.Route
    , cachedGroups : AssocList.Dict Evergreen.V9.Id.GroupId GroupCache
    , cachedUsers : AssocList.Dict (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId) UserCache
    , time : Time.Posix
    , timezone : Time.Zone
    , lastConnectionCheck : Time.Posix
    , loginForm : LoginForm
    , logs : Maybe (Array.Array Log)
    , hasLoginTokenError : Bool
    , groupForm : Evergreen.V9.CreateGroupForm.Model
    , groupCreated : Bool
    , accountDeletedResult : Maybe (Result () ())
    , searchBox : String
    , searchList : List Evergreen.V9.Id.GroupId
    , windowWidth : Quantity.Quantity Int Pixels.Pixels
    , windowHeight : Quantity.Quantity Int Pixels.Pixels
    , groupPage : AssocList.Dict Evergreen.V9.Id.GroupId Evergreen.V9.GroupPage.Model
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias BackendUser =
    { name : Evergreen.V9.Name.Name
    , description : Evergreen.V9.Description.Description
    , emailAddress : EmailAddress.EmailAddress
    , profileImage : Evergreen.V9.ProfileImage.ProfileImage
    , timezone : Time.Zone
    , allowEventReminders : Bool
    }


type alias LoginTokenData =
    { creationTime : Time.Posix
    , emailAddress : EmailAddress.EmailAddress
    }


type alias DeleteUserTokenData =
    { creationTime : Time.Posix
    , userId : Evergreen.V9.Id.Id Evergreen.V9.Id.UserId
    }


type alias BackendModel =
    { users : AssocList.Dict (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId) BackendUser
    , groups : AssocList.Dict Evergreen.V9.Id.GroupId Evergreen.V9.Group.Group
    , groupIdCounter : Int
    , sessions : BiDict.Assoc.BiDict Evergreen.V9.Id.SessionId (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId)
    , connections : AssocList.Dict Evergreen.V9.Id.SessionId (List.Nonempty.Nonempty Evergreen.V9.Id.ClientId)
    , logs : Array.Array Log
    , time : Time.Posix
    , secretCounter : Int
    , pendingLoginTokens : AssocList.Dict (Evergreen.V9.Id.Id Evergreen.V9.Id.LoginToken) LoginTokenData
    , pendingDeleteUserTokens : AssocList.Dict (Evergreen.V9.Id.Id Evergreen.V9.Id.DeleteUserToken) DeleteUserTokenData
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
    | GroupFormMsg Evergreen.V9.CreateGroupForm.Msg
    | ProfileFormMsg Evergreen.V9.ProfileForm.Msg
    | CroppedImage
        { requestId : Int
        , croppedImageUrl : String
        }
    | TypedSearchText String
    | SubmittedSearchBox
    | GroupPageMsg Evergreen.V9.GroupPage.Msg
    | GotWindowSize (Quantity.Quantity Int Pixels.Pixels) (Quantity.Quantity Int Pixels.Pixels)
    | GotTimeZone (Result TimeZone.Error ( String, Time.Zone ))


type BackendMsg
    = SentLoginEmail EmailAddress.EmailAddress (Result SendGrid.Error ())
    | SentDeleteUserEmail (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId) (Result SendGrid.Error ())
    | SentEventReminderEmail (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId) Evergreen.V9.Id.GroupId Evergreen.V9.Group.EventId (Result SendGrid.Error ())
    | BackendGotTime Time.Posix
    | Connected Evergreen.V9.Id.SessionId Evergreen.V9.Id.ClientId
    | Disconnected Evergreen.V9.Id.SessionId Evergreen.V9.Id.ClientId


type GroupRequest
    = GroupNotFound_
    | GroupFound_ Evergreen.V9.Group.Group (AssocList.Dict (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId) Evergreen.V9.FrontendUser.FrontendUser)


type ToFrontend
    = GetGroupResponse Evergreen.V9.Id.GroupId GroupRequest
    | GetUserResponse (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId) (Result () Evergreen.V9.FrontendUser.FrontendUser)
    | CheckLoginResponse (Maybe ( Evergreen.V9.Id.Id Evergreen.V9.Id.UserId, BackendUser ))
    | LoginWithTokenResponse (Result () ( Evergreen.V9.Id.Id Evergreen.V9.Id.UserId, BackendUser ))
    | GetAdminDataResponse (Array.Array Log)
    | CreateGroupResponse (Result Evergreen.V9.CreateGroupForm.CreateGroupError ( Evergreen.V9.Id.GroupId, Evergreen.V9.Group.Group ))
    | LogoutResponse
    | ChangeNameResponse Evergreen.V9.Name.Name
    | ChangeDescriptionResponse Evergreen.V9.Description.Description
    | ChangeEmailAddressResponse EmailAddress.EmailAddress
    | DeleteUserResponse (Result () ())
    | ChangeProfileImageResponse Evergreen.V9.ProfileImage.ProfileImage
    | GetMyGroupsResponse (List ( Evergreen.V9.Id.GroupId, Evergreen.V9.Group.Group ))
    | SearchGroupsResponse String (List ( Evergreen.V9.Id.GroupId, Evergreen.V9.Group.Group ))
    | ChangeGroupNameResponse Evergreen.V9.Id.GroupId Evergreen.V9.GroupName.GroupName
    | ChangeGroupDescriptionResponse Evergreen.V9.Id.GroupId Evergreen.V9.Description.Description
    | CreateEventResponse Evergreen.V9.Id.GroupId (Result Evergreen.V9.GroupPage.CreateEventError Evergreen.V9.Event.Event)
    | EditEventResponse Evergreen.V9.Id.GroupId Evergreen.V9.Group.EventId (Result Evergreen.V9.Group.EditEventError Evergreen.V9.Event.Event) Time.Posix
    | JoinEventResponse Evergreen.V9.Id.GroupId Evergreen.V9.Group.EventId (Result () ())
    | LeaveEventResponse Evergreen.V9.Id.GroupId Evergreen.V9.Group.EventId (Result () ())
    | ChangeEventCancellationStatusResponse Evergreen.V9.Id.GroupId Evergreen.V9.Group.EventId (Result Evergreen.V9.Group.EditCancellationStatusError Evergreen.V9.Event.CancellationStatus) Time.Posix
