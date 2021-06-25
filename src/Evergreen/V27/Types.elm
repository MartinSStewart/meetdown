module Evergreen.V27.Types exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc
import Browser
import Browser.Navigation
import Evergreen.V27.CreateGroupPage
import Evergreen.V27.Description
import Evergreen.V27.EmailAddress
import Evergreen.V27.Event
import Evergreen.V27.EventDuration
import Evergreen.V27.EventName
import Evergreen.V27.FrontendUser
import Evergreen.V27.Group
import Evergreen.V27.GroupName
import Evergreen.V27.GroupPage
import Evergreen.V27.Id
import Evergreen.V27.MaxAttendees
import Evergreen.V27.Name
import Evergreen.V27.Postmark
import Evergreen.V27.ProfileImage
import Evergreen.V27.ProfilePage
import Evergreen.V27.Route
import Evergreen.V27.Untrusted
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
    , route : Evergreen.V27.Route.Route
    , routeToken : Evergreen.V27.Route.Token
    , windowSize : Maybe ( Quantity.Quantity Int Pixels.Pixels, Quantity.Quantity Int Pixels.Pixels )
    , time : Maybe Time.Posix
    , timezone : Maybe Time.Zone
    }


type ToBackend
    = GetGroupRequest (Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId)
    | GetUserRequest (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)
    | CheckLoginRequest
    | LoginWithTokenRequest (Evergreen.V27.Id.Id Evergreen.V27.Id.LoginToken) (Maybe ( Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId, Evergreen.V27.Group.EventId ))
    | GetLoginTokenRequest Evergreen.V27.Route.Route (Evergreen.V27.Untrusted.Untrusted Evergreen.V27.EmailAddress.EmailAddress) (Maybe ( Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId, Evergreen.V27.Group.EventId ))
    | GetAdminDataRequest
    | LogoutRequest
    | CreateGroupRequest (Evergreen.V27.Untrusted.Untrusted Evergreen.V27.GroupName.GroupName) (Evergreen.V27.Untrusted.Untrusted Evergreen.V27.Description.Description) Evergreen.V27.Group.GroupVisibility
    | ChangeNameRequest (Evergreen.V27.Untrusted.Untrusted Evergreen.V27.Name.Name)
    | ChangeDescriptionRequest (Evergreen.V27.Untrusted.Untrusted Evergreen.V27.Description.Description)
    | ChangeEmailAddressRequest (Evergreen.V27.Untrusted.Untrusted Evergreen.V27.EmailAddress.EmailAddress)
    | SendDeleteUserEmailRequest
    | DeleteUserRequest (Evergreen.V27.Id.Id Evergreen.V27.Id.DeleteUserToken)
    | ChangeProfileImageRequest (Evergreen.V27.Untrusted.Untrusted Evergreen.V27.ProfileImage.ProfileImage)
    | GetMyGroupsRequest
    | SearchGroupsRequest String
    | ChangeGroupNameRequest (Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId) (Evergreen.V27.Untrusted.Untrusted Evergreen.V27.GroupName.GroupName)
    | ChangeGroupDescriptionRequest (Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId) (Evergreen.V27.Untrusted.Untrusted Evergreen.V27.Description.Description)
    | CreateEventRequest (Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId) (Evergreen.V27.Untrusted.Untrusted Evergreen.V27.EventName.EventName) (Evergreen.V27.Untrusted.Untrusted Evergreen.V27.Description.Description) (Evergreen.V27.Untrusted.Untrusted Evergreen.V27.Event.EventType) Time.Posix (Evergreen.V27.Untrusted.Untrusted Evergreen.V27.EventDuration.EventDuration) (Evergreen.V27.Untrusted.Untrusted Evergreen.V27.MaxAttendees.MaxAttendees)
    | EditEventRequest (Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId) Evergreen.V27.Group.EventId (Evergreen.V27.Untrusted.Untrusted Evergreen.V27.EventName.EventName) (Evergreen.V27.Untrusted.Untrusted Evergreen.V27.Description.Description) (Evergreen.V27.Untrusted.Untrusted Evergreen.V27.Event.EventType) Time.Posix (Evergreen.V27.Untrusted.Untrusted Evergreen.V27.EventDuration.EventDuration) (Evergreen.V27.Untrusted.Untrusted Evergreen.V27.MaxAttendees.MaxAttendees)
    | JoinEventRequest (Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId) Evergreen.V27.Group.EventId
    | LeaveEventRequest (Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId) Evergreen.V27.Group.EventId
    | ChangeEventCancellationStatusRequest (Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId) Evergreen.V27.Group.EventId Evergreen.V27.Event.CancellationStatus


type Log
    = LogUntrustedCheckFailed Time.Posix ToBackend Evergreen.V27.Id.SessionIdFirst4Chars
    | LogLoginEmail Time.Posix (Result Http.Error Evergreen.V27.Postmark.PostmarkSendResponse) Evergreen.V27.EmailAddress.EmailAddress
    | LogDeleteAccountEmail Time.Posix (Result Http.Error Evergreen.V27.Postmark.PostmarkSendResponse) (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)
    | LogEventReminderEmail Time.Posix (Result Http.Error Evergreen.V27.Postmark.PostmarkSendResponse) (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) (Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId) Evergreen.V27.Group.EventId
    | LogLoginTokenEmailRequestRateLimited Time.Posix Evergreen.V27.EmailAddress.EmailAddress Evergreen.V27.Id.SessionIdFirst4Chars
    | LogDeleteAccountEmailRequestRateLimited Time.Posix (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.Id.SessionIdFirst4Chars


type alias AdminModel =
    { cachedEmailAddress : AssocList.Dict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.EmailAddress.EmailAddress
    , logs : Array.Array Log
    , lastLogCheck : Time.Posix
    }


type AdminCache
    = AdminCacheNotRequested
    | AdminCached AdminModel
    | AdminCachePending


type alias LoggedIn_ =
    { userId : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
    , emailAddress : Evergreen.V27.EmailAddress.EmailAddress
    , profileForm : Evergreen.V27.ProfilePage.Model
    , myGroups : Maybe (AssocSet.Set (Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId))
    , adminState : AdminCache
    , isAdmin : Bool
    }


type LoginStatus
    = LoginStatusPending
    | LoggedIn LoggedIn_
    | NotLoggedIn
        { showLogin : Bool
        , joiningEvent : Maybe ( Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId, Evergreen.V27.Group.EventId )
        }


type Cache item
    = ItemDoesNotExist
    | ItemCached item
    | ItemRequestPending


type alias LoginForm =
    { email : String
    , pressedSubmitEmail : Bool
    , emailSent : Maybe Evergreen.V27.EmailAddress.EmailAddress
    }


type alias LoadedFrontend =
    { navigationKey : NavigationKey
    , loginStatus : LoginStatus
    , route : Evergreen.V27.Route.Route
    , cachedGroups : AssocList.Dict (Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId) (Cache Evergreen.V27.Group.Group)
    , cachedUsers : AssocList.Dict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) (Cache Evergreen.V27.FrontendUser.FrontendUser)
    , time : Time.Posix
    , timezone : Time.Zone
    , lastConnectionCheck : Time.Posix
    , loginForm : LoginForm
    , logs : Maybe (Array.Array Log)
    , hasLoginTokenError : Bool
    , groupForm : Evergreen.V27.CreateGroupPage.Model
    , groupCreated : Bool
    , accountDeletedResult : Maybe (Result () ())
    , searchText : String
    , searchList : List (Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId)
    , windowWidth : Quantity.Quantity Int Pixels.Pixels
    , windowHeight : Quantity.Quantity Int Pixels.Pixels
    , groupPage : AssocList.Dict (Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId) Evergreen.V27.GroupPage.Model
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias BackendUser =
    { name : Evergreen.V27.Name.Name
    , description : Evergreen.V27.Description.Description
    , emailAddress : Evergreen.V27.EmailAddress.EmailAddress
    , profileImage : Evergreen.V27.ProfileImage.ProfileImage
    , timezone : Time.Zone
    , allowEventReminders : Bool
    }


type alias LoginTokenData =
    { creationTime : Time.Posix
    , emailAddress : Evergreen.V27.EmailAddress.EmailAddress
    }


type alias DeleteUserTokenData =
    { creationTime : Time.Posix
    , userId : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
    }


type alias BackendModel =
    { users : AssocList.Dict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) BackendUser
    , groups : AssocList.Dict (Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId) Evergreen.V27.Group.Group
    , sessions : BiDict.Assoc.BiDict Evergreen.V27.Id.SessionId (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)
    , loginAttempts : AssocList.Dict Evergreen.V27.Id.SessionId (List.Nonempty.Nonempty Time.Posix)
    , connections : AssocList.Dict Evergreen.V27.Id.SessionId (List.Nonempty.Nonempty Evergreen.V27.Id.ClientId)
    , logs : Array.Array Log
    , time : Time.Posix
    , secretCounter : Int
    , pendingLoginTokens : AssocList.Dict (Evergreen.V27.Id.Id Evergreen.V27.Id.LoginToken) LoginTokenData
    , pendingDeleteUserTokens : AssocList.Dict (Evergreen.V27.Id.Id Evergreen.V27.Id.DeleteUserToken) DeleteUserTokenData
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
    | GroupFormMsg Evergreen.V27.CreateGroupPage.Msg
    | ProfileFormMsg Evergreen.V27.ProfilePage.Msg
    | CroppedImage
        { requestId : Int
        , croppedImageUrl : String
        }
    | TypedSearchText String
    | SubmittedSearchBox
    | GroupPageMsg Evergreen.V27.GroupPage.Msg
    | GotWindowSize (Quantity.Quantity Int Pixels.Pixels) (Quantity.Quantity Int Pixels.Pixels)
    | GotTimeZone (Result TimeZone.Error ( String, Time.Zone ))


type BackendMsg
    = SentLoginEmail Evergreen.V27.EmailAddress.EmailAddress (Result Http.Error Evergreen.V27.Postmark.PostmarkSendResponse)
    | SentDeleteUserEmail (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) (Result Http.Error Evergreen.V27.Postmark.PostmarkSendResponse)
    | SentEventReminderEmail (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) (Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId) Evergreen.V27.Group.EventId (Result Http.Error Evergreen.V27.Postmark.PostmarkSendResponse)
    | BackendGotTime Time.Posix
    | Connected Evergreen.V27.Id.SessionId Evergreen.V27.Id.ClientId
    | Disconnected Evergreen.V27.Id.SessionId Evergreen.V27.Id.ClientId


type GroupRequest
    = GroupNotFound_
    | GroupFound_ Evergreen.V27.Group.Group (AssocList.Dict (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) Evergreen.V27.FrontendUser.FrontendUser)


type ToFrontend
    = GetGroupResponse (Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId) GroupRequest
    | GetUserResponse (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId) (Result () Evergreen.V27.FrontendUser.FrontendUser)
    | CheckLoginResponse
        (Maybe
            { userId : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | LoginWithTokenResponse
        (Result
            ()
            { userId : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | GetAdminDataResponse AdminModel
    | CreateGroupResponse (Result Evergreen.V27.CreateGroupPage.CreateGroupError ( Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId, Evergreen.V27.Group.Group ))
    | LogoutResponse
    | ChangeNameResponse Evergreen.V27.Name.Name
    | ChangeDescriptionResponse Evergreen.V27.Description.Description
    | ChangeEmailAddressResponse Evergreen.V27.EmailAddress.EmailAddress
    | DeleteUserResponse (Result () ())
    | ChangeProfileImageResponse Evergreen.V27.ProfileImage.ProfileImage
    | GetMyGroupsResponse (List ( Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId, Evergreen.V27.Group.Group ))
    | SearchGroupsResponse String (List ( Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId, Evergreen.V27.Group.Group ))
    | ChangeGroupNameResponse (Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId) Evergreen.V27.GroupName.GroupName
    | ChangeGroupDescriptionResponse (Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId) Evergreen.V27.Description.Description
    | CreateEventResponse (Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId) (Result Evergreen.V27.GroupPage.CreateEventError Evergreen.V27.Event.Event)
    | EditEventResponse (Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId) Evergreen.V27.Group.EventId (Result Evergreen.V27.Group.EditEventError Evergreen.V27.Event.Event) Time.Posix
    | JoinEventResponse (Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId) Evergreen.V27.Group.EventId (Result Evergreen.V27.Group.JoinEventError ())
    | LeaveEventResponse (Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId) Evergreen.V27.Group.EventId (Result () ())
    | ChangeEventCancellationStatusResponse (Evergreen.V27.Id.Id Evergreen.V27.Id.GroupId) Evergreen.V27.Group.EventId (Result Evergreen.V27.Group.EditCancellationStatusError Evergreen.V27.Event.CancellationStatus) Time.Posix
