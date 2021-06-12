module Evergreen.V8.Types exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc
import Browser
import Browser.Navigation
import EmailAddress
import Evergreen.V8.CreateGroupForm
import Evergreen.V8.Description
import Evergreen.V8.Event
import Evergreen.V8.EventDuration
import Evergreen.V8.EventName
import Evergreen.V8.FrontendUser
import Evergreen.V8.Group
import Evergreen.V8.GroupName
import Evergreen.V8.GroupPage
import Evergreen.V8.Id
import Evergreen.V8.Name
import Evergreen.V8.ProfileForm
import Evergreen.V8.ProfileImage
import Evergreen.V8.Route
import Evergreen.V8.Untrusted
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
    , route : Evergreen.V8.Route.Route
    , routeToken : Evergreen.V8.Route.Token
    , windowSize : Maybe ( Quantity.Quantity Int Pixels.Pixels, Quantity.Quantity Int Pixels.Pixels )
    , time : Maybe Time.Posix
    , timezone : Maybe Time.Zone
    }


type ToBackend
    = GetGroupRequest Evergreen.V8.Id.GroupId
    | GetUserRequest (Evergreen.V8.Id.Id Evergreen.V8.Id.UserId)
    | CheckLoginRequest
    | LoginWithTokenRequest (Evergreen.V8.Id.Id Evergreen.V8.Id.LoginToken)
    | GetLoginTokenRequest Evergreen.V8.Route.Route (Evergreen.V8.Untrusted.Untrusted EmailAddress.EmailAddress)
    | GetAdminDataRequest
    | LogoutRequest
    | CreateGroupRequest (Evergreen.V8.Untrusted.Untrusted Evergreen.V8.GroupName.GroupName) (Evergreen.V8.Untrusted.Untrusted Evergreen.V8.Description.Description) Evergreen.V8.Group.GroupVisibility
    | ChangeNameRequest (Evergreen.V8.Untrusted.Untrusted Evergreen.V8.Name.Name)
    | ChangeDescriptionRequest (Evergreen.V8.Untrusted.Untrusted Evergreen.V8.Description.Description)
    | ChangeEmailAddressRequest (Evergreen.V8.Untrusted.Untrusted EmailAddress.EmailAddress)
    | SendDeleteUserEmailRequest
    | DeleteUserRequest (Evergreen.V8.Id.Id Evergreen.V8.Id.DeleteUserToken)
    | ChangeProfileImageRequest (Evergreen.V8.Untrusted.Untrusted Evergreen.V8.ProfileImage.ProfileImage)
    | GetMyGroupsRequest
    | SearchGroupsRequest String
    | ChangeGroupNameRequest Evergreen.V8.Id.GroupId (Evergreen.V8.Untrusted.Untrusted Evergreen.V8.GroupName.GroupName)
    | ChangeGroupDescriptionRequest Evergreen.V8.Id.GroupId (Evergreen.V8.Untrusted.Untrusted Evergreen.V8.Description.Description)
    | CreateEventRequest Evergreen.V8.Id.GroupId (Evergreen.V8.Untrusted.Untrusted Evergreen.V8.EventName.EventName) (Evergreen.V8.Untrusted.Untrusted Evergreen.V8.Description.Description) (Evergreen.V8.Untrusted.Untrusted Evergreen.V8.Event.EventType) Time.Posix (Evergreen.V8.Untrusted.Untrusted Evergreen.V8.EventDuration.EventDuration)
    | EditEventRequest Evergreen.V8.Id.GroupId Evergreen.V8.Group.EventId (Evergreen.V8.Untrusted.Untrusted Evergreen.V8.EventName.EventName) (Evergreen.V8.Untrusted.Untrusted Evergreen.V8.Description.Description) (Evergreen.V8.Untrusted.Untrusted Evergreen.V8.Event.EventType) Time.Posix (Evergreen.V8.Untrusted.Untrusted Evergreen.V8.EventDuration.EventDuration)
    | JoinEventRequest Evergreen.V8.Id.GroupId Evergreen.V8.Group.EventId
    | LeaveEventRequest Evergreen.V8.Id.GroupId Evergreen.V8.Group.EventId


type Log
    = LogUntrustedCheckFailed Time.Posix ToBackend
    | LogLoginEmail Time.Posix (Result SendGrid.Error ()) EmailAddress.EmailAddress
    | LogDeleteAccountEmail Time.Posix (Result SendGrid.Error ()) (Evergreen.V8.Id.Id Evergreen.V8.Id.UserId)
    | LogEventReminderEmail Time.Posix (Result SendGrid.Error ()) (Evergreen.V8.Id.Id Evergreen.V8.Id.UserId) Evergreen.V8.Id.GroupId Evergreen.V8.Group.EventId


type alias AdminModel =
    { cachedEmailAddress : AssocList.Dict (Evergreen.V8.Id.Id Evergreen.V8.Id.UserId) EmailAddress.EmailAddress
    , logs : Array.Array Log
    }


type alias LoggedIn_ =
    { userId : Evergreen.V8.Id.Id Evergreen.V8.Id.UserId
    , emailAddress : EmailAddress.EmailAddress
    , profileForm : Evergreen.V8.ProfileForm.Model
    , myGroups : Maybe (AssocSet.Set Evergreen.V8.Id.GroupId)
    , adminState : Maybe AdminModel
    }


type LoginStatus
    = LoginStatusPending
    | LoggedIn LoggedIn_
    | NotLoggedIn
        { showLogin : Bool
        }


type GroupCache
    = GroupNotFound
    | GroupFound Evergreen.V8.Group.Group
    | GroupRequestPending


type UserCache
    = UserNotFound
    | UserFound Evergreen.V8.FrontendUser.FrontendUser
    | UserRequestPending


type alias LoginForm =
    { email : String
    , pressedSubmitEmail : Bool
    , emailSent : Maybe EmailAddress.EmailAddress
    }


type alias LoadedFrontend =
    { navigationKey : NavigationKey
    , loginStatus : LoginStatus
    , route : Evergreen.V8.Route.Route
    , cachedGroups : AssocList.Dict Evergreen.V8.Id.GroupId GroupCache
    , cachedUsers : AssocList.Dict (Evergreen.V8.Id.Id Evergreen.V8.Id.UserId) UserCache
    , time : Time.Posix
    , timezone : Time.Zone
    , lastConnectionCheck : Time.Posix
    , loginForm : LoginForm
    , logs : Maybe (Array.Array Log)
    , hasLoginTokenError : Bool
    , groupForm : Evergreen.V8.CreateGroupForm.Model
    , groupCreated : Bool
    , accountDeletedResult : Maybe (Result () ())
    , searchBox : String
    , searchList : List Evergreen.V8.Id.GroupId
    , windowWidth : Quantity.Quantity Int Pixels.Pixels
    , windowHeight : Quantity.Quantity Int Pixels.Pixels
    , groupPage : AssocList.Dict Evergreen.V8.Id.GroupId Evergreen.V8.GroupPage.Model
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias BackendUser =
    { name : Evergreen.V8.Name.Name
    , description : Evergreen.V8.Description.Description
    , emailAddress : EmailAddress.EmailAddress
    , profileImage : Evergreen.V8.ProfileImage.ProfileImage
    , timezone : Time.Zone
    , allowEventReminders : Bool
    }


type alias LoginTokenData =
    { creationTime : Time.Posix
    , emailAddress : EmailAddress.EmailAddress
    }


type alias DeleteUserTokenData =
    { creationTime : Time.Posix
    , userId : Evergreen.V8.Id.Id Evergreen.V8.Id.UserId
    }


type alias BackendModel =
    { users : AssocList.Dict (Evergreen.V8.Id.Id Evergreen.V8.Id.UserId) BackendUser
    , groups : AssocList.Dict Evergreen.V8.Id.GroupId Evergreen.V8.Group.Group
    , groupIdCounter : Int
    , sessions : BiDict.Assoc.BiDict Evergreen.V8.Id.SessionId (Evergreen.V8.Id.Id Evergreen.V8.Id.UserId)
    , connections : AssocList.Dict Evergreen.V8.Id.SessionId (List.Nonempty.Nonempty Evergreen.V8.Id.ClientId)
    , logs : Array.Array Log
    , time : Time.Posix
    , secretCounter : Int
    , pendingLoginTokens : AssocList.Dict (Evergreen.V8.Id.Id Evergreen.V8.Id.LoginToken) LoginTokenData
    , pendingDeleteUserTokens : AssocList.Dict (Evergreen.V8.Id.Id Evergreen.V8.Id.DeleteUserToken) DeleteUserTokenData
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Time.Posix
    | PressedLogin
    | PressedLogout
    | TypedEmail String
    | PressedSubmitEmail
    | PressedCreateGroup
    | GroupFormMsg Evergreen.V8.CreateGroupForm.Msg
    | ProfileFormMsg Evergreen.V8.ProfileForm.Msg
    | CroppedImage
        { requestId : Int
        , croppedImageUrl : String
        }
    | TypedSearchText String
    | SubmittedSearchBox
    | GroupPageMsg Evergreen.V8.GroupPage.Msg
    | GotWindowSize (Quantity.Quantity Int Pixels.Pixels) (Quantity.Quantity Int Pixels.Pixels)
    | GotTimeZone (Result TimeZone.Error ( String, Time.Zone ))


type BackendMsg
    = SentLoginEmail EmailAddress.EmailAddress (Result SendGrid.Error ())
    | SentDeleteUserEmail (Evergreen.V8.Id.Id Evergreen.V8.Id.UserId) (Result SendGrid.Error ())
    | SentEventReminderEmail (Evergreen.V8.Id.Id Evergreen.V8.Id.UserId) Evergreen.V8.Id.GroupId Evergreen.V8.Group.EventId (Result SendGrid.Error ())
    | BackendGotTime Time.Posix
    | Connected Evergreen.V8.Id.SessionId Evergreen.V8.Id.ClientId
    | Disconnected Evergreen.V8.Id.SessionId Evergreen.V8.Id.ClientId


type GroupRequest
    = GroupNotFound_
    | GroupFound_ Evergreen.V8.Group.Group (AssocList.Dict (Evergreen.V8.Id.Id Evergreen.V8.Id.UserId) Evergreen.V8.FrontendUser.FrontendUser)


type ToFrontend
    = GetGroupResponse Evergreen.V8.Id.GroupId GroupRequest
    | GetUserResponse (Evergreen.V8.Id.Id Evergreen.V8.Id.UserId) (Result () Evergreen.V8.FrontendUser.FrontendUser)
    | CheckLoginResponse (Maybe ( Evergreen.V8.Id.Id Evergreen.V8.Id.UserId, BackendUser ))
    | LoginWithTokenResponse (Result () ( Evergreen.V8.Id.Id Evergreen.V8.Id.UserId, BackendUser ))
    | GetAdminDataResponse (Array.Array Log)
    | CreateGroupResponse (Result Evergreen.V8.CreateGroupForm.CreateGroupError ( Evergreen.V8.Id.GroupId, Evergreen.V8.Group.Group ))
    | LogoutResponse
    | ChangeNameResponse Evergreen.V8.Name.Name
    | ChangeDescriptionResponse Evergreen.V8.Description.Description
    | ChangeEmailAddressResponse EmailAddress.EmailAddress
    | DeleteUserResponse (Result () ())
    | ChangeProfileImageResponse Evergreen.V8.ProfileImage.ProfileImage
    | GetMyGroupsResponse (List ( Evergreen.V8.Id.GroupId, Evergreen.V8.Group.Group ))
    | SearchGroupsResponse String (List ( Evergreen.V8.Id.GroupId, Evergreen.V8.Group.Group ))
    | ChangeGroupNameResponse Evergreen.V8.Id.GroupId Evergreen.V8.GroupName.GroupName
    | ChangeGroupDescriptionResponse Evergreen.V8.Id.GroupId Evergreen.V8.Description.Description
    | CreateEventResponse Evergreen.V8.Id.GroupId (Result Evergreen.V8.GroupPage.CreateEventError Evergreen.V8.Event.Event)
    | EditEventResponse Evergreen.V8.Id.GroupId Evergreen.V8.Group.EventId (Result Evergreen.V8.Group.EditEventError Evergreen.V8.Event.Event) Time.Posix
    | JoinEventResponse Evergreen.V8.Id.GroupId Evergreen.V8.Group.EventId (Result () ())
    | LeaveEventResponse Evergreen.V8.Id.GroupId Evergreen.V8.Group.EventId (Result () ())
