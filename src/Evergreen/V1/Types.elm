module Evergreen.V1.Types exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc
import Browser
import Browser.Navigation
import EmailAddress
import Evergreen.V1.CreateGroupForm
import Evergreen.V1.Description
import Evergreen.V1.Event
import Evergreen.V1.EventDuration
import Evergreen.V1.EventName
import Evergreen.V1.FrontendUser
import Evergreen.V1.Group
import Evergreen.V1.GroupName
import Evergreen.V1.GroupPage
import Evergreen.V1.Id
import Evergreen.V1.Name
import Evergreen.V1.ProfileForm
import Evergreen.V1.ProfileImage
import Evergreen.V1.Route
import Evergreen.V1.Untrusted
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
    , route : Evergreen.V1.Route.Route
    , routeToken : Evergreen.V1.Route.Token
    , windowSize : Maybe ( Quantity.Quantity Int Pixels.Pixels, Quantity.Quantity Int Pixels.Pixels )
    , time : Maybe Time.Posix
    , timezone : Maybe Time.Zone
    }


type alias LoggedIn_ =
    { userId : Evergreen.V1.Id.Id Evergreen.V1.Id.UserId
    , emailAddress : EmailAddress.EmailAddress
    , profileForm : Evergreen.V1.ProfileForm.Model
    , myGroups : Maybe (AssocSet.Set Evergreen.V1.Id.GroupId)
    }


type LoginStatus
    = LoginStatusPending
    | LoggedIn LoggedIn_
    | NotLoggedIn
        { showLogin : Bool
        }


type GroupCache
    = GroupNotFound
    | GroupFound Evergreen.V1.Group.Group
    | GroupRequestPending


type alias LoginForm =
    { email : String
    , pressedSubmitEmail : Bool
    , emailSent : Maybe EmailAddress.EmailAddress
    }


type ToBackendRequest
    = GetGroupRequest Evergreen.V1.Id.GroupId
    | CheckLoginRequest
    | LoginWithTokenRequest (Evergreen.V1.Id.Id Evergreen.V1.Id.LoginToken)
    | GetLoginTokenRequest Evergreen.V1.Route.Route (Evergreen.V1.Untrusted.Untrusted EmailAddress.EmailAddress)
    | GetAdminDataRequest
    | LogoutRequest
    | CreateGroupRequest (Evergreen.V1.Untrusted.Untrusted Evergreen.V1.GroupName.GroupName) (Evergreen.V1.Untrusted.Untrusted Evergreen.V1.Description.Description) Evergreen.V1.Group.GroupVisibility
    | ChangeNameRequest (Evergreen.V1.Untrusted.Untrusted Evergreen.V1.Name.Name)
    | ChangeDescriptionRequest (Evergreen.V1.Untrusted.Untrusted Evergreen.V1.Description.Description)
    | ChangeEmailAddressRequest (Evergreen.V1.Untrusted.Untrusted EmailAddress.EmailAddress)
    | SendDeleteUserEmailRequest
    | DeleteUserRequest (Evergreen.V1.Id.Id Evergreen.V1.Id.DeleteUserToken)
    | ChangeProfileImageRequest (Evergreen.V1.Untrusted.Untrusted Evergreen.V1.ProfileImage.ProfileImage)
    | GetMyGroupsRequest
    | SearchGroupsRequest String
    | ChangeGroupNameRequest Evergreen.V1.Id.GroupId (Evergreen.V1.Untrusted.Untrusted Evergreen.V1.GroupName.GroupName)
    | ChangeGroupDescriptionRequest Evergreen.V1.Id.GroupId (Evergreen.V1.Untrusted.Untrusted Evergreen.V1.Description.Description)
    | CreateEventRequest Evergreen.V1.Id.GroupId (Evergreen.V1.Untrusted.Untrusted Evergreen.V1.EventName.EventName) (Evergreen.V1.Untrusted.Untrusted Evergreen.V1.Description.Description) (Evergreen.V1.Untrusted.Untrusted Evergreen.V1.Event.EventType) Time.Posix (Evergreen.V1.Untrusted.Untrusted Evergreen.V1.EventDuration.EventDuration)


type Log
    = UntrustedCheckFailed Time.Posix ToBackendRequest
    | SendGridSendEmail Time.Posix (Result SendGrid.Error ()) EmailAddress.EmailAddress


type alias LoadedFrontend =
    { navigationKey : NavigationKey
    , loginStatus : LoginStatus
    , route : Evergreen.V1.Route.Route
    , cachedGroups : AssocList.Dict Evergreen.V1.Id.GroupId GroupCache
    , cachedUsers : AssocList.Dict (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId) Evergreen.V1.FrontendUser.FrontendUser
    , time : Time.Posix
    , timezone : Time.Zone
    , lastConnectionCheck : Time.Posix
    , loginForm : LoginForm
    , logs : Maybe (Array.Array Log)
    , hasLoginError : Bool
    , groupForm : Evergreen.V1.CreateGroupForm.Model
    , groupCreated : Bool
    , accountDeletedResult : Maybe (Result () ())
    , searchBox : String
    , searchList : List Evergreen.V1.Id.GroupId
    , windowWidth : Quantity.Quantity Int Pixels.Pixels
    , windowHeight : Quantity.Quantity Int Pixels.Pixels
    , groupPage : AssocList.Dict Evergreen.V1.Id.GroupId Evergreen.V1.GroupPage.Model
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias BackendUser =
    { name : Evergreen.V1.Name.Name
    , description : Evergreen.V1.Description.Description
    , emailAddress : EmailAddress.EmailAddress
    , profileImage : Evergreen.V1.ProfileImage.ProfileImage
    }


type alias LoginTokenData =
    { creationTime : Time.Posix
    , emailAddress : EmailAddress.EmailAddress
    }


type alias DeleteUserTokenData =
    { creationTime : Time.Posix
    , userId : Evergreen.V1.Id.Id Evergreen.V1.Id.UserId
    }


type alias BackendModel =
    { users : AssocList.Dict (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId) BackendUser
    , groups : AssocList.Dict Evergreen.V1.Id.GroupId Evergreen.V1.Group.Group
    , groupIdCounter : Int
    , sessions : BiDict.Assoc.BiDict Evergreen.V1.Id.SessionId (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId)
    , connections : AssocList.Dict Evergreen.V1.Id.SessionId (List.Nonempty.Nonempty Evergreen.V1.Id.ClientId)
    , logs : Array.Array Log
    , time : Time.Posix
    , secretCounter : Int
    , pendingLoginTokens : AssocList.Dict (Evergreen.V1.Id.Id Evergreen.V1.Id.LoginToken) LoginTokenData
    , pendingDeleteUserTokens : AssocList.Dict (Evergreen.V1.Id.Id Evergreen.V1.Id.DeleteUserToken) DeleteUserTokenData
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
    | GroupFormMsg Evergreen.V1.CreateGroupForm.Msg
    | ProfileFormMsg Evergreen.V1.ProfileForm.Msg
    | CroppedImage
        { requestId : Int
        , croppedImageUrl : String
        }
    | TypedSearchText String
    | SubmittedSearchBox
    | GroupPageMsg Evergreen.V1.GroupPage.Msg
    | GotWindowSize (Quantity.Quantity Int Pixels.Pixels) (Quantity.Quantity Int Pixels.Pixels)
    | GotTimeZone (Result TimeZone.Error ( String, Time.Zone ))


type ToBackend
    = ToBackend (List.Nonempty.Nonempty ToBackendRequest)


type BackendMsg
    = SentLoginEmail EmailAddress.EmailAddress (Result SendGrid.Error ())
    | SentDeleteUserEmail EmailAddress.EmailAddress (Result SendGrid.Error ())
    | BackendGotTime Time.Posix
    | Connected Evergreen.V1.Id.SessionId Evergreen.V1.Id.ClientId
    | Disconnected Evergreen.V1.Id.SessionId Evergreen.V1.Id.ClientId


type GroupRequest
    = GroupNotFound_
    | GroupFound_ Evergreen.V1.Group.Group (AssocList.Dict (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId) Evergreen.V1.FrontendUser.FrontendUser)


type ToFrontend
    = GetGroupResponse Evergreen.V1.Id.GroupId GroupRequest
    | CheckLoginResponse (Maybe ( Evergreen.V1.Id.Id Evergreen.V1.Id.UserId, BackendUser ))
    | LoginWithTokenResponse (Result () ( Evergreen.V1.Id.Id Evergreen.V1.Id.UserId, BackendUser ))
    | GetAdminDataResponse (Array.Array Log)
    | CreateGroupResponse (Result Evergreen.V1.CreateGroupForm.CreateGroupError ( Evergreen.V1.Id.GroupId, Evergreen.V1.Group.Group ))
    | LogoutResponse
    | ChangeNameResponse Evergreen.V1.Name.Name
    | ChangeDescriptionResponse Evergreen.V1.Description.Description
    | ChangeEmailAddressResponse EmailAddress.EmailAddress
    | DeleteUserResponse (Result () ())
    | ChangeProfileImageResponse Evergreen.V1.ProfileImage.ProfileImage
    | GetMyGroupsResponse (List ( Evergreen.V1.Id.GroupId, Evergreen.V1.Group.Group ))
    | SearchGroupsResponse String (List ( Evergreen.V1.Id.GroupId, Evergreen.V1.Group.Group ))
    | ChangeGroupNameResponse Evergreen.V1.Id.GroupId Evergreen.V1.GroupName.GroupName
    | ChangeGroupDescriptionResponse Evergreen.V1.Id.GroupId Evergreen.V1.Description.Description
    | CreateEventResponse Evergreen.V1.Id.GroupId (Result Evergreen.V1.GroupPage.CreateEventError Evergreen.V1.Event.Event)
