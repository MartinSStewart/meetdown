module Evergreen.V26.Types exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc
import Browser
import Browser.Navigation
import Evergreen.V26.CreateGroupPage
import Evergreen.V26.Description
import Evergreen.V26.Event
import Evergreen.V26.EventDuration
import Evergreen.V26.EventName
import Evergreen.V26.FrontendUser
import Evergreen.V26.Group
import Evergreen.V26.GroupName
import Evergreen.V26.GroupPage
import Evergreen.V26.Id
import Evergreen.V26.MaxAttendees
import Evergreen.V26.Name
import Evergreen.V26.ProfileImage
import Evergreen.V26.ProfilePage
import Evergreen.V26.Route
import Evergreen.V26.Untrusted
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
    , route : Evergreen.V26.Route.Route
    , routeToken : Evergreen.V26.Route.Token
    , windowSize : Maybe ( Quantity.Quantity Int Pixels.Pixels, Quantity.Quantity Int Pixels.Pixels )
    , time : Maybe Time.Posix
    , timezone : Maybe Time.Zone
    }


type ToBackend
    = GetGroupRequest (Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId)
    | GetUserRequest (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId)
    | CheckLoginRequest
    | LoginWithTokenRequest (Evergreen.V26.Id.Id Evergreen.V26.Id.LoginToken) (Maybe ( Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId, Evergreen.V26.Group.EventId ))
    | GetLoginTokenRequest Evergreen.V26.Route.Route (Evergreen.V26.Untrusted.Untrusted EmailAddress) (Maybe ( Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId, Evergreen.V26.Group.EventId ))
    | GetAdminDataRequest
    | LogoutRequest
    | CreateGroupRequest (Evergreen.V26.Untrusted.Untrusted Evergreen.V26.GroupName.GroupName) (Evergreen.V26.Untrusted.Untrusted Evergreen.V26.Description.Description) Evergreen.V26.Group.GroupVisibility
    | ChangeNameRequest (Evergreen.V26.Untrusted.Untrusted Evergreen.V26.Name.Name)
    | ChangeDescriptionRequest (Evergreen.V26.Untrusted.Untrusted Evergreen.V26.Description.Description)
    | ChangeEmailAddressRequest (Evergreen.V26.Untrusted.Untrusted EmailAddress)
    | SendDeleteUserEmailRequest
    | DeleteUserRequest (Evergreen.V26.Id.Id Evergreen.V26.Id.DeleteUserToken)
    | ChangeProfileImageRequest (Evergreen.V26.Untrusted.Untrusted Evergreen.V26.ProfileImage.ProfileImage)
    | GetMyGroupsRequest
    | SearchGroupsRequest String
    | ChangeGroupNameRequest (Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId) (Evergreen.V26.Untrusted.Untrusted Evergreen.V26.GroupName.GroupName)
    | ChangeGroupDescriptionRequest (Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId) (Evergreen.V26.Untrusted.Untrusted Evergreen.V26.Description.Description)
    | CreateEventRequest (Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId) (Evergreen.V26.Untrusted.Untrusted Evergreen.V26.EventName.EventName) (Evergreen.V26.Untrusted.Untrusted Evergreen.V26.Description.Description) (Evergreen.V26.Untrusted.Untrusted Evergreen.V26.Event.EventType) Time.Posix (Evergreen.V26.Untrusted.Untrusted Evergreen.V26.EventDuration.EventDuration) (Evergreen.V26.Untrusted.Untrusted Evergreen.V26.MaxAttendees.MaxAttendees)
    | EditEventRequest (Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId) Evergreen.V26.Group.EventId (Evergreen.V26.Untrusted.Untrusted Evergreen.V26.EventName.EventName) (Evergreen.V26.Untrusted.Untrusted Evergreen.V26.Description.Description) (Evergreen.V26.Untrusted.Untrusted Evergreen.V26.Event.EventType) Time.Posix (Evergreen.V26.Untrusted.Untrusted Evergreen.V26.EventDuration.EventDuration) (Evergreen.V26.Untrusted.Untrusted Evergreen.V26.MaxAttendees.MaxAttendees)
    | JoinEventRequest (Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId) Evergreen.V26.Group.EventId
    | LeaveEventRequest (Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId) Evergreen.V26.Group.EventId
    | ChangeEventCancellationStatusRequest (Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId) Evergreen.V26.Group.EventId Evergreen.V26.Event.CancellationStatus


type Log
    = LogUntrustedCheckFailed Time.Posix ToBackend Evergreen.V26.Id.SessionIdFirst4Chars
    | LogLoginEmail Time.Posix (Result SendGrid.Error ()) EmailAddress
    | LogDeleteAccountEmail Time.Posix (Result SendGrid.Error ()) (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId)
    | LogEventReminderEmail Time.Posix (Result SendGrid.Error ()) (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) (Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId) Evergreen.V26.Group.EventId
    | LogLoginTokenEmailRequestRateLimited Time.Posix EmailAddress Evergreen.V26.Id.SessionIdFirst4Chars
    | LogDeleteAccountEmailRequestRateLimited Time.Posix (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) Evergreen.V26.Id.SessionIdFirst4Chars


type alias AdminModel =
    { cachedEmailAddress : AssocList.Dict (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) EmailAddress
    , logs : Array.Array Log
    , lastLogCheck : Time.Posix
    }


type AdminCache
    = AdminCacheNotRequested
    | AdminCached AdminModel
    | AdminCachePending


type alias LoggedIn_ =
    { userId : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
    , emailAddress : EmailAddress
    , profileForm : Evergreen.V26.ProfilePage.Model
    , myGroups : Maybe (AssocSet.Set (Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId))
    , adminState : AdminCache
    , isAdmin : Bool
    }


type LoginStatus
    = LoginStatusPending
    | LoggedIn LoggedIn_
    | NotLoggedIn
        { showLogin : Bool
        , joiningEvent : Maybe ( Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId, Evergreen.V26.Group.EventId )
        }


type Cache item
    = ItemDoesNotExist
    | ItemCached item
    | ItemRequestPending


type alias LoginForm =
    { email : String
    , pressedSubmitEmail : Bool
    , emailSent : Maybe EmailAddress
    }


type alias LoadedFrontend =
    { navigationKey : NavigationKey
    , loginStatus : LoginStatus
    , route : Evergreen.V26.Route.Route
    , cachedGroups : AssocList.Dict (Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId) (Cache Evergreen.V26.Group.Group)
    , cachedUsers : AssocList.Dict (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) (Cache Evergreen.V26.FrontendUser.FrontendUser)
    , time : Time.Posix
    , timezone : Time.Zone
    , lastConnectionCheck : Time.Posix
    , loginForm : LoginForm
    , logs : Maybe (Array.Array Log)
    , hasLoginTokenError : Bool
    , groupForm : Evergreen.V26.CreateGroupPage.Model
    , groupCreated : Bool
    , accountDeletedResult : Maybe (Result () ())
    , searchText : String
    , searchList : List (Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId)
    , windowWidth : Quantity.Quantity Int Pixels.Pixels
    , windowHeight : Quantity.Quantity Int Pixels.Pixels
    , groupPage : AssocList.Dict (Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId) Evergreen.V26.GroupPage.Model
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias BackendUser =
    { name : Evergreen.V26.Name.Name
    , description : Evergreen.V26.Description.Description
    , emailAddress : EmailAddress
    , profileImage : Evergreen.V26.ProfileImage.ProfileImage
    , timezone : Time.Zone
    , allowEventReminders : Bool
    }


type alias LoginTokenData =
    { creationTime : Time.Posix
    , emailAddress : EmailAddress
    }


type alias DeleteUserTokenData =
    { creationTime : Time.Posix
    , userId : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
    }


type alias BackendModel =
    { users : AssocList.Dict (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) BackendUser
    , groups : AssocList.Dict (Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId) Evergreen.V26.Group.Group
    , sessions : BiDict.Assoc.BiDict Evergreen.V26.Id.SessionId (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId)
    , loginAttempts : AssocList.Dict Evergreen.V26.Id.SessionId (List.Nonempty.Nonempty Time.Posix)
    , connections : AssocList.Dict Evergreen.V26.Id.SessionId (List.Nonempty.Nonempty Evergreen.V26.Id.ClientId)
    , logs : Array.Array Log
    , time : Time.Posix
    , secretCounter : Int
    , pendingLoginTokens : AssocList.Dict (Evergreen.V26.Id.Id Evergreen.V26.Id.LoginToken) LoginTokenData
    , pendingDeleteUserTokens : AssocList.Dict (Evergreen.V26.Id.Id Evergreen.V26.Id.DeleteUserToken) DeleteUserTokenData
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
    | GroupFormMsg Evergreen.V26.CreateGroupPage.Msg
    | ProfileFormMsg Evergreen.V26.ProfilePage.Msg
    | CroppedImage
        { requestId : Int
        , croppedImageUrl : String
        }
    | TypedSearchText String
    | SubmittedSearchBox
    | GroupPageMsg Evergreen.V26.GroupPage.Msg
    | GotWindowSize (Quantity.Quantity Int Pixels.Pixels) (Quantity.Quantity Int Pixels.Pixels)
    | GotTimeZone (Result TimeZone.Error ( String, Time.Zone ))


type BackendMsg
    = SentLoginEmail EmailAddress (Result SendGrid.Error ())
    | SentDeleteUserEmail (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) (Result SendGrid.Error ())
    | SentEventReminderEmail (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) (Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId) Evergreen.V26.Group.EventId (Result SendGrid.Error ())
    | BackendGotTime Time.Posix
    | Connected Evergreen.V26.Id.SessionId Evergreen.V26.Id.ClientId
    | Disconnected Evergreen.V26.Id.SessionId Evergreen.V26.Id.ClientId


type GroupRequest
    = GroupNotFound_
    | GroupFound_ Evergreen.V26.Group.Group (AssocList.Dict (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) Evergreen.V26.FrontendUser.FrontendUser)


type ToFrontend
    = GetGroupResponse (Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId) GroupRequest
    | GetUserResponse (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId) (Result () Evergreen.V26.FrontendUser.FrontendUser)
    | CheckLoginResponse
        (Maybe
            { userId : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | LoginWithTokenResponse
        (Result
            ()
            { userId : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | GetAdminDataResponse AdminModel
    | CreateGroupResponse (Result Evergreen.V26.CreateGroupPage.CreateGroupError ( Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId, Evergreen.V26.Group.Group ))
    | LogoutResponse
    | ChangeNameResponse Evergreen.V26.Name.Name
    | ChangeDescriptionResponse Evergreen.V26.Description.Description
    | ChangeEmailAddressResponse EmailAddress
    | DeleteUserResponse (Result () ())
    | ChangeProfileImageResponse Evergreen.V26.ProfileImage.ProfileImage
    | GetMyGroupsResponse (List ( Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId, Evergreen.V26.Group.Group ))
    | SearchGroupsResponse String (List ( Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId, Evergreen.V26.Group.Group ))
    | ChangeGroupNameResponse (Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId) Evergreen.V26.GroupName.GroupName
    | ChangeGroupDescriptionResponse (Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId) Evergreen.V26.Description.Description
    | CreateEventResponse (Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId) (Result Evergreen.V26.GroupPage.CreateEventError Evergreen.V26.Event.Event)
    | EditEventResponse (Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId) Evergreen.V26.Group.EventId (Result Evergreen.V26.Group.EditEventError Evergreen.V26.Event.Event) Time.Posix
    | JoinEventResponse (Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId) Evergreen.V26.Group.EventId (Result Evergreen.V26.Group.JoinEventError ())
    | LeaveEventResponse (Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId) Evergreen.V26.Group.EventId (Result () ())
    | ChangeEventCancellationStatusResponse (Evergreen.V26.Id.Id Evergreen.V26.Id.GroupId) Evergreen.V26.Group.EventId (Result Evergreen.V26.Group.EditCancellationStatusError Evergreen.V26.Event.CancellationStatus) Time.Posix


type EmailAddress
    = EmailAddress
        { localPart : String
        , tags : List String
        , domain : String
        , tld : List String
        }
