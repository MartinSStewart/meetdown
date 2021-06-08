module Evergreen.V6.Types exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc
import Browser
import Browser.Navigation
import EmailAddress
import Evergreen.V6.CreateGroupForm
import Evergreen.V6.Description
import Evergreen.V6.Event
import Evergreen.V6.EventDuration
import Evergreen.V6.EventName
import Evergreen.V6.FrontendUser
import Evergreen.V6.Group
import Evergreen.V6.GroupName
import Evergreen.V6.GroupPage
import Evergreen.V6.Id
import Evergreen.V6.Name
import Evergreen.V6.ProfileForm
import Evergreen.V6.ProfileImage
import Evergreen.V6.Route
import Evergreen.V6.Untrusted
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
    , route : Evergreen.V6.Route.Route
    , routeToken : Evergreen.V6.Route.Token
    , windowSize : Maybe ( Quantity.Quantity Int Pixels.Pixels, Quantity.Quantity Int Pixels.Pixels )
    , time : Maybe Time.Posix
    , timezone : Maybe Time.Zone
    }


type ToBackend
    = GetGroupRequest Evergreen.V6.Id.GroupId
    | GetUserRequest (Evergreen.V6.Id.Id Evergreen.V6.Id.UserId)
    | CheckLoginRequest
    | LoginWithTokenRequest (Evergreen.V6.Id.Id Evergreen.V6.Id.LoginToken)
    | GetLoginTokenRequest Evergreen.V6.Route.Route (Evergreen.V6.Untrusted.Untrusted EmailAddress.EmailAddress)
    | GetAdminDataRequest
    | LogoutRequest
    | CreateGroupRequest (Evergreen.V6.Untrusted.Untrusted Evergreen.V6.GroupName.GroupName) (Evergreen.V6.Untrusted.Untrusted Evergreen.V6.Description.Description) Evergreen.V6.Group.GroupVisibility
    | ChangeNameRequest (Evergreen.V6.Untrusted.Untrusted Evergreen.V6.Name.Name)
    | ChangeDescriptionRequest (Evergreen.V6.Untrusted.Untrusted Evergreen.V6.Description.Description)
    | ChangeEmailAddressRequest (Evergreen.V6.Untrusted.Untrusted EmailAddress.EmailAddress)
    | SendDeleteUserEmailRequest
    | DeleteUserRequest (Evergreen.V6.Id.Id Evergreen.V6.Id.DeleteUserToken)
    | ChangeProfileImageRequest (Evergreen.V6.Untrusted.Untrusted Evergreen.V6.ProfileImage.ProfileImage)
    | GetMyGroupsRequest
    | SearchGroupsRequest String
    | ChangeGroupNameRequest Evergreen.V6.Id.GroupId (Evergreen.V6.Untrusted.Untrusted Evergreen.V6.GroupName.GroupName)
    | ChangeGroupDescriptionRequest Evergreen.V6.Id.GroupId (Evergreen.V6.Untrusted.Untrusted Evergreen.V6.Description.Description)
    | CreateEventRequest Evergreen.V6.Id.GroupId (Evergreen.V6.Untrusted.Untrusted Evergreen.V6.EventName.EventName) (Evergreen.V6.Untrusted.Untrusted Evergreen.V6.Description.Description) (Evergreen.V6.Untrusted.Untrusted Evergreen.V6.Event.EventType) Time.Posix (Evergreen.V6.Untrusted.Untrusted Evergreen.V6.EventDuration.EventDuration)
    | JoinEventRequest Evergreen.V6.Id.GroupId Evergreen.V6.Group.EventId
    | LeaveEventRequest Evergreen.V6.Id.GroupId Evergreen.V6.Group.EventId


type Log
    = LogUntrustedCheckFailed Time.Posix ToBackend
    | LogLoginEmail Time.Posix (Result SendGrid.Error ()) EmailAddress.EmailAddress
    | LogDeleteAccountEmail Time.Posix (Result SendGrid.Error ()) (Evergreen.V6.Id.Id Evergreen.V6.Id.UserId)
    | LogEventReminderEmail Time.Posix (Result SendGrid.Error ()) (Evergreen.V6.Id.Id Evergreen.V6.Id.UserId) Evergreen.V6.Id.GroupId


type alias AdminModel =
    { cachedEmailAddress : AssocList.Dict (Evergreen.V6.Id.Id Evergreen.V6.Id.UserId) EmailAddress.EmailAddress
    , logs : Array.Array Log
    }


type alias LoggedIn_ =
    { userId : Evergreen.V6.Id.Id Evergreen.V6.Id.UserId
    , emailAddress : EmailAddress.EmailAddress
    , profileForm : Evergreen.V6.ProfileForm.Model
    , myGroups : Maybe (AssocSet.Set Evergreen.V6.Id.GroupId)
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
    | GroupFound Evergreen.V6.Group.Group
    | GroupRequestPending


type UserCache
    = UserNotFound
    | UserFound Evergreen.V6.FrontendUser.FrontendUser
    | UserRequestPending


type alias LoginForm =
    { email : String
    , pressedSubmitEmail : Bool
    , emailSent : Maybe EmailAddress.EmailAddress
    }


type alias LoadedFrontend =
    { navigationKey : NavigationKey
    , loginStatus : LoginStatus
    , route : Evergreen.V6.Route.Route
    , cachedGroups : AssocList.Dict Evergreen.V6.Id.GroupId GroupCache
    , cachedUsers : AssocList.Dict (Evergreen.V6.Id.Id Evergreen.V6.Id.UserId) UserCache
    , time : Time.Posix
    , timezone : Time.Zone
    , lastConnectionCheck : Time.Posix
    , loginForm : LoginForm
    , logs : Maybe (Array.Array Log)
    , hasLoginTokenError : Bool
    , groupForm : Evergreen.V6.CreateGroupForm.Model
    , groupCreated : Bool
    , accountDeletedResult : Maybe (Result () ())
    , searchBox : String
    , searchList : List Evergreen.V6.Id.GroupId
    , windowWidth : Quantity.Quantity Int Pixels.Pixels
    , windowHeight : Quantity.Quantity Int Pixels.Pixels
    , groupPage : AssocList.Dict Evergreen.V6.Id.GroupId Evergreen.V6.GroupPage.Model
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias BackendUser =
    { name : Evergreen.V6.Name.Name
    , description : Evergreen.V6.Description.Description
    , emailAddress : EmailAddress.EmailAddress
    , profileImage : Evergreen.V6.ProfileImage.ProfileImage
    , timezone : Time.Zone
    }


type alias LoginTokenData =
    { creationTime : Time.Posix
    , emailAddress : EmailAddress.EmailAddress
    }


type alias DeleteUserTokenData =
    { creationTime : Time.Posix
    , userId : Evergreen.V6.Id.Id Evergreen.V6.Id.UserId
    }


type alias BackendModel =
    { users : AssocList.Dict (Evergreen.V6.Id.Id Evergreen.V6.Id.UserId) BackendUser
    , groups : AssocList.Dict Evergreen.V6.Id.GroupId Evergreen.V6.Group.Group
    , groupIdCounter : Int
    , sessions : BiDict.Assoc.BiDict Evergreen.V6.Id.SessionId (Evergreen.V6.Id.Id Evergreen.V6.Id.UserId)
    , connections : AssocList.Dict Evergreen.V6.Id.SessionId (List.Nonempty.Nonempty Evergreen.V6.Id.ClientId)
    , logs : Array.Array Log
    , time : Time.Posix
    , secretCounter : Int
    , pendingLoginTokens : AssocList.Dict (Evergreen.V6.Id.Id Evergreen.V6.Id.LoginToken) LoginTokenData
    , pendingDeleteUserTokens : AssocList.Dict (Evergreen.V6.Id.Id Evergreen.V6.Id.DeleteUserToken) DeleteUserTokenData
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
    | GroupFormMsg Evergreen.V6.CreateGroupForm.Msg
    | ProfileFormMsg Evergreen.V6.ProfileForm.Msg
    | CroppedImage
        { requestId : Int
        , croppedImageUrl : String
        }
    | TypedSearchText String
    | SubmittedSearchBox
    | GroupPageMsg Evergreen.V6.GroupPage.Msg
    | GotWindowSize (Quantity.Quantity Int Pixels.Pixels) (Quantity.Quantity Int Pixels.Pixels)
    | GotTimeZone (Result TimeZone.Error ( String, Time.Zone ))


type BackendMsg
    = SentLoginEmail EmailAddress.EmailAddress (Result SendGrid.Error ())
    | SentDeleteUserEmail (Evergreen.V6.Id.Id Evergreen.V6.Id.UserId) (Result SendGrid.Error ())
    | SentEventReminderEmail (Evergreen.V6.Id.Id Evergreen.V6.Id.UserId) Evergreen.V6.Id.GroupId Evergreen.V6.Group.EventId (Result SendGrid.Error ())
    | BackendGotTime Time.Posix
    | Connected Evergreen.V6.Id.SessionId Evergreen.V6.Id.ClientId
    | Disconnected Evergreen.V6.Id.SessionId Evergreen.V6.Id.ClientId


type GroupRequest
    = GroupNotFound_
    | GroupFound_ Evergreen.V6.Group.Group (AssocList.Dict (Evergreen.V6.Id.Id Evergreen.V6.Id.UserId) Evergreen.V6.FrontendUser.FrontendUser)


type ToFrontend
    = GetGroupResponse Evergreen.V6.Id.GroupId GroupRequest
    | GetUserResponse (Evergreen.V6.Id.Id Evergreen.V6.Id.UserId) (Result () Evergreen.V6.FrontendUser.FrontendUser)
    | CheckLoginResponse (Maybe ( Evergreen.V6.Id.Id Evergreen.V6.Id.UserId, BackendUser ))
    | LoginWithTokenResponse (Result () ( Evergreen.V6.Id.Id Evergreen.V6.Id.UserId, BackendUser ))
    | GetAdminDataResponse (Array.Array Log)
    | CreateGroupResponse (Result Evergreen.V6.CreateGroupForm.CreateGroupError ( Evergreen.V6.Id.GroupId, Evergreen.V6.Group.Group ))
    | LogoutResponse
    | ChangeNameResponse Evergreen.V6.Name.Name
    | ChangeDescriptionResponse Evergreen.V6.Description.Description
    | ChangeEmailAddressResponse EmailAddress.EmailAddress
    | DeleteUserResponse (Result () ())
    | ChangeProfileImageResponse Evergreen.V6.ProfileImage.ProfileImage
    | GetMyGroupsResponse (List ( Evergreen.V6.Id.GroupId, Evergreen.V6.Group.Group ))
    | SearchGroupsResponse String (List ( Evergreen.V6.Id.GroupId, Evergreen.V6.Group.Group ))
    | ChangeGroupNameResponse Evergreen.V6.Id.GroupId Evergreen.V6.GroupName.GroupName
    | ChangeGroupDescriptionResponse Evergreen.V6.Id.GroupId Evergreen.V6.Description.Description
    | CreateEventResponse Evergreen.V6.Id.GroupId (Result Evergreen.V6.GroupPage.CreateEventError Evergreen.V6.Event.Event)
    | JoinEventResponse Evergreen.V6.Id.GroupId Evergreen.V6.Group.EventId (Result () ())
    | LeaveEventResponse Evergreen.V6.Id.GroupId Evergreen.V6.Group.EventId (Result () ())
