module Evergreen.V16.Types exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc
import Browser
import Browser.Navigation
import EmailAddress
import Evergreen.V16.CreateGroupPage
import Evergreen.V16.Description
import Evergreen.V16.Event
import Evergreen.V16.EventDuration
import Evergreen.V16.EventName
import Evergreen.V16.FrontendUser
import Evergreen.V16.Group
import Evergreen.V16.GroupName
import Evergreen.V16.GroupPage
import Evergreen.V16.Id
import Evergreen.V16.MaxAttendees
import Evergreen.V16.Name
import Evergreen.V16.ProfileImage
import Evergreen.V16.ProfilePage
import Evergreen.V16.Route
import Evergreen.V16.Untrusted
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
    , route : Evergreen.V16.Route.Route
    , routeToken : Evergreen.V16.Route.Token
    , windowSize : Maybe ( Quantity.Quantity Int Pixels.Pixels, Quantity.Quantity Int Pixels.Pixels )
    , time : Maybe Time.Posix
    , timezone : Maybe Time.Zone
    }


type ToBackend
    = GetGroupRequest Evergreen.V16.Id.GroupId
    | GetUserRequest (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId)
    | CheckLoginRequest
    | LoginWithTokenRequest (Evergreen.V16.Id.Id Evergreen.V16.Id.LoginToken) (Maybe ( Evergreen.V16.Id.GroupId, Evergreen.V16.Group.EventId ))
    | GetLoginTokenRequest Evergreen.V16.Route.Route (Evergreen.V16.Untrusted.Untrusted EmailAddress.EmailAddress) (Maybe ( Evergreen.V16.Id.GroupId, Evergreen.V16.Group.EventId ))
    | GetAdminDataRequest
    | LogoutRequest
    | CreateGroupRequest (Evergreen.V16.Untrusted.Untrusted Evergreen.V16.GroupName.GroupName) (Evergreen.V16.Untrusted.Untrusted Evergreen.V16.Description.Description) Evergreen.V16.Group.GroupVisibility
    | ChangeNameRequest (Evergreen.V16.Untrusted.Untrusted Evergreen.V16.Name.Name)
    | ChangeDescriptionRequest (Evergreen.V16.Untrusted.Untrusted Evergreen.V16.Description.Description)
    | ChangeEmailAddressRequest (Evergreen.V16.Untrusted.Untrusted EmailAddress.EmailAddress)
    | SendDeleteUserEmailRequest
    | DeleteUserRequest (Evergreen.V16.Id.Id Evergreen.V16.Id.DeleteUserToken)
    | ChangeProfileImageRequest (Evergreen.V16.Untrusted.Untrusted Evergreen.V16.ProfileImage.ProfileImage)
    | GetMyGroupsRequest
    | SearchGroupsRequest String
    | ChangeGroupNameRequest Evergreen.V16.Id.GroupId (Evergreen.V16.Untrusted.Untrusted Evergreen.V16.GroupName.GroupName)
    | ChangeGroupDescriptionRequest Evergreen.V16.Id.GroupId (Evergreen.V16.Untrusted.Untrusted Evergreen.V16.Description.Description)
    | CreateEventRequest Evergreen.V16.Id.GroupId (Evergreen.V16.Untrusted.Untrusted Evergreen.V16.EventName.EventName) (Evergreen.V16.Untrusted.Untrusted Evergreen.V16.Description.Description) (Evergreen.V16.Untrusted.Untrusted Evergreen.V16.Event.EventType) Time.Posix (Evergreen.V16.Untrusted.Untrusted Evergreen.V16.EventDuration.EventDuration) (Evergreen.V16.Untrusted.Untrusted Evergreen.V16.MaxAttendees.MaxAttendees)
    | EditEventRequest Evergreen.V16.Id.GroupId Evergreen.V16.Group.EventId (Evergreen.V16.Untrusted.Untrusted Evergreen.V16.EventName.EventName) (Evergreen.V16.Untrusted.Untrusted Evergreen.V16.Description.Description) (Evergreen.V16.Untrusted.Untrusted Evergreen.V16.Event.EventType) Time.Posix (Evergreen.V16.Untrusted.Untrusted Evergreen.V16.EventDuration.EventDuration) (Evergreen.V16.Untrusted.Untrusted Evergreen.V16.MaxAttendees.MaxAttendees)
    | JoinEventRequest Evergreen.V16.Id.GroupId Evergreen.V16.Group.EventId
    | LeaveEventRequest Evergreen.V16.Id.GroupId Evergreen.V16.Group.EventId
    | ChangeEventCancellationStatusRequest Evergreen.V16.Id.GroupId Evergreen.V16.Group.EventId Evergreen.V16.Event.CancellationStatus


type Log
    = LogUntrustedCheckFailed Time.Posix ToBackend Evergreen.V16.Id.SessionIdFirst4Chars
    | LogLoginEmail Time.Posix (Result SendGrid.Error ()) EmailAddress.EmailAddress
    | LogDeleteAccountEmail Time.Posix (Result SendGrid.Error ()) (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId)
    | LogEventReminderEmail Time.Posix (Result SendGrid.Error ()) (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) Evergreen.V16.Id.GroupId Evergreen.V16.Group.EventId
    | LogLoginTokenEmailRequestRateLimited Time.Posix EmailAddress.EmailAddress Evergreen.V16.Id.SessionIdFirst4Chars
    | LogDeleteAccountEmailRequestRateLimited Time.Posix (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) Evergreen.V16.Id.SessionIdFirst4Chars


type alias AdminModel =
    { cachedEmailAddress : AssocList.Dict (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) EmailAddress.EmailAddress
    , logs : Array.Array Log
    , lastLogCheck : Time.Posix
    }


type AdminCache
    = AdminCacheNotRequested
    | AdminCached AdminModel
    | AdminCachePending


type alias LoggedIn_ =
    { userId : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
    , emailAddress : EmailAddress.EmailAddress
    , profileForm : Evergreen.V16.ProfilePage.Model
    , myGroups : Maybe (AssocSet.Set Evergreen.V16.Id.GroupId)
    , adminState : AdminCache
    , isAdmin : Bool
    }


type LoginStatus
    = LoginStatusPending
    | LoggedIn LoggedIn_
    | NotLoggedIn
        { showLogin : Bool
        , joiningEvent : Maybe ( Evergreen.V16.Id.GroupId, Evergreen.V16.Group.EventId )
        }


type Cache item
    = ItemDoesNotExist
    | ItemCached item
    | ItemRequestPending


type alias LoginForm =
    { email : String
    , pressedSubmitEmail : Bool
    , emailSent : Maybe EmailAddress.EmailAddress
    }


type alias LoadedFrontend =
    { navigationKey : NavigationKey
    , loginStatus : LoginStatus
    , route : Evergreen.V16.Route.Route
    , cachedGroups : AssocList.Dict Evergreen.V16.Id.GroupId (Cache Evergreen.V16.Group.Group)
    , cachedUsers : AssocList.Dict (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) (Cache Evergreen.V16.FrontendUser.FrontendUser)
    , time : Time.Posix
    , timezone : Time.Zone
    , lastConnectionCheck : Time.Posix
    , loginForm : LoginForm
    , logs : Maybe (Array.Array Log)
    , hasLoginTokenError : Bool
    , groupForm : Evergreen.V16.CreateGroupPage.Model
    , groupCreated : Bool
    , accountDeletedResult : Maybe (Result () ())
    , searchText : String
    , searchList : List Evergreen.V16.Id.GroupId
    , windowWidth : Quantity.Quantity Int Pixels.Pixels
    , windowHeight : Quantity.Quantity Int Pixels.Pixels
    , groupPage : AssocList.Dict Evergreen.V16.Id.GroupId Evergreen.V16.GroupPage.Model
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias BackendUser =
    { name : Evergreen.V16.Name.Name
    , description : Evergreen.V16.Description.Description
    , emailAddress : EmailAddress.EmailAddress
    , profileImage : Evergreen.V16.ProfileImage.ProfileImage
    , timezone : Time.Zone
    , allowEventReminders : Bool
    }


type alias LoginTokenData =
    { creationTime : Time.Posix
    , emailAddress : EmailAddress.EmailAddress
    }


type alias DeleteUserTokenData =
    { creationTime : Time.Posix
    , userId : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
    }


type alias BackendModel =
    { users : AssocList.Dict (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) BackendUser
    , groups : AssocList.Dict Evergreen.V16.Id.GroupId Evergreen.V16.Group.Group
    , groupIdCounter : Int
    , sessions : BiDict.Assoc.BiDict Evergreen.V16.Id.SessionId (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId)
    , loginAttempts : AssocList.Dict Evergreen.V16.Id.SessionId (List.Nonempty.Nonempty Time.Posix)
    , connections : AssocList.Dict Evergreen.V16.Id.SessionId (List.Nonempty.Nonempty Evergreen.V16.Id.ClientId)
    , logs : Array.Array Log
    , time : Time.Posix
    , secretCounter : Int
    , pendingLoginTokens : AssocList.Dict (Evergreen.V16.Id.Id Evergreen.V16.Id.LoginToken) LoginTokenData
    , pendingDeleteUserTokens : AssocList.Dict (Evergreen.V16.Id.Id Evergreen.V16.Id.DeleteUserToken) DeleteUserTokenData
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
    | GroupFormMsg Evergreen.V16.CreateGroupPage.Msg
    | ProfileFormMsg Evergreen.V16.ProfilePage.Msg
    | CroppedImage
        { requestId : Int
        , croppedImageUrl : String
        }
    | TypedSearchText String
    | SubmittedSearchBox
    | GroupPageMsg Evergreen.V16.GroupPage.Msg
    | GotWindowSize (Quantity.Quantity Int Pixels.Pixels) (Quantity.Quantity Int Pixels.Pixels)
    | GotTimeZone (Result TimeZone.Error ( String, Time.Zone ))


type BackendMsg
    = SentLoginEmail EmailAddress.EmailAddress (Result SendGrid.Error ())
    | SentDeleteUserEmail (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) (Result SendGrid.Error ())
    | SentEventReminderEmail (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) Evergreen.V16.Id.GroupId Evergreen.V16.Group.EventId (Result SendGrid.Error ())
    | BackendGotTime Time.Posix
    | Connected Evergreen.V16.Id.SessionId Evergreen.V16.Id.ClientId
    | Disconnected Evergreen.V16.Id.SessionId Evergreen.V16.Id.ClientId


type GroupRequest
    = GroupNotFound_
    | GroupFound_ Evergreen.V16.Group.Group (AssocList.Dict (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) Evergreen.V16.FrontendUser.FrontendUser)


type ToFrontend
    = GetGroupResponse Evergreen.V16.Id.GroupId GroupRequest
    | GetUserResponse (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId) (Result () Evergreen.V16.FrontendUser.FrontendUser)
    | CheckLoginResponse
        (Maybe
            { userId : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | LoginWithTokenResponse
        (Result
            ()
            { userId : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | GetAdminDataResponse AdminModel
    | CreateGroupResponse (Result Evergreen.V16.CreateGroupPage.CreateGroupError ( Evergreen.V16.Id.GroupId, Evergreen.V16.Group.Group ))
    | LogoutResponse
    | ChangeNameResponse Evergreen.V16.Name.Name
    | ChangeDescriptionResponse Evergreen.V16.Description.Description
    | ChangeEmailAddressResponse EmailAddress.EmailAddress
    | DeleteUserResponse (Result () ())
    | ChangeProfileImageResponse Evergreen.V16.ProfileImage.ProfileImage
    | GetMyGroupsResponse (List ( Evergreen.V16.Id.GroupId, Evergreen.V16.Group.Group ))
    | SearchGroupsResponse String (List ( Evergreen.V16.Id.GroupId, Evergreen.V16.Group.Group ))
    | ChangeGroupNameResponse Evergreen.V16.Id.GroupId Evergreen.V16.GroupName.GroupName
    | ChangeGroupDescriptionResponse Evergreen.V16.Id.GroupId Evergreen.V16.Description.Description
    | CreateEventResponse Evergreen.V16.Id.GroupId (Result Evergreen.V16.GroupPage.CreateEventError Evergreen.V16.Event.Event)
    | EditEventResponse Evergreen.V16.Id.GroupId Evergreen.V16.Group.EventId (Result Evergreen.V16.Group.EditEventError Evergreen.V16.Event.Event) Time.Posix
    | JoinEventResponse Evergreen.V16.Id.GroupId Evergreen.V16.Group.EventId (Result Evergreen.V16.Group.JoinEventError ())
    | LeaveEventResponse Evergreen.V16.Id.GroupId Evergreen.V16.Group.EventId (Result () ())
    | ChangeEventCancellationStatusResponse Evergreen.V16.Id.GroupId Evergreen.V16.Group.EventId (Result Evergreen.V16.Group.EditCancellationStatusError Evergreen.V16.Event.CancellationStatus) Time.Posix
