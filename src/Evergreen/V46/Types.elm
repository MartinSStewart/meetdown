module Evergreen.V46.Types exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc
import Browser
import Browser.Navigation
import Evergreen.V46.AdminStatus
import Evergreen.V46.CreateGroupPage
import Evergreen.V46.Description
import Evergreen.V46.EmailAddress
import Evergreen.V46.Event
import Evergreen.V46.EventDuration
import Evergreen.V46.EventName
import Evergreen.V46.FrontendUser
import Evergreen.V46.Group
import Evergreen.V46.GroupName
import Evergreen.V46.GroupPage
import Evergreen.V46.Id
import Evergreen.V46.MaxAttendees
import Evergreen.V46.Name
import Evergreen.V46.Postmark
import Evergreen.V46.ProfileImage
import Evergreen.V46.ProfilePage
import Evergreen.V46.Route
import Evergreen.V46.Untrusted
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
    , route : Evergreen.V46.Route.Route
    , routeToken : Evergreen.V46.Route.Token
    , windowSize : Maybe ( Quantity.Quantity Int Pixels.Pixels, Quantity.Quantity Int Pixels.Pixels )
    , time : Maybe Time.Posix
    , timezone : Maybe Time.Zone
    }


type ToBackend
    = GetGroupRequest (Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId)
    | GetUserRequest (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId)
    | CheckLoginRequest
    | LoginWithTokenRequest (Evergreen.V46.Id.Id Evergreen.V46.Id.LoginToken) (Maybe ( Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId, Evergreen.V46.Group.EventId ))
    | GetLoginTokenRequest Evergreen.V46.Route.Route (Evergreen.V46.Untrusted.Untrusted Evergreen.V46.EmailAddress.EmailAddress) (Maybe ( Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId, Evergreen.V46.Group.EventId ))
    | GetAdminDataRequest
    | LogoutRequest
    | CreateGroupRequest (Evergreen.V46.Untrusted.Untrusted Evergreen.V46.GroupName.GroupName) (Evergreen.V46.Untrusted.Untrusted Evergreen.V46.Description.Description) Evergreen.V46.Group.GroupVisibility
    | ChangeNameRequest (Evergreen.V46.Untrusted.Untrusted Evergreen.V46.Name.Name)
    | ChangeDescriptionRequest (Evergreen.V46.Untrusted.Untrusted Evergreen.V46.Description.Description)
    | ChangeEmailAddressRequest (Evergreen.V46.Untrusted.Untrusted Evergreen.V46.EmailAddress.EmailAddress)
    | SendDeleteUserEmailRequest
    | DeleteUserRequest (Evergreen.V46.Id.Id Evergreen.V46.Id.DeleteUserToken)
    | ChangeProfileImageRequest (Evergreen.V46.Untrusted.Untrusted Evergreen.V46.ProfileImage.ProfileImage)
    | GetMyGroupsRequest
    | SearchGroupsRequest String
    | ChangeGroupNameRequest (Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId) (Evergreen.V46.Untrusted.Untrusted Evergreen.V46.GroupName.GroupName)
    | ChangeGroupDescriptionRequest (Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId) (Evergreen.V46.Untrusted.Untrusted Evergreen.V46.Description.Description)
    | ChangeGroupVisibilityRequest (Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId) Evergreen.V46.Group.GroupVisibility
    | CreateEventRequest (Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId) (Evergreen.V46.Untrusted.Untrusted Evergreen.V46.EventName.EventName) (Evergreen.V46.Untrusted.Untrusted Evergreen.V46.Description.Description) (Evergreen.V46.Untrusted.Untrusted Evergreen.V46.Event.EventType) Time.Posix (Evergreen.V46.Untrusted.Untrusted Evergreen.V46.EventDuration.EventDuration) (Evergreen.V46.Untrusted.Untrusted Evergreen.V46.MaxAttendees.MaxAttendees)
    | EditEventRequest (Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId) Evergreen.V46.Group.EventId (Evergreen.V46.Untrusted.Untrusted Evergreen.V46.EventName.EventName) (Evergreen.V46.Untrusted.Untrusted Evergreen.V46.Description.Description) (Evergreen.V46.Untrusted.Untrusted Evergreen.V46.Event.EventType) Time.Posix (Evergreen.V46.Untrusted.Untrusted Evergreen.V46.EventDuration.EventDuration) (Evergreen.V46.Untrusted.Untrusted Evergreen.V46.MaxAttendees.MaxAttendees)
    | JoinEventRequest (Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId) Evergreen.V46.Group.EventId
    | LeaveEventRequest (Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId) Evergreen.V46.Group.EventId
    | ChangeEventCancellationStatusRequest (Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId) Evergreen.V46.Group.EventId Evergreen.V46.Event.CancellationStatus
    | DeleteGroupAdminRequest (Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId)


type Log
    = LogUntrustedCheckFailed Time.Posix ToBackend Evergreen.V46.Id.SessionIdFirst4Chars
    | LogLoginEmail Time.Posix (Result Http.Error Evergreen.V46.Postmark.PostmarkSendResponse) Evergreen.V46.EmailAddress.EmailAddress
    | LogDeleteAccountEmail Time.Posix (Result Http.Error Evergreen.V46.Postmark.PostmarkSendResponse) (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId)
    | LogEventReminderEmail Time.Posix (Result Http.Error Evergreen.V46.Postmark.PostmarkSendResponse) (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) (Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId) Evergreen.V46.Group.EventId
    | LogLoginTokenEmailRequestRateLimited Time.Posix Evergreen.V46.EmailAddress.EmailAddress Evergreen.V46.Id.SessionIdFirst4Chars
    | LogDeleteAccountEmailRequestRateLimited Time.Posix (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) Evergreen.V46.Id.SessionIdFirst4Chars


type alias AdminModel =
    { cachedEmailAddress : AssocList.Dict (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) Evergreen.V46.EmailAddress.EmailAddress
    , logs : Array.Array Log
    , lastLogCheck : Time.Posix
    }


type AdminCache
    = AdminCacheNotRequested
    | AdminCached AdminModel
    | AdminCachePending


type alias LoggedIn_ =
    { userId : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
    , emailAddress : Evergreen.V46.EmailAddress.EmailAddress
    , profileForm : Evergreen.V46.ProfilePage.Model
    , myGroups : Maybe (AssocSet.Set (Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId))
    , adminState : AdminCache
    , adminStatus : Evergreen.V46.AdminStatus.AdminStatus
    }


type LoginStatus
    = LoginStatusPending
    | LoggedIn LoggedIn_
    | NotLoggedIn
        { showLogin : Bool
        , joiningEvent : Maybe ( Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId, Evergreen.V46.Group.EventId )
        }


type Cache item
    = ItemDoesNotExist
    | ItemCached item
    | ItemRequestPending


type alias LoginForm =
    { email : String
    , pressedSubmitEmail : Bool
    , emailSent : Maybe Evergreen.V46.EmailAddress.EmailAddress
    }


type alias LoadedFrontend =
    { navigationKey : NavigationKey
    , loginStatus : LoginStatus
    , route : Evergreen.V46.Route.Route
    , cachedGroups : AssocList.Dict (Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId) (Cache Evergreen.V46.Group.Group)
    , cachedUsers : AssocList.Dict (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) (Cache Evergreen.V46.FrontendUser.FrontendUser)
    , time : Time.Posix
    , timezone : Time.Zone
    , lastConnectionCheck : Time.Posix
    , loginForm : LoginForm
    , logs : Maybe (Array.Array Log)
    , hasLoginTokenError : Bool
    , groupForm : Evergreen.V46.CreateGroupPage.Model
    , groupCreated : Bool
    , accountDeletedResult : Maybe (Result () ())
    , searchText : String
    , searchList : List (Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId)
    , windowWidth : Quantity.Quantity Int Pixels.Pixels
    , windowHeight : Quantity.Quantity Int Pixels.Pixels
    , groupPage : AssocList.Dict (Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId) Evergreen.V46.GroupPage.Model
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias BackendUser =
    { name : Evergreen.V46.Name.Name
    , description : Evergreen.V46.Description.Description
    , emailAddress : Evergreen.V46.EmailAddress.EmailAddress
    , profileImage : Evergreen.V46.ProfileImage.ProfileImage
    , timezone : Time.Zone
    , allowEventReminders : Bool
    }


type alias LoginTokenData =
    { creationTime : Time.Posix
    , emailAddress : Evergreen.V46.EmailAddress.EmailAddress
    }


type alias DeleteUserTokenData =
    { creationTime : Time.Posix
    , userId : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
    }


type alias BackendModel =
    { users : AssocList.Dict (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) BackendUser
    , groups : AssocList.Dict (Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId) Evergreen.V46.Group.Group
    , deletedGroups : AssocList.Dict (Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId) Evergreen.V46.Group.Group
    , sessions : BiDict.Assoc.BiDict Evergreen.V46.Id.SessionId (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId)
    , loginAttempts : AssocList.Dict Evergreen.V46.Id.SessionId (List.Nonempty.Nonempty Time.Posix)
    , connections : AssocList.Dict Evergreen.V46.Id.SessionId (List.Nonempty.Nonempty Evergreen.V46.Id.ClientId)
    , logs : Array.Array Log
    , time : Time.Posix
    , secretCounter : Int
    , pendingLoginTokens : AssocList.Dict (Evergreen.V46.Id.Id Evergreen.V46.Id.LoginToken) LoginTokenData
    , pendingDeleteUserTokens : AssocList.Dict (Evergreen.V46.Id.Id Evergreen.V46.Id.DeleteUserToken) DeleteUserTokenData
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
    | CreateGroupPageMsg Evergreen.V46.CreateGroupPage.Msg
    | ProfileFormMsg Evergreen.V46.ProfilePage.Msg
    | CroppedImage
        { requestId : Int
        , croppedImageUrl : String
        }
    | TypedSearchText String
    | SubmittedSearchBox
    | GroupPageMsg Evergreen.V46.GroupPage.Msg
    | GotWindowSize (Quantity.Quantity Int Pixels.Pixels) (Quantity.Quantity Int Pixels.Pixels)
    | GotTimeZone (Result TimeZone.Error ( String, Time.Zone ))
    | ScrolledToTop
    | PressedEnableAdmin
    | PressedDisableAdmin


type BackendMsg
    = SentLoginEmail Evergreen.V46.EmailAddress.EmailAddress (Result Http.Error Evergreen.V46.Postmark.PostmarkSendResponse)
    | SentDeleteUserEmail (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) (Result Http.Error Evergreen.V46.Postmark.PostmarkSendResponse)
    | SentEventReminderEmail (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) (Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId) Evergreen.V46.Group.EventId (Result Http.Error Evergreen.V46.Postmark.PostmarkSendResponse)
    | BackendGotTime Time.Posix
    | Connected Evergreen.V46.Id.SessionId Evergreen.V46.Id.ClientId
    | Disconnected Evergreen.V46.Id.SessionId Evergreen.V46.Id.ClientId


type GroupRequest
    = GroupNotFound_
    | GroupFound_ Evergreen.V46.Group.Group (AssocList.Dict (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) Evergreen.V46.FrontendUser.FrontendUser)


type ToFrontend
    = GetGroupResponse (Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId) GroupRequest
    | GetUserResponse (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId) (Result () Evergreen.V46.FrontendUser.FrontendUser)
    | CheckLoginResponse
        (Maybe
            { userId : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | LoginWithTokenResponse
        (Result
            ()
            { userId : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | GetAdminDataResponse AdminModel
    | CreateGroupResponse (Result Evergreen.V46.CreateGroupPage.CreateGroupError ( Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId, Evergreen.V46.Group.Group ))
    | LogoutResponse
    | ChangeNameResponse Evergreen.V46.Name.Name
    | ChangeDescriptionResponse Evergreen.V46.Description.Description
    | ChangeEmailAddressResponse Evergreen.V46.EmailAddress.EmailAddress
    | DeleteUserResponse (Result () ())
    | ChangeProfileImageResponse Evergreen.V46.ProfileImage.ProfileImage
    | GetMyGroupsResponse (List ( Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId, Evergreen.V46.Group.Group ))
    | SearchGroupsResponse String (List ( Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId, Evergreen.V46.Group.Group ))
    | ChangeGroupNameResponse (Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId) Evergreen.V46.GroupName.GroupName
    | ChangeGroupDescriptionResponse (Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId) Evergreen.V46.Description.Description
    | ChangeGroupVisibilityResponse (Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId) Evergreen.V46.Group.GroupVisibility
    | CreateEventResponse (Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId) (Result Evergreen.V46.GroupPage.CreateEventError Evergreen.V46.Event.Event)
    | EditEventResponse (Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId) Evergreen.V46.Group.EventId (Result Evergreen.V46.Group.EditEventError Evergreen.V46.Event.Event) Time.Posix
    | JoinEventResponse (Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId) Evergreen.V46.Group.EventId (Result Evergreen.V46.Group.JoinEventError ())
    | LeaveEventResponse (Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId) Evergreen.V46.Group.EventId (Result () ())
    | ChangeEventCancellationStatusResponse (Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId) Evergreen.V46.Group.EventId (Result Evergreen.V46.Group.EditCancellationStatusError Evergreen.V46.Event.CancellationStatus) Time.Posix
    | DeleteGroupAdminResponse (Evergreen.V46.Id.Id Evergreen.V46.Id.GroupId)
