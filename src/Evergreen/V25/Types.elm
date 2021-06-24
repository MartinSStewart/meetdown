module Evergreen.V25.Types exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc
import Browser
import Browser.Navigation
import EmailAddress
import Evergreen.V25.CreateGroupPage
import Evergreen.V25.Description
import Evergreen.V25.Event
import Evergreen.V25.EventDuration
import Evergreen.V25.EventName
import Evergreen.V25.FrontendUser
import Evergreen.V25.Group
import Evergreen.V25.GroupName
import Evergreen.V25.GroupPage
import Evergreen.V25.Id
import Evergreen.V25.MaxAttendees
import Evergreen.V25.Name
import Evergreen.V25.ProfileImage
import Evergreen.V25.ProfilePage
import Evergreen.V25.Route
import Evergreen.V25.Untrusted
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
    , route : Evergreen.V25.Route.Route
    , routeToken : Evergreen.V25.Route.Token
    , windowSize : Maybe ( Quantity.Quantity Int Pixels.Pixels, Quantity.Quantity Int Pixels.Pixels )
    , time : Maybe Time.Posix
    , timezone : Maybe Time.Zone
    }


type ToBackend
    = GetGroupRequest Evergreen.V25.Id.GroupId
    | GetUserRequest (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId)
    | CheckLoginRequest
    | LoginWithTokenRequest (Evergreen.V25.Id.Id Evergreen.V25.Id.LoginToken) (Maybe ( Evergreen.V25.Id.GroupId, Evergreen.V25.Group.EventId ))
    | GetLoginTokenRequest Evergreen.V25.Route.Route (Evergreen.V25.Untrusted.Untrusted EmailAddress.EmailAddress) (Maybe ( Evergreen.V25.Id.GroupId, Evergreen.V25.Group.EventId ))
    | GetAdminDataRequest
    | LogoutRequest
    | CreateGroupRequest (Evergreen.V25.Untrusted.Untrusted Evergreen.V25.GroupName.GroupName) (Evergreen.V25.Untrusted.Untrusted Evergreen.V25.Description.Description) Evergreen.V25.Group.GroupVisibility
    | ChangeNameRequest (Evergreen.V25.Untrusted.Untrusted Evergreen.V25.Name.Name)
    | ChangeDescriptionRequest (Evergreen.V25.Untrusted.Untrusted Evergreen.V25.Description.Description)
    | ChangeEmailAddressRequest (Evergreen.V25.Untrusted.Untrusted EmailAddress.EmailAddress)
    | SendDeleteUserEmailRequest
    | DeleteUserRequest (Evergreen.V25.Id.Id Evergreen.V25.Id.DeleteUserToken)
    | ChangeProfileImageRequest (Evergreen.V25.Untrusted.Untrusted Evergreen.V25.ProfileImage.ProfileImage)
    | GetMyGroupsRequest
    | SearchGroupsRequest String
    | ChangeGroupNameRequest Evergreen.V25.Id.GroupId (Evergreen.V25.Untrusted.Untrusted Evergreen.V25.GroupName.GroupName)
    | ChangeGroupDescriptionRequest Evergreen.V25.Id.GroupId (Evergreen.V25.Untrusted.Untrusted Evergreen.V25.Description.Description)
    | CreateEventRequest Evergreen.V25.Id.GroupId (Evergreen.V25.Untrusted.Untrusted Evergreen.V25.EventName.EventName) (Evergreen.V25.Untrusted.Untrusted Evergreen.V25.Description.Description) (Evergreen.V25.Untrusted.Untrusted Evergreen.V25.Event.EventType) Time.Posix (Evergreen.V25.Untrusted.Untrusted Evergreen.V25.EventDuration.EventDuration) (Evergreen.V25.Untrusted.Untrusted Evergreen.V25.MaxAttendees.MaxAttendees)
    | EditEventRequest Evergreen.V25.Id.GroupId Evergreen.V25.Group.EventId (Evergreen.V25.Untrusted.Untrusted Evergreen.V25.EventName.EventName) (Evergreen.V25.Untrusted.Untrusted Evergreen.V25.Description.Description) (Evergreen.V25.Untrusted.Untrusted Evergreen.V25.Event.EventType) Time.Posix (Evergreen.V25.Untrusted.Untrusted Evergreen.V25.EventDuration.EventDuration) (Evergreen.V25.Untrusted.Untrusted Evergreen.V25.MaxAttendees.MaxAttendees)
    | JoinEventRequest Evergreen.V25.Id.GroupId Evergreen.V25.Group.EventId
    | LeaveEventRequest Evergreen.V25.Id.GroupId Evergreen.V25.Group.EventId
    | ChangeEventCancellationStatusRequest Evergreen.V25.Id.GroupId Evergreen.V25.Group.EventId Evergreen.V25.Event.CancellationStatus


type Log
    = LogUntrustedCheckFailed Time.Posix ToBackend Evergreen.V25.Id.SessionIdFirst4Chars
    | LogLoginEmail Time.Posix (Result SendGrid.Error ()) EmailAddress.EmailAddress
    | LogDeleteAccountEmail Time.Posix (Result SendGrid.Error ()) (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId)
    | LogEventReminderEmail Time.Posix (Result SendGrid.Error ()) (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) Evergreen.V25.Id.GroupId Evergreen.V25.Group.EventId
    | LogLoginTokenEmailRequestRateLimited Time.Posix EmailAddress.EmailAddress Evergreen.V25.Id.SessionIdFirst4Chars
    | LogDeleteAccountEmailRequestRateLimited Time.Posix (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) Evergreen.V25.Id.SessionIdFirst4Chars


type alias AdminModel =
    { cachedEmailAddress : AssocList.Dict (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) EmailAddress.EmailAddress
    , logs : Array.Array Log
    , lastLogCheck : Time.Posix
    }


type AdminCache
    = AdminCacheNotRequested
    | AdminCached AdminModel
    | AdminCachePending


type alias LoggedIn_ =
    { userId : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
    , emailAddress : EmailAddress.EmailAddress
    , profileForm : Evergreen.V25.ProfilePage.Model
    , myGroups : Maybe (AssocSet.Set Evergreen.V25.Id.GroupId)
    , adminState : AdminCache
    , isAdmin : Bool
    }


type LoginStatus
    = LoginStatusPending
    | LoggedIn LoggedIn_
    | NotLoggedIn
        { showLogin : Bool
        , joiningEvent : Maybe ( Evergreen.V25.Id.GroupId, Evergreen.V25.Group.EventId )
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
    , route : Evergreen.V25.Route.Route
    , cachedGroups : AssocList.Dict Evergreen.V25.Id.GroupId (Cache Evergreen.V25.Group.Group)
    , cachedUsers : AssocList.Dict (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) (Cache Evergreen.V25.FrontendUser.FrontendUser)
    , time : Time.Posix
    , timezone : Time.Zone
    , lastConnectionCheck : Time.Posix
    , loginForm : LoginForm
    , logs : Maybe (Array.Array Log)
    , hasLoginTokenError : Bool
    , groupForm : Evergreen.V25.CreateGroupPage.Model
    , groupCreated : Bool
    , accountDeletedResult : Maybe (Result () ())
    , searchText : String
    , searchList : List Evergreen.V25.Id.GroupId
    , windowWidth : Quantity.Quantity Int Pixels.Pixels
    , windowHeight : Quantity.Quantity Int Pixels.Pixels
    , groupPage : AssocList.Dict Evergreen.V25.Id.GroupId Evergreen.V25.GroupPage.Model
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias BackendUser =
    { name : Evergreen.V25.Name.Name
    , description : Evergreen.V25.Description.Description
    , emailAddress : EmailAddress.EmailAddress
    , profileImage : Evergreen.V25.ProfileImage.ProfileImage
    , timezone : Time.Zone
    , allowEventReminders : Bool
    }


type alias LoginTokenData =
    { creationTime : Time.Posix
    , emailAddress : EmailAddress.EmailAddress
    }


type alias DeleteUserTokenData =
    { creationTime : Time.Posix
    , userId : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
    }


type alias BackendModel =
    { users : AssocList.Dict (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) BackendUser
    , groups : AssocList.Dict Evergreen.V25.Id.GroupId Evergreen.V25.Group.Group
    , groupIdCounter : Int
    , sessions : BiDict.Assoc.BiDict Evergreen.V25.Id.SessionId (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId)
    , loginAttempts : AssocList.Dict Evergreen.V25.Id.SessionId (List.Nonempty.Nonempty Time.Posix)
    , connections : AssocList.Dict Evergreen.V25.Id.SessionId (List.Nonempty.Nonempty Evergreen.V25.Id.ClientId)
    , logs : Array.Array Log
    , time : Time.Posix
    , secretCounter : Int
    , pendingLoginTokens : AssocList.Dict (Evergreen.V25.Id.Id Evergreen.V25.Id.LoginToken) LoginTokenData
    , pendingDeleteUserTokens : AssocList.Dict (Evergreen.V25.Id.Id Evergreen.V25.Id.DeleteUserToken) DeleteUserTokenData
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
    | GroupFormMsg Evergreen.V25.CreateGroupPage.Msg
    | ProfileFormMsg Evergreen.V25.ProfilePage.Msg
    | CroppedImage
        { requestId : Int
        , croppedImageUrl : String
        }
    | TypedSearchText String
    | SubmittedSearchBox
    | GroupPageMsg Evergreen.V25.GroupPage.Msg
    | GotWindowSize (Quantity.Quantity Int Pixels.Pixels) (Quantity.Quantity Int Pixels.Pixels)
    | GotTimeZone (Result TimeZone.Error ( String, Time.Zone ))


type BackendMsg
    = SentLoginEmail EmailAddress.EmailAddress (Result SendGrid.Error ())
    | SentDeleteUserEmail (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) (Result SendGrid.Error ())
    | SentEventReminderEmail (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) Evergreen.V25.Id.GroupId Evergreen.V25.Group.EventId (Result SendGrid.Error ())
    | BackendGotTime Time.Posix
    | Connected Evergreen.V25.Id.SessionId Evergreen.V25.Id.ClientId
    | Disconnected Evergreen.V25.Id.SessionId Evergreen.V25.Id.ClientId


type GroupRequest
    = GroupNotFound_
    | GroupFound_ Evergreen.V25.Group.Group (AssocList.Dict (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) Evergreen.V25.FrontendUser.FrontendUser)


type ToFrontend
    = GetGroupResponse Evergreen.V25.Id.GroupId GroupRequest
    | GetUserResponse (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId) (Result () Evergreen.V25.FrontendUser.FrontendUser)
    | CheckLoginResponse
        (Maybe
            { userId : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | LoginWithTokenResponse
        (Result
            ()
            { userId : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | GetAdminDataResponse AdminModel
    | CreateGroupResponse (Result Evergreen.V25.CreateGroupPage.CreateGroupError ( Evergreen.V25.Id.GroupId, Evergreen.V25.Group.Group ))
    | LogoutResponse
    | ChangeNameResponse Evergreen.V25.Name.Name
    | ChangeDescriptionResponse Evergreen.V25.Description.Description
    | ChangeEmailAddressResponse EmailAddress.EmailAddress
    | DeleteUserResponse (Result () ())
    | ChangeProfileImageResponse Evergreen.V25.ProfileImage.ProfileImage
    | GetMyGroupsResponse (List ( Evergreen.V25.Id.GroupId, Evergreen.V25.Group.Group ))
    | SearchGroupsResponse String (List ( Evergreen.V25.Id.GroupId, Evergreen.V25.Group.Group ))
    | ChangeGroupNameResponse Evergreen.V25.Id.GroupId Evergreen.V25.GroupName.GroupName
    | ChangeGroupDescriptionResponse Evergreen.V25.Id.GroupId Evergreen.V25.Description.Description
    | CreateEventResponse Evergreen.V25.Id.GroupId (Result Evergreen.V25.GroupPage.CreateEventError Evergreen.V25.Event.Event)
    | EditEventResponse Evergreen.V25.Id.GroupId Evergreen.V25.Group.EventId (Result Evergreen.V25.Group.EditEventError Evergreen.V25.Event.Event) Time.Posix
    | JoinEventResponse Evergreen.V25.Id.GroupId Evergreen.V25.Group.EventId (Result Evergreen.V25.Group.JoinEventError ())
    | LeaveEventResponse Evergreen.V25.Id.GroupId Evergreen.V25.Group.EventId (Result () ())
    | ChangeEventCancellationStatusResponse Evergreen.V25.Id.GroupId Evergreen.V25.Group.EventId (Result Evergreen.V25.Group.EditCancellationStatusError Evergreen.V25.Event.CancellationStatus) Time.Posix
