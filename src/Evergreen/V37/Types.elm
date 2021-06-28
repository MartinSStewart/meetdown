module Evergreen.V37.Types exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc
import Browser
import Browser.Navigation
import Evergreen.V37.AdminStatus
import Evergreen.V37.CreateGroupPage
import Evergreen.V37.Description
import Evergreen.V37.EmailAddress
import Evergreen.V37.Event
import Evergreen.V37.EventDuration
import Evergreen.V37.EventName
import Evergreen.V37.FrontendUser
import Evergreen.V37.Group
import Evergreen.V37.GroupName
import Evergreen.V37.GroupPage
import Evergreen.V37.Id
import Evergreen.V37.MaxAttendees
import Evergreen.V37.Name
import Evergreen.V37.Postmark
import Evergreen.V37.ProfileImage
import Evergreen.V37.ProfilePage
import Evergreen.V37.Route
import Evergreen.V37.Untrusted
import Http
import List.Nonempty
import Pixels
import Quantity
import Time
import TimeZone
import Url


type NavigationKey
    = RealNavigationKey Browser.Navigation.Key
    | MockNavigationKey


type alias LoadingFrontend =
    { navigationKey : NavigationKey
    , route : Evergreen.V37.Route.Route
    , routeToken : Evergreen.V37.Route.Token
    , windowSize : Maybe ( Quantity.Quantity Int Pixels.Pixels, Quantity.Quantity Int Pixels.Pixels )
    , time : Maybe Time.Posix
    , timezone : Maybe Time.Zone
    }


type ToBackend
    = GetGroupRequest (Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId)
    | GetUserRequest (Evergreen.V37.Id.Id Evergreen.V37.Id.UserId)
    | CheckLoginRequest
    | LoginWithTokenRequest (Evergreen.V37.Id.Id Evergreen.V37.Id.LoginToken) (Maybe ( Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId, Evergreen.V37.Group.EventId ))
    | GetLoginTokenRequest Evergreen.V37.Route.Route (Evergreen.V37.Untrusted.Untrusted Evergreen.V37.EmailAddress.EmailAddress) (Maybe ( Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId, Evergreen.V37.Group.EventId ))
    | GetAdminDataRequest
    | LogoutRequest
    | CreateGroupRequest (Evergreen.V37.Untrusted.Untrusted Evergreen.V37.GroupName.GroupName) (Evergreen.V37.Untrusted.Untrusted Evergreen.V37.Description.Description) Evergreen.V37.Group.GroupVisibility
    | ChangeNameRequest (Evergreen.V37.Untrusted.Untrusted Evergreen.V37.Name.Name)
    | ChangeDescriptionRequest (Evergreen.V37.Untrusted.Untrusted Evergreen.V37.Description.Description)
    | ChangeEmailAddressRequest (Evergreen.V37.Untrusted.Untrusted Evergreen.V37.EmailAddress.EmailAddress)
    | SendDeleteUserEmailRequest
    | DeleteUserRequest (Evergreen.V37.Id.Id Evergreen.V37.Id.DeleteUserToken)
    | ChangeProfileImageRequest (Evergreen.V37.Untrusted.Untrusted Evergreen.V37.ProfileImage.ProfileImage)
    | GetMyGroupsRequest
    | SearchGroupsRequest String
    | ChangeGroupNameRequest (Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId) (Evergreen.V37.Untrusted.Untrusted Evergreen.V37.GroupName.GroupName)
    | ChangeGroupDescriptionRequest (Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId) (Evergreen.V37.Untrusted.Untrusted Evergreen.V37.Description.Description)
    | ChangeGroupVisibilityRequest (Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId) Evergreen.V37.Group.GroupVisibility
    | CreateEventRequest (Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId) (Evergreen.V37.Untrusted.Untrusted Evergreen.V37.EventName.EventName) (Evergreen.V37.Untrusted.Untrusted Evergreen.V37.Description.Description) (Evergreen.V37.Untrusted.Untrusted Evergreen.V37.Event.EventType) Time.Posix (Evergreen.V37.Untrusted.Untrusted Evergreen.V37.EventDuration.EventDuration) (Evergreen.V37.Untrusted.Untrusted Evergreen.V37.MaxAttendees.MaxAttendees)
    | EditEventRequest (Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId) Evergreen.V37.Group.EventId (Evergreen.V37.Untrusted.Untrusted Evergreen.V37.EventName.EventName) (Evergreen.V37.Untrusted.Untrusted Evergreen.V37.Description.Description) (Evergreen.V37.Untrusted.Untrusted Evergreen.V37.Event.EventType) Time.Posix (Evergreen.V37.Untrusted.Untrusted Evergreen.V37.EventDuration.EventDuration) (Evergreen.V37.Untrusted.Untrusted Evergreen.V37.MaxAttendees.MaxAttendees)
    | JoinEventRequest (Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId) Evergreen.V37.Group.EventId
    | LeaveEventRequest (Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId) Evergreen.V37.Group.EventId
    | ChangeEventCancellationStatusRequest (Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId) Evergreen.V37.Group.EventId Evergreen.V37.Event.CancellationStatus
    | DeleteGroupAdminRequest (Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId)


type Log
    = LogUntrustedCheckFailed Time.Posix ToBackend Evergreen.V37.Id.SessionIdFirst4Chars
    | LogLoginEmail Time.Posix (Result Http.Error Evergreen.V37.Postmark.PostmarkSendResponse) Evergreen.V37.EmailAddress.EmailAddress
    | LogDeleteAccountEmail Time.Posix (Result Http.Error Evergreen.V37.Postmark.PostmarkSendResponse) (Evergreen.V37.Id.Id Evergreen.V37.Id.UserId)
    | LogEventReminderEmail Time.Posix (Result Http.Error Evergreen.V37.Postmark.PostmarkSendResponse) (Evergreen.V37.Id.Id Evergreen.V37.Id.UserId) (Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId) Evergreen.V37.Group.EventId
    | LogLoginTokenEmailRequestRateLimited Time.Posix Evergreen.V37.EmailAddress.EmailAddress Evergreen.V37.Id.SessionIdFirst4Chars
    | LogDeleteAccountEmailRequestRateLimited Time.Posix (Evergreen.V37.Id.Id Evergreen.V37.Id.UserId) Evergreen.V37.Id.SessionIdFirst4Chars


type alias AdminModel =
    { cachedEmailAddress : AssocList.Dict (Evergreen.V37.Id.Id Evergreen.V37.Id.UserId) Evergreen.V37.EmailAddress.EmailAddress
    , logs : Array.Array Log
    , lastLogCheck : Time.Posix
    }


type AdminCache
    = AdminCacheNotRequested
    | AdminCached AdminModel
    | AdminCachePending


type alias LoggedIn_ =
    { userId : Evergreen.V37.Id.Id Evergreen.V37.Id.UserId
    , emailAddress : Evergreen.V37.EmailAddress.EmailAddress
    , profileForm : Evergreen.V37.ProfilePage.Model
    , myGroups : Maybe (AssocSet.Set (Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId))
    , adminState : AdminCache
    , adminStatus : Evergreen.V37.AdminStatus.AdminStatus
    }


type LoginStatus
    = LoginStatusPending
    | LoggedIn LoggedIn_
    | NotLoggedIn
        { showLogin : Bool
        , joiningEvent : Maybe ( Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId, Evergreen.V37.Group.EventId )
        }


type Cache item
    = ItemDoesNotExist
    | ItemCached item
    | ItemRequestPending


type alias LoginForm =
    { email : String
    , pressedSubmitEmail : Bool
    , emailSent : Maybe Evergreen.V37.EmailAddress.EmailAddress
    }


type alias LoadedFrontend =
    { navigationKey : NavigationKey
    , loginStatus : LoginStatus
    , route : Evergreen.V37.Route.Route
    , cachedGroups : AssocList.Dict (Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId) (Cache Evergreen.V37.Group.Group)
    , cachedUsers : AssocList.Dict (Evergreen.V37.Id.Id Evergreen.V37.Id.UserId) (Cache Evergreen.V37.FrontendUser.FrontendUser)
    , time : Time.Posix
    , timezone : Time.Zone
    , lastConnectionCheck : Time.Posix
    , loginForm : LoginForm
    , logs : Maybe (Array.Array Log)
    , hasLoginTokenError : Bool
    , groupForm : Evergreen.V37.CreateGroupPage.Model
    , groupCreated : Bool
    , accountDeletedResult : Maybe (Result () ())
    , searchText : String
    , searchList : List (Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId)
    , windowWidth : Quantity.Quantity Int Pixels.Pixels
    , windowHeight : Quantity.Quantity Int Pixels.Pixels
    , groupPage : AssocList.Dict (Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId) Evergreen.V37.GroupPage.Model
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias BackendUser =
    { name : Evergreen.V37.Name.Name
    , description : Evergreen.V37.Description.Description
    , emailAddress : Evergreen.V37.EmailAddress.EmailAddress
    , profileImage : Evergreen.V37.ProfileImage.ProfileImage
    , timezone : Time.Zone
    , allowEventReminders : Bool
    }


type alias LoginTokenData =
    { creationTime : Time.Posix
    , emailAddress : Evergreen.V37.EmailAddress.EmailAddress
    }


type alias DeleteUserTokenData =
    { creationTime : Time.Posix
    , userId : Evergreen.V37.Id.Id Evergreen.V37.Id.UserId
    }


type alias BackendModel =
    { users : AssocList.Dict (Evergreen.V37.Id.Id Evergreen.V37.Id.UserId) BackendUser
    , groups : AssocList.Dict (Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId) Evergreen.V37.Group.Group
    , deletedGroups : AssocList.Dict (Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId) Evergreen.V37.Group.Group
    , sessions : BiDict.Assoc.BiDict Evergreen.V37.Id.SessionId (Evergreen.V37.Id.Id Evergreen.V37.Id.UserId)
    , loginAttempts : AssocList.Dict Evergreen.V37.Id.SessionId (List.Nonempty.Nonempty Time.Posix)
    , connections : AssocList.Dict Evergreen.V37.Id.SessionId (List.Nonempty.Nonempty Evergreen.V37.Id.ClientId)
    , logs : Array.Array Log
    , time : Time.Posix
    , secretCounter : Int
    , pendingLoginTokens : AssocList.Dict (Evergreen.V37.Id.Id Evergreen.V37.Id.LoginToken) LoginTokenData
    , pendingDeleteUserTokens : AssocList.Dict (Evergreen.V37.Id.Id Evergreen.V37.Id.DeleteUserToken) DeleteUserTokenData
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
    | CreateGroupPageMsg Evergreen.V37.CreateGroupPage.Msg
    | ProfileFormMsg Evergreen.V37.ProfilePage.Msg
    | CroppedImage
        { requestId : Int
        , croppedImageUrl : String
        }
    | TypedSearchText String
    | SubmittedSearchBox
    | GroupPageMsg Evergreen.V37.GroupPage.Msg
    | GotWindowSize (Quantity.Quantity Int Pixels.Pixels) (Quantity.Quantity Int Pixels.Pixels)
    | GotTimeZone (Result TimeZone.Error ( String, Time.Zone ))
    | ScrolledToTop
    | PressedEnableAdmin
    | PressedDisableAdmin


type BackendMsg
    = SentLoginEmail Evergreen.V37.EmailAddress.EmailAddress (Result Http.Error Evergreen.V37.Postmark.PostmarkSendResponse)
    | SentDeleteUserEmail (Evergreen.V37.Id.Id Evergreen.V37.Id.UserId) (Result Http.Error Evergreen.V37.Postmark.PostmarkSendResponse)
    | SentEventReminderEmail (Evergreen.V37.Id.Id Evergreen.V37.Id.UserId) (Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId) Evergreen.V37.Group.EventId (Result Http.Error Evergreen.V37.Postmark.PostmarkSendResponse)
    | BackendGotTime Time.Posix
    | Connected Evergreen.V37.Id.SessionId Evergreen.V37.Id.ClientId
    | Disconnected Evergreen.V37.Id.SessionId Evergreen.V37.Id.ClientId


type GroupRequest
    = GroupNotFound_
    | GroupFound_ Evergreen.V37.Group.Group (AssocList.Dict (Evergreen.V37.Id.Id Evergreen.V37.Id.UserId) Evergreen.V37.FrontendUser.FrontendUser)


type ToFrontend
    = GetGroupResponse (Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId) GroupRequest
    | GetUserResponse (Evergreen.V37.Id.Id Evergreen.V37.Id.UserId) (Result () Evergreen.V37.FrontendUser.FrontendUser)
    | CheckLoginResponse
        (Maybe
            { userId : Evergreen.V37.Id.Id Evergreen.V37.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | LoginWithTokenResponse
        (Result
            ()
            { userId : Evergreen.V37.Id.Id Evergreen.V37.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | GetAdminDataResponse AdminModel
    | CreateGroupResponse (Result Evergreen.V37.CreateGroupPage.CreateGroupError ( Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId, Evergreen.V37.Group.Group ))
    | LogoutResponse
    | ChangeNameResponse Evergreen.V37.Name.Name
    | ChangeDescriptionResponse Evergreen.V37.Description.Description
    | ChangeEmailAddressResponse Evergreen.V37.EmailAddress.EmailAddress
    | DeleteUserResponse (Result () ())
    | ChangeProfileImageResponse Evergreen.V37.ProfileImage.ProfileImage
    | GetMyGroupsResponse (List ( Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId, Evergreen.V37.Group.Group ))
    | SearchGroupsResponse String (List ( Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId, Evergreen.V37.Group.Group ))
    | ChangeGroupNameResponse (Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId) Evergreen.V37.GroupName.GroupName
    | ChangeGroupDescriptionResponse (Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId) Evergreen.V37.Description.Description
    | ChangeGroupVisibilityResponse (Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId) Evergreen.V37.Group.GroupVisibility
    | CreateEventResponse (Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId) (Result Evergreen.V37.GroupPage.CreateEventError Evergreen.V37.Event.Event)
    | EditEventResponse (Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId) Evergreen.V37.Group.EventId (Result Evergreen.V37.Group.EditEventError Evergreen.V37.Event.Event) Time.Posix
    | JoinEventResponse (Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId) Evergreen.V37.Group.EventId (Result Evergreen.V37.Group.JoinEventError ())
    | LeaveEventResponse (Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId) Evergreen.V37.Group.EventId (Result () ())
    | ChangeEventCancellationStatusResponse (Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId) Evergreen.V37.Group.EventId (Result Evergreen.V37.Group.EditCancellationStatusError Evergreen.V37.Event.CancellationStatus) Time.Posix
    | DeleteGroupAdminResponse (Evergreen.V37.Id.Id Evergreen.V37.Id.GroupId)
