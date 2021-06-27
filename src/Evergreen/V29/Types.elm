module Evergreen.V29.Types exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc
import Browser
import Browser.Navigation
import Evergreen.V29.CreateGroupPage
import Evergreen.V29.Description
import Evergreen.V29.EmailAddress
import Evergreen.V29.Event
import Evergreen.V29.EventDuration
import Evergreen.V29.EventName
import Evergreen.V29.FrontendUser
import Evergreen.V29.Group
import Evergreen.V29.GroupName
import Evergreen.V29.GroupPage
import Evergreen.V29.Id
import Evergreen.V29.MaxAttendees
import Evergreen.V29.Name
import Evergreen.V29.Postmark
import Evergreen.V29.ProfileImage
import Evergreen.V29.ProfilePage
import Evergreen.V29.Route
import Evergreen.V29.Untrusted
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
    , route : Evergreen.V29.Route.Route
    , routeToken : Evergreen.V29.Route.Token
    , windowSize : Maybe ( Quantity.Quantity Int Pixels.Pixels, Quantity.Quantity Int Pixels.Pixels )
    , time : Maybe Time.Posix
    , timezone : Maybe Time.Zone
    }


type ToBackend
    = GetGroupRequest (Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId)
    | GetUserRequest (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)
    | CheckLoginRequest
    | LoginWithTokenRequest (Evergreen.V29.Id.Id Evergreen.V29.Id.LoginToken) (Maybe ( Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId, Evergreen.V29.Group.EventId ))
    | GetLoginTokenRequest Evergreen.V29.Route.Route (Evergreen.V29.Untrusted.Untrusted Evergreen.V29.EmailAddress.EmailAddress) (Maybe ( Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId, Evergreen.V29.Group.EventId ))
    | GetAdminDataRequest
    | LogoutRequest
    | CreateGroupRequest (Evergreen.V29.Untrusted.Untrusted Evergreen.V29.GroupName.GroupName) (Evergreen.V29.Untrusted.Untrusted Evergreen.V29.Description.Description) Evergreen.V29.Group.GroupVisibility
    | ChangeNameRequest (Evergreen.V29.Untrusted.Untrusted Evergreen.V29.Name.Name)
    | ChangeDescriptionRequest (Evergreen.V29.Untrusted.Untrusted Evergreen.V29.Description.Description)
    | ChangeEmailAddressRequest (Evergreen.V29.Untrusted.Untrusted Evergreen.V29.EmailAddress.EmailAddress)
    | SendDeleteUserEmailRequest
    | DeleteUserRequest (Evergreen.V29.Id.Id Evergreen.V29.Id.DeleteUserToken)
    | ChangeProfileImageRequest (Evergreen.V29.Untrusted.Untrusted Evergreen.V29.ProfileImage.ProfileImage)
    | GetMyGroupsRequest
    | SearchGroupsRequest String
    | ChangeGroupNameRequest (Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId) (Evergreen.V29.Untrusted.Untrusted Evergreen.V29.GroupName.GroupName)
    | ChangeGroupDescriptionRequest (Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId) (Evergreen.V29.Untrusted.Untrusted Evergreen.V29.Description.Description)
    | CreateEventRequest (Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId) (Evergreen.V29.Untrusted.Untrusted Evergreen.V29.EventName.EventName) (Evergreen.V29.Untrusted.Untrusted Evergreen.V29.Description.Description) (Evergreen.V29.Untrusted.Untrusted Evergreen.V29.Event.EventType) Time.Posix (Evergreen.V29.Untrusted.Untrusted Evergreen.V29.EventDuration.EventDuration) (Evergreen.V29.Untrusted.Untrusted Evergreen.V29.MaxAttendees.MaxAttendees)
    | EditEventRequest (Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId) Evergreen.V29.Group.EventId (Evergreen.V29.Untrusted.Untrusted Evergreen.V29.EventName.EventName) (Evergreen.V29.Untrusted.Untrusted Evergreen.V29.Description.Description) (Evergreen.V29.Untrusted.Untrusted Evergreen.V29.Event.EventType) Time.Posix (Evergreen.V29.Untrusted.Untrusted Evergreen.V29.EventDuration.EventDuration) (Evergreen.V29.Untrusted.Untrusted Evergreen.V29.MaxAttendees.MaxAttendees)
    | JoinEventRequest (Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId) Evergreen.V29.Group.EventId
    | LeaveEventRequest (Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId) Evergreen.V29.Group.EventId
    | ChangeEventCancellationStatusRequest (Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId) Evergreen.V29.Group.EventId Evergreen.V29.Event.CancellationStatus


type Log
    = LogUntrustedCheckFailed Time.Posix ToBackend Evergreen.V29.Id.SessionIdFirst4Chars
    | LogLoginEmail Time.Posix (Result Http.Error Evergreen.V29.Postmark.PostmarkSendResponse) Evergreen.V29.EmailAddress.EmailAddress
    | LogDeleteAccountEmail Time.Posix (Result Http.Error Evergreen.V29.Postmark.PostmarkSendResponse) (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)
    | LogEventReminderEmail Time.Posix (Result Http.Error Evergreen.V29.Postmark.PostmarkSendResponse) (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) (Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId) Evergreen.V29.Group.EventId
    | LogLoginTokenEmailRequestRateLimited Time.Posix Evergreen.V29.EmailAddress.EmailAddress Evergreen.V29.Id.SessionIdFirst4Chars
    | LogDeleteAccountEmailRequestRateLimited Time.Posix (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.Id.SessionIdFirst4Chars


type alias AdminModel =
    { cachedEmailAddress : AssocList.Dict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.EmailAddress.EmailAddress
    , logs : Array.Array Log
    , lastLogCheck : Time.Posix
    }


type AdminCache
    = AdminCacheNotRequested
    | AdminCached AdminModel
    | AdminCachePending


type alias LoggedIn_ =
    { userId : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    , emailAddress : Evergreen.V29.EmailAddress.EmailAddress
    , profileForm : Evergreen.V29.ProfilePage.Model
    , myGroups : Maybe (AssocSet.Set (Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId))
    , adminState : AdminCache
    , isAdmin : Bool
    }


type LoginStatus
    = LoginStatusPending
    | LoggedIn LoggedIn_
    | NotLoggedIn
        { showLogin : Bool
        , joiningEvent : Maybe ( Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId, Evergreen.V29.Group.EventId )
        }


type Cache item
    = ItemDoesNotExist
    | ItemCached item
    | ItemRequestPending


type alias LoginForm =
    { email : String
    , pressedSubmitEmail : Bool
    , emailSent : Maybe Evergreen.V29.EmailAddress.EmailAddress
    }


type alias LoadedFrontend =
    { navigationKey : NavigationKey
    , loginStatus : LoginStatus
    , route : Evergreen.V29.Route.Route
    , cachedGroups : AssocList.Dict (Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId) (Cache Evergreen.V29.Group.Group)
    , cachedUsers : AssocList.Dict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) (Cache Evergreen.V29.FrontendUser.FrontendUser)
    , time : Time.Posix
    , timezone : Time.Zone
    , lastConnectionCheck : Time.Posix
    , loginForm : LoginForm
    , logs : Maybe (Array.Array Log)
    , hasLoginTokenError : Bool
    , groupForm : Evergreen.V29.CreateGroupPage.Model
    , groupCreated : Bool
    , accountDeletedResult : Maybe (Result () ())
    , searchText : String
    , searchList : List (Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId)
    , windowWidth : Quantity.Quantity Int Pixels.Pixels
    , windowHeight : Quantity.Quantity Int Pixels.Pixels
    , groupPage : AssocList.Dict (Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId) Evergreen.V29.GroupPage.Model
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias BackendUser =
    { name : Evergreen.V29.Name.Name
    , description : Evergreen.V29.Description.Description
    , emailAddress : Evergreen.V29.EmailAddress.EmailAddress
    , profileImage : Evergreen.V29.ProfileImage.ProfileImage
    , timezone : Time.Zone
    , allowEventReminders : Bool
    }


type alias LoginTokenData =
    { creationTime : Time.Posix
    , emailAddress : Evergreen.V29.EmailAddress.EmailAddress
    }


type alias DeleteUserTokenData =
    { creationTime : Time.Posix
    , userId : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
    }


type alias BackendModel =
    { users : AssocList.Dict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) BackendUser
    , groups : AssocList.Dict (Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId) Evergreen.V29.Group.Group
    , sessions : BiDict.Assoc.BiDict Evergreen.V29.Id.SessionId (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)
    , loginAttempts : AssocList.Dict Evergreen.V29.Id.SessionId (List.Nonempty.Nonempty Time.Posix)
    , connections : AssocList.Dict Evergreen.V29.Id.SessionId (List.Nonempty.Nonempty Evergreen.V29.Id.ClientId)
    , logs : Array.Array Log
    , time : Time.Posix
    , secretCounter : Int
    , pendingLoginTokens : AssocList.Dict (Evergreen.V29.Id.Id Evergreen.V29.Id.LoginToken) LoginTokenData
    , pendingDeleteUserTokens : AssocList.Dict (Evergreen.V29.Id.Id Evergreen.V29.Id.DeleteUserToken) DeleteUserTokenData
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
    | CreateGroupPageMsg Evergreen.V29.CreateGroupPage.Msg
    | ProfileFormMsg Evergreen.V29.ProfilePage.Msg
    | CroppedImage
        { requestId : Int
        , croppedImageUrl : String
        }
    | TypedSearchText String
    | SubmittedSearchBox
    | GroupPageMsg Evergreen.V29.GroupPage.Msg
    | GotWindowSize (Quantity.Quantity Int Pixels.Pixels) (Quantity.Quantity Int Pixels.Pixels)
    | GotTimeZone (Result TimeZone.Error ( String, Time.Zone ))


type BackendMsg
    = SentLoginEmail Evergreen.V29.EmailAddress.EmailAddress (Result Http.Error Evergreen.V29.Postmark.PostmarkSendResponse)
    | SentDeleteUserEmail (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) (Result Http.Error Evergreen.V29.Postmark.PostmarkSendResponse)
    | SentEventReminderEmail (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) (Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId) Evergreen.V29.Group.EventId (Result Http.Error Evergreen.V29.Postmark.PostmarkSendResponse)
    | BackendGotTime Time.Posix
    | Connected Evergreen.V29.Id.SessionId Evergreen.V29.Id.ClientId
    | Disconnected Evergreen.V29.Id.SessionId Evergreen.V29.Id.ClientId


type GroupRequest
    = GroupNotFound_
    | GroupFound_ Evergreen.V29.Group.Group (AssocList.Dict (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) Evergreen.V29.FrontendUser.FrontendUser)


type ToFrontend
    = GetGroupResponse (Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId) GroupRequest
    | GetUserResponse (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId) (Result () Evergreen.V29.FrontendUser.FrontendUser)
    | CheckLoginResponse
        (Maybe
            { userId : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | LoginWithTokenResponse
        (Result
            ()
            { userId : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | GetAdminDataResponse AdminModel
    | CreateGroupResponse (Result Evergreen.V29.CreateGroupPage.CreateGroupError ( Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId, Evergreen.V29.Group.Group ))
    | LogoutResponse
    | ChangeNameResponse Evergreen.V29.Name.Name
    | ChangeDescriptionResponse Evergreen.V29.Description.Description
    | ChangeEmailAddressResponse Evergreen.V29.EmailAddress.EmailAddress
    | DeleteUserResponse (Result () ())
    | ChangeProfileImageResponse Evergreen.V29.ProfileImage.ProfileImage
    | GetMyGroupsResponse (List ( Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId, Evergreen.V29.Group.Group ))
    | SearchGroupsResponse String (List ( Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId, Evergreen.V29.Group.Group ))
    | ChangeGroupNameResponse (Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId) Evergreen.V29.GroupName.GroupName
    | ChangeGroupDescriptionResponse (Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId) Evergreen.V29.Description.Description
    | CreateEventResponse (Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId) (Result Evergreen.V29.GroupPage.CreateEventError Evergreen.V29.Event.Event)
    | EditEventResponse (Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId) Evergreen.V29.Group.EventId (Result Evergreen.V29.Group.EditEventError Evergreen.V29.Event.Event) Time.Posix
    | JoinEventResponse (Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId) Evergreen.V29.Group.EventId (Result Evergreen.V29.Group.JoinEventError ())
    | LeaveEventResponse (Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId) Evergreen.V29.Group.EventId (Result () ())
    | ChangeEventCancellationStatusResponse (Evergreen.V29.Id.Id Evergreen.V29.Id.GroupId) Evergreen.V29.Group.EventId (Result Evergreen.V29.Group.EditCancellationStatusError Evergreen.V29.Event.CancellationStatus) Time.Posix
