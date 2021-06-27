module Evergreen.V30.Types exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc
import Browser
import Browser.Navigation
import Evergreen.V30.CreateGroupPage
import Evergreen.V30.Description
import Evergreen.V30.EmailAddress
import Evergreen.V30.Event
import Evergreen.V30.EventDuration
import Evergreen.V30.EventName
import Evergreen.V30.FrontendUser
import Evergreen.V30.Group
import Evergreen.V30.GroupName
import Evergreen.V30.GroupPage
import Evergreen.V30.Id
import Evergreen.V30.MaxAttendees
import Evergreen.V30.Name
import Evergreen.V30.Postmark
import Evergreen.V30.ProfileImage
import Evergreen.V30.ProfilePage
import Evergreen.V30.Route
import Evergreen.V30.Untrusted
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
    , route : Evergreen.V30.Route.Route
    , routeToken : Evergreen.V30.Route.Token
    , windowSize : Maybe ( Quantity.Quantity Int Pixels.Pixels, Quantity.Quantity Int Pixels.Pixels )
    , time : Maybe Time.Posix
    , timezone : Maybe Time.Zone
    }


type ToBackend
    = GetGroupRequest (Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId)
    | GetUserRequest (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
    | CheckLoginRequest
    | LoginWithTokenRequest (Evergreen.V30.Id.Id Evergreen.V30.Id.LoginToken) (Maybe ( Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId, Evergreen.V30.Group.EventId ))
    | GetLoginTokenRequest Evergreen.V30.Route.Route (Evergreen.V30.Untrusted.Untrusted Evergreen.V30.EmailAddress.EmailAddress) (Maybe ( Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId, Evergreen.V30.Group.EventId ))
    | GetAdminDataRequest
    | LogoutRequest
    | CreateGroupRequest (Evergreen.V30.Untrusted.Untrusted Evergreen.V30.GroupName.GroupName) (Evergreen.V30.Untrusted.Untrusted Evergreen.V30.Description.Description) Evergreen.V30.Group.GroupVisibility
    | ChangeNameRequest (Evergreen.V30.Untrusted.Untrusted Evergreen.V30.Name.Name)
    | ChangeDescriptionRequest (Evergreen.V30.Untrusted.Untrusted Evergreen.V30.Description.Description)
    | ChangeEmailAddressRequest (Evergreen.V30.Untrusted.Untrusted Evergreen.V30.EmailAddress.EmailAddress)
    | SendDeleteUserEmailRequest
    | DeleteUserRequest (Evergreen.V30.Id.Id Evergreen.V30.Id.DeleteUserToken)
    | ChangeProfileImageRequest (Evergreen.V30.Untrusted.Untrusted Evergreen.V30.ProfileImage.ProfileImage)
    | GetMyGroupsRequest
    | SearchGroupsRequest String
    | ChangeGroupNameRequest (Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId) (Evergreen.V30.Untrusted.Untrusted Evergreen.V30.GroupName.GroupName)
    | ChangeGroupDescriptionRequest (Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId) (Evergreen.V30.Untrusted.Untrusted Evergreen.V30.Description.Description)
    | CreateEventRequest (Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId) (Evergreen.V30.Untrusted.Untrusted Evergreen.V30.EventName.EventName) (Evergreen.V30.Untrusted.Untrusted Evergreen.V30.Description.Description) (Evergreen.V30.Untrusted.Untrusted Evergreen.V30.Event.EventType) Time.Posix (Evergreen.V30.Untrusted.Untrusted Evergreen.V30.EventDuration.EventDuration) (Evergreen.V30.Untrusted.Untrusted Evergreen.V30.MaxAttendees.MaxAttendees)
    | EditEventRequest (Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId) Evergreen.V30.Group.EventId (Evergreen.V30.Untrusted.Untrusted Evergreen.V30.EventName.EventName) (Evergreen.V30.Untrusted.Untrusted Evergreen.V30.Description.Description) (Evergreen.V30.Untrusted.Untrusted Evergreen.V30.Event.EventType) Time.Posix (Evergreen.V30.Untrusted.Untrusted Evergreen.V30.EventDuration.EventDuration) (Evergreen.V30.Untrusted.Untrusted Evergreen.V30.MaxAttendees.MaxAttendees)
    | JoinEventRequest (Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId) Evergreen.V30.Group.EventId
    | LeaveEventRequest (Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId) Evergreen.V30.Group.EventId
    | ChangeEventCancellationStatusRequest (Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId) Evergreen.V30.Group.EventId Evergreen.V30.Event.CancellationStatus


type Log
    = LogUntrustedCheckFailed Time.Posix ToBackend Evergreen.V30.Id.SessionIdFirst4Chars
    | LogLoginEmail Time.Posix (Result Http.Error Evergreen.V30.Postmark.PostmarkSendResponse) Evergreen.V30.EmailAddress.EmailAddress
    | LogDeleteAccountEmail Time.Posix (Result Http.Error Evergreen.V30.Postmark.PostmarkSendResponse) (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
    | LogEventReminderEmail Time.Posix (Result Http.Error Evergreen.V30.Postmark.PostmarkSendResponse) (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) (Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId) Evergreen.V30.Group.EventId
    | LogLoginTokenEmailRequestRateLimited Time.Posix Evergreen.V30.EmailAddress.EmailAddress Evergreen.V30.Id.SessionIdFirst4Chars
    | LogDeleteAccountEmailRequestRateLimited Time.Posix (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) Evergreen.V30.Id.SessionIdFirst4Chars


type alias AdminModel =
    { cachedEmailAddress : AssocList.Dict (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) Evergreen.V30.EmailAddress.EmailAddress
    , logs : Array.Array Log
    , lastLogCheck : Time.Posix
    }


type AdminCache
    = AdminCacheNotRequested
    | AdminCached AdminModel
    | AdminCachePending


type alias LoggedIn_ =
    { userId : Evergreen.V30.Id.Id Evergreen.V30.Id.UserId
    , emailAddress : Evergreen.V30.EmailAddress.EmailAddress
    , profileForm : Evergreen.V30.ProfilePage.Model
    , myGroups : Maybe (AssocSet.Set (Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId))
    , adminState : AdminCache
    , isAdmin : Bool
    }


type LoginStatus
    = LoginStatusPending
    | LoggedIn LoggedIn_
    | NotLoggedIn
        { showLogin : Bool
        , joiningEvent : Maybe ( Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId, Evergreen.V30.Group.EventId )
        }


type Cache item
    = ItemDoesNotExist
    | ItemCached item
    | ItemRequestPending


type alias LoginForm =
    { email : String
    , pressedSubmitEmail : Bool
    , emailSent : Maybe Evergreen.V30.EmailAddress.EmailAddress
    }


type alias LoadedFrontend =
    { navigationKey : NavigationKey
    , loginStatus : LoginStatus
    , route : Evergreen.V30.Route.Route
    , cachedGroups : AssocList.Dict (Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId) (Cache Evergreen.V30.Group.Group)
    , cachedUsers : AssocList.Dict (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) (Cache Evergreen.V30.FrontendUser.FrontendUser)
    , time : Time.Posix
    , timezone : Time.Zone
    , lastConnectionCheck : Time.Posix
    , loginForm : LoginForm
    , logs : Maybe (Array.Array Log)
    , hasLoginTokenError : Bool
    , groupForm : Evergreen.V30.CreateGroupPage.Model
    , groupCreated : Bool
    , accountDeletedResult : Maybe (Result () ())
    , searchText : String
    , searchList : List (Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId)
    , windowWidth : Quantity.Quantity Int Pixels.Pixels
    , windowHeight : Quantity.Quantity Int Pixels.Pixels
    , groupPage : AssocList.Dict (Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId) Evergreen.V30.GroupPage.Model
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias BackendUser =
    { name : Evergreen.V30.Name.Name
    , description : Evergreen.V30.Description.Description
    , emailAddress : Evergreen.V30.EmailAddress.EmailAddress
    , profileImage : Evergreen.V30.ProfileImage.ProfileImage
    , timezone : Time.Zone
    , allowEventReminders : Bool
    }


type alias LoginTokenData =
    { creationTime : Time.Posix
    , emailAddress : Evergreen.V30.EmailAddress.EmailAddress
    }


type alias DeleteUserTokenData =
    { creationTime : Time.Posix
    , userId : Evergreen.V30.Id.Id Evergreen.V30.Id.UserId
    }


type alias BackendModel =
    { users : AssocList.Dict (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) BackendUser
    , groups : AssocList.Dict (Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId) Evergreen.V30.Group.Group
    , sessions : BiDict.Assoc.BiDict Evergreen.V30.Id.SessionId (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
    , loginAttempts : AssocList.Dict Evergreen.V30.Id.SessionId (List.Nonempty.Nonempty Time.Posix)
    , connections : AssocList.Dict Evergreen.V30.Id.SessionId (List.Nonempty.Nonempty Evergreen.V30.Id.ClientId)
    , logs : Array.Array Log
    , time : Time.Posix
    , secretCounter : Int
    , pendingLoginTokens : AssocList.Dict (Evergreen.V30.Id.Id Evergreen.V30.Id.LoginToken) LoginTokenData
    , pendingDeleteUserTokens : AssocList.Dict (Evergreen.V30.Id.Id Evergreen.V30.Id.DeleteUserToken) DeleteUserTokenData
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
    | CreateGroupPageMsg Evergreen.V30.CreateGroupPage.Msg
    | ProfileFormMsg Evergreen.V30.ProfilePage.Msg
    | CroppedImage
        { requestId : Int
        , croppedImageUrl : String
        }
    | TypedSearchText String
    | SubmittedSearchBox
    | GroupPageMsg Evergreen.V30.GroupPage.Msg
    | GotWindowSize (Quantity.Quantity Int Pixels.Pixels) (Quantity.Quantity Int Pixels.Pixels)
    | GotTimeZone (Result TimeZone.Error ( String, Time.Zone ))
    | ScrolledToTop


type BackendMsg
    = SentLoginEmail Evergreen.V30.EmailAddress.EmailAddress (Result Http.Error Evergreen.V30.Postmark.PostmarkSendResponse)
    | SentDeleteUserEmail (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) (Result Http.Error Evergreen.V30.Postmark.PostmarkSendResponse)
    | SentEventReminderEmail (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) (Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId) Evergreen.V30.Group.EventId (Result Http.Error Evergreen.V30.Postmark.PostmarkSendResponse)
    | BackendGotTime Time.Posix
    | Connected Evergreen.V30.Id.SessionId Evergreen.V30.Id.ClientId
    | Disconnected Evergreen.V30.Id.SessionId Evergreen.V30.Id.ClientId


type GroupRequest
    = GroupNotFound_
    | GroupFound_ Evergreen.V30.Group.Group (AssocList.Dict (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) Evergreen.V30.FrontendUser.FrontendUser)


type ToFrontend
    = GetGroupResponse (Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId) GroupRequest
    | GetUserResponse (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId) (Result () Evergreen.V30.FrontendUser.FrontendUser)
    | CheckLoginResponse
        (Maybe
            { userId : Evergreen.V30.Id.Id Evergreen.V30.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | LoginWithTokenResponse
        (Result
            ()
            { userId : Evergreen.V30.Id.Id Evergreen.V30.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | GetAdminDataResponse AdminModel
    | CreateGroupResponse (Result Evergreen.V30.CreateGroupPage.CreateGroupError ( Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId, Evergreen.V30.Group.Group ))
    | LogoutResponse
    | ChangeNameResponse Evergreen.V30.Name.Name
    | ChangeDescriptionResponse Evergreen.V30.Description.Description
    | ChangeEmailAddressResponse Evergreen.V30.EmailAddress.EmailAddress
    | DeleteUserResponse (Result () ())
    | ChangeProfileImageResponse Evergreen.V30.ProfileImage.ProfileImage
    | GetMyGroupsResponse (List ( Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId, Evergreen.V30.Group.Group ))
    | SearchGroupsResponse String (List ( Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId, Evergreen.V30.Group.Group ))
    | ChangeGroupNameResponse (Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId) Evergreen.V30.GroupName.GroupName
    | ChangeGroupDescriptionResponse (Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId) Evergreen.V30.Description.Description
    | CreateEventResponse (Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId) (Result Evergreen.V30.GroupPage.CreateEventError Evergreen.V30.Event.Event)
    | EditEventResponse (Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId) Evergreen.V30.Group.EventId (Result Evergreen.V30.Group.EditEventError Evergreen.V30.Event.Event) Time.Posix
    | JoinEventResponse (Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId) Evergreen.V30.Group.EventId (Result Evergreen.V30.Group.JoinEventError ())
    | LeaveEventResponse (Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId) Evergreen.V30.Group.EventId (Result () ())
    | ChangeEventCancellationStatusResponse (Evergreen.V30.Id.Id Evergreen.V30.Id.GroupId) Evergreen.V30.Group.EventId (Result Evergreen.V30.Group.EditCancellationStatusError Evergreen.V30.Event.CancellationStatus) Time.Posix
