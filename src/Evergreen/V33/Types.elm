module Evergreen.V33.Types exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc
import Browser
import Browser.Navigation
import Evergreen.V33.CreateGroupPage
import Evergreen.V33.Description
import Evergreen.V33.EmailAddress
import Evergreen.V33.Event
import Evergreen.V33.EventDuration
import Evergreen.V33.EventName
import Evergreen.V33.FrontendUser
import Evergreen.V33.Group
import Evergreen.V33.GroupName
import Evergreen.V33.GroupPage
import Evergreen.V33.Id
import Evergreen.V33.MaxAttendees
import Evergreen.V33.Name
import Evergreen.V33.Postmark
import Evergreen.V33.ProfileImage
import Evergreen.V33.ProfilePage
import Evergreen.V33.Route
import Evergreen.V33.Untrusted
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
    , route : Evergreen.V33.Route.Route
    , routeToken : Evergreen.V33.Route.Token
    , windowSize : Maybe ( Quantity.Quantity Int Pixels.Pixels, Quantity.Quantity Int Pixels.Pixels )
    , time : Maybe Time.Posix
    , timezone : Maybe Time.Zone
    }


type ToBackend
    = GetGroupRequest (Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId)
    | GetUserRequest (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId)
    | CheckLoginRequest
    | LoginWithTokenRequest (Evergreen.V33.Id.Id Evergreen.V33.Id.LoginToken) (Maybe ( Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId, Evergreen.V33.Group.EventId ))
    | GetLoginTokenRequest Evergreen.V33.Route.Route (Evergreen.V33.Untrusted.Untrusted Evergreen.V33.EmailAddress.EmailAddress) (Maybe ( Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId, Evergreen.V33.Group.EventId ))
    | GetAdminDataRequest
    | LogoutRequest
    | CreateGroupRequest (Evergreen.V33.Untrusted.Untrusted Evergreen.V33.GroupName.GroupName) (Evergreen.V33.Untrusted.Untrusted Evergreen.V33.Description.Description) Evergreen.V33.Group.GroupVisibility
    | ChangeNameRequest (Evergreen.V33.Untrusted.Untrusted Evergreen.V33.Name.Name)
    | ChangeDescriptionRequest (Evergreen.V33.Untrusted.Untrusted Evergreen.V33.Description.Description)
    | ChangeEmailAddressRequest (Evergreen.V33.Untrusted.Untrusted Evergreen.V33.EmailAddress.EmailAddress)
    | SendDeleteUserEmailRequest
    | DeleteUserRequest (Evergreen.V33.Id.Id Evergreen.V33.Id.DeleteUserToken)
    | ChangeProfileImageRequest (Evergreen.V33.Untrusted.Untrusted Evergreen.V33.ProfileImage.ProfileImage)
    | GetMyGroupsRequest
    | SearchGroupsRequest String
    | ChangeGroupNameRequest (Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId) (Evergreen.V33.Untrusted.Untrusted Evergreen.V33.GroupName.GroupName)
    | ChangeGroupDescriptionRequest (Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId) (Evergreen.V33.Untrusted.Untrusted Evergreen.V33.Description.Description)
    | CreateEventRequest (Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId) (Evergreen.V33.Untrusted.Untrusted Evergreen.V33.EventName.EventName) (Evergreen.V33.Untrusted.Untrusted Evergreen.V33.Description.Description) (Evergreen.V33.Untrusted.Untrusted Evergreen.V33.Event.EventType) Time.Posix (Evergreen.V33.Untrusted.Untrusted Evergreen.V33.EventDuration.EventDuration) (Evergreen.V33.Untrusted.Untrusted Evergreen.V33.MaxAttendees.MaxAttendees)
    | EditEventRequest (Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId) Evergreen.V33.Group.EventId (Evergreen.V33.Untrusted.Untrusted Evergreen.V33.EventName.EventName) (Evergreen.V33.Untrusted.Untrusted Evergreen.V33.Description.Description) (Evergreen.V33.Untrusted.Untrusted Evergreen.V33.Event.EventType) Time.Posix (Evergreen.V33.Untrusted.Untrusted Evergreen.V33.EventDuration.EventDuration) (Evergreen.V33.Untrusted.Untrusted Evergreen.V33.MaxAttendees.MaxAttendees)
    | JoinEventRequest (Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId) Evergreen.V33.Group.EventId
    | LeaveEventRequest (Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId) Evergreen.V33.Group.EventId
    | ChangeEventCancellationStatusRequest (Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId) Evergreen.V33.Group.EventId Evergreen.V33.Event.CancellationStatus


type Log
    = LogUntrustedCheckFailed Time.Posix ToBackend Evergreen.V33.Id.SessionIdFirst4Chars
    | LogLoginEmail Time.Posix (Result Http.Error Evergreen.V33.Postmark.PostmarkSendResponse) Evergreen.V33.EmailAddress.EmailAddress
    | LogDeleteAccountEmail Time.Posix (Result Http.Error Evergreen.V33.Postmark.PostmarkSendResponse) (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId)
    | LogEventReminderEmail Time.Posix (Result Http.Error Evergreen.V33.Postmark.PostmarkSendResponse) (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) (Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId) Evergreen.V33.Group.EventId
    | LogLoginTokenEmailRequestRateLimited Time.Posix Evergreen.V33.EmailAddress.EmailAddress Evergreen.V33.Id.SessionIdFirst4Chars
    | LogDeleteAccountEmailRequestRateLimited Time.Posix (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) Evergreen.V33.Id.SessionIdFirst4Chars


type alias AdminModel =
    { cachedEmailAddress : AssocList.Dict (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) Evergreen.V33.EmailAddress.EmailAddress
    , logs : Array.Array Log
    , lastLogCheck : Time.Posix
    }


type AdminCache
    = AdminCacheNotRequested
    | AdminCached AdminModel
    | AdminCachePending


type alias LoggedIn_ =
    { userId : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
    , emailAddress : Evergreen.V33.EmailAddress.EmailAddress
    , profileForm : Evergreen.V33.ProfilePage.Model
    , myGroups : Maybe (AssocSet.Set (Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId))
    , adminState : AdminCache
    , isAdmin : Bool
    }


type LoginStatus
    = LoginStatusPending
    | LoggedIn LoggedIn_
    | NotLoggedIn
        { showLogin : Bool
        , joiningEvent : Maybe ( Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId, Evergreen.V33.Group.EventId )
        }


type Cache item
    = ItemDoesNotExist
    | ItemCached item
    | ItemRequestPending


type alias LoginForm =
    { email : String
    , pressedSubmitEmail : Bool
    , emailSent : Maybe Evergreen.V33.EmailAddress.EmailAddress
    }


type alias LoadedFrontend =
    { navigationKey : NavigationKey
    , loginStatus : LoginStatus
    , route : Evergreen.V33.Route.Route
    , cachedGroups : AssocList.Dict (Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId) (Cache Evergreen.V33.Group.Group)
    , cachedUsers : AssocList.Dict (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) (Cache Evergreen.V33.FrontendUser.FrontendUser)
    , time : Time.Posix
    , timezone : Time.Zone
    , lastConnectionCheck : Time.Posix
    , loginForm : LoginForm
    , logs : Maybe (Array.Array Log)
    , hasLoginTokenError : Bool
    , groupForm : Evergreen.V33.CreateGroupPage.Model
    , groupCreated : Bool
    , accountDeletedResult : Maybe (Result () ())
    , searchText : String
    , searchList : List (Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId)
    , windowWidth : Quantity.Quantity Int Pixels.Pixels
    , windowHeight : Quantity.Quantity Int Pixels.Pixels
    , groupPage : AssocList.Dict (Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId) Evergreen.V33.GroupPage.Model
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias BackendUser =
    { name : Evergreen.V33.Name.Name
    , description : Evergreen.V33.Description.Description
    , emailAddress : Evergreen.V33.EmailAddress.EmailAddress
    , profileImage : Evergreen.V33.ProfileImage.ProfileImage
    , timezone : Time.Zone
    , allowEventReminders : Bool
    }


type alias LoginTokenData =
    { creationTime : Time.Posix
    , emailAddress : Evergreen.V33.EmailAddress.EmailAddress
    }


type alias DeleteUserTokenData =
    { creationTime : Time.Posix
    , userId : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
    }


type alias BackendModel =
    { users : AssocList.Dict (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) BackendUser
    , groups : AssocList.Dict (Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId) Evergreen.V33.Group.Group
    , sessions : BiDict.Assoc.BiDict Evergreen.V33.Id.SessionId (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId)
    , loginAttempts : AssocList.Dict Evergreen.V33.Id.SessionId (List.Nonempty.Nonempty Time.Posix)
    , connections : AssocList.Dict Evergreen.V33.Id.SessionId (List.Nonempty.Nonempty Evergreen.V33.Id.ClientId)
    , logs : Array.Array Log
    , time : Time.Posix
    , secretCounter : Int
    , pendingLoginTokens : AssocList.Dict (Evergreen.V33.Id.Id Evergreen.V33.Id.LoginToken) LoginTokenData
    , pendingDeleteUserTokens : AssocList.Dict (Evergreen.V33.Id.Id Evergreen.V33.Id.DeleteUserToken) DeleteUserTokenData
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
    | CreateGroupPageMsg Evergreen.V33.CreateGroupPage.Msg
    | ProfileFormMsg Evergreen.V33.ProfilePage.Msg
    | CroppedImage
        { requestId : Int
        , croppedImageUrl : String
        }
    | TypedSearchText String
    | SubmittedSearchBox
    | GroupPageMsg Evergreen.V33.GroupPage.Msg
    | GotWindowSize (Quantity.Quantity Int Pixels.Pixels) (Quantity.Quantity Int Pixels.Pixels)
    | GotTimeZone (Result TimeZone.Error ( String, Time.Zone ))
    | ScrolledToTop


type BackendMsg
    = SentLoginEmail Evergreen.V33.EmailAddress.EmailAddress (Result Http.Error Evergreen.V33.Postmark.PostmarkSendResponse)
    | SentDeleteUserEmail (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) (Result Http.Error Evergreen.V33.Postmark.PostmarkSendResponse)
    | SentEventReminderEmail (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) (Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId) Evergreen.V33.Group.EventId (Result Http.Error Evergreen.V33.Postmark.PostmarkSendResponse)
    | BackendGotTime Time.Posix
    | Connected Evergreen.V33.Id.SessionId Evergreen.V33.Id.ClientId
    | Disconnected Evergreen.V33.Id.SessionId Evergreen.V33.Id.ClientId


type GroupRequest
    = GroupNotFound_
    | GroupFound_ Evergreen.V33.Group.Group (AssocList.Dict (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) Evergreen.V33.FrontendUser.FrontendUser)


type ToFrontend
    = GetGroupResponse (Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId) GroupRequest
    | GetUserResponse (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId) (Result () Evergreen.V33.FrontendUser.FrontendUser)
    | CheckLoginResponse
        (Maybe
            { userId : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | LoginWithTokenResponse
        (Result
            ()
            { userId : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | GetAdminDataResponse AdminModel
    | CreateGroupResponse (Result Evergreen.V33.CreateGroupPage.CreateGroupError ( Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId, Evergreen.V33.Group.Group ))
    | LogoutResponse
    | ChangeNameResponse Evergreen.V33.Name.Name
    | ChangeDescriptionResponse Evergreen.V33.Description.Description
    | ChangeEmailAddressResponse Evergreen.V33.EmailAddress.EmailAddress
    | DeleteUserResponse (Result () ())
    | ChangeProfileImageResponse Evergreen.V33.ProfileImage.ProfileImage
    | GetMyGroupsResponse (List ( Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId, Evergreen.V33.Group.Group ))
    | SearchGroupsResponse String (List ( Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId, Evergreen.V33.Group.Group ))
    | ChangeGroupNameResponse (Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId) Evergreen.V33.GroupName.GroupName
    | ChangeGroupDescriptionResponse (Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId) Evergreen.V33.Description.Description
    | CreateEventResponse (Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId) (Result Evergreen.V33.GroupPage.CreateEventError Evergreen.V33.Event.Event)
    | EditEventResponse (Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId) Evergreen.V33.Group.EventId (Result Evergreen.V33.Group.EditEventError Evergreen.V33.Event.Event) Time.Posix
    | JoinEventResponse (Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId) Evergreen.V33.Group.EventId (Result Evergreen.V33.Group.JoinEventError ())
    | LeaveEventResponse (Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId) Evergreen.V33.Group.EventId (Result () ())
    | ChangeEventCancellationStatusResponse (Evergreen.V33.Id.Id Evergreen.V33.Id.GroupId) Evergreen.V33.Group.EventId (Result Evergreen.V33.Group.EditCancellationStatusError Evergreen.V33.Event.CancellationStatus) Time.Posix
