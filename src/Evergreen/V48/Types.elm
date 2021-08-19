module Evergreen.V48.Types exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc
import Browser
import Evergreen.V48.AdminStatus
import Evergreen.V48.CreateGroupPage
import Evergreen.V48.Description
import Evergreen.V48.Effect.Browser.Navigation
import Evergreen.V48.Effect.Http
import Evergreen.V48.Effect.Lamdera
import Evergreen.V48.EmailAddress
import Evergreen.V48.Event
import Evergreen.V48.FrontendUser
import Evergreen.V48.Group
import Evergreen.V48.GroupName
import Evergreen.V48.GroupPage
import Evergreen.V48.Id
import Evergreen.V48.Name
import Evergreen.V48.Postmark
import Evergreen.V48.ProfileImage
import Evergreen.V48.ProfilePage
import Evergreen.V48.Route
import Evergreen.V48.TimeZone
import Evergreen.V48.Untrusted
import List.Nonempty
import Pixels
import Quantity
import Time
import Url


type alias LoadingFrontend =
    { navigationKey : Evergreen.V48.Effect.Browser.Navigation.Key
    , route : Evergreen.V48.Route.Route
    , routeToken : Evergreen.V48.Route.Token
    , windowSize : Maybe ( Quantity.Quantity Int Pixels.Pixels, Quantity.Quantity Int Pixels.Pixels )
    , time : Maybe Time.Posix
    , timezone : Maybe Time.Zone
    }


type ToBackend
    = GetGroupRequest (Evergreen.V48.Id.Id Evergreen.V48.Id.GroupId)
    | GetUserRequest (Evergreen.V48.Id.Id Evergreen.V48.Id.UserId)
    | CheckLoginRequest
    | LoginWithTokenRequest (Evergreen.V48.Id.Id Evergreen.V48.Id.LoginToken) (Maybe ( Evergreen.V48.Id.Id Evergreen.V48.Id.GroupId, Evergreen.V48.Group.EventId ))
    | GetLoginTokenRequest Evergreen.V48.Route.Route (Evergreen.V48.Untrusted.Untrusted Evergreen.V48.EmailAddress.EmailAddress) (Maybe ( Evergreen.V48.Id.Id Evergreen.V48.Id.GroupId, Evergreen.V48.Group.EventId ))
    | GetAdminDataRequest
    | LogoutRequest
    | CreateGroupRequest (Evergreen.V48.Untrusted.Untrusted Evergreen.V48.GroupName.GroupName) (Evergreen.V48.Untrusted.Untrusted Evergreen.V48.Description.Description) Evergreen.V48.Group.GroupVisibility
    | DeleteUserRequest (Evergreen.V48.Id.Id Evergreen.V48.Id.DeleteUserToken)
    | GetMyGroupsRequest
    | SearchGroupsRequest String
    | GroupRequest (Evergreen.V48.Id.Id Evergreen.V48.Id.GroupId) Evergreen.V48.GroupPage.ToBackend
    | ProfileFormRequest Evergreen.V48.ProfilePage.ToBackend


type Log
    = LogUntrustedCheckFailed Time.Posix ToBackend Evergreen.V48.Id.SessionIdFirst4Chars
    | LogLoginEmail Time.Posix (Result Evergreen.V48.Effect.Http.Error Evergreen.V48.Postmark.PostmarkSendResponse) Evergreen.V48.EmailAddress.EmailAddress
    | LogDeleteAccountEmail Time.Posix (Result Evergreen.V48.Effect.Http.Error Evergreen.V48.Postmark.PostmarkSendResponse) (Evergreen.V48.Id.Id Evergreen.V48.Id.UserId)
    | LogEventReminderEmail Time.Posix (Result Evergreen.V48.Effect.Http.Error Evergreen.V48.Postmark.PostmarkSendResponse) (Evergreen.V48.Id.Id Evergreen.V48.Id.UserId) (Evergreen.V48.Id.Id Evergreen.V48.Id.GroupId) Evergreen.V48.Group.EventId
    | LogLoginTokenEmailRequestRateLimited Time.Posix Evergreen.V48.EmailAddress.EmailAddress Evergreen.V48.Id.SessionIdFirst4Chars
    | LogDeleteAccountEmailRequestRateLimited Time.Posix (Evergreen.V48.Id.Id Evergreen.V48.Id.UserId) Evergreen.V48.Id.SessionIdFirst4Chars


type alias AdminModel =
    { cachedEmailAddress : AssocList.Dict (Evergreen.V48.Id.Id Evergreen.V48.Id.UserId) Evergreen.V48.EmailAddress.EmailAddress
    , logs : Array.Array Log
    , lastLogCheck : Time.Posix
    }


type AdminCache
    = AdminCacheNotRequested
    | AdminCached AdminModel
    | AdminCachePending


type alias LoggedIn_ =
    { userId : Evergreen.V48.Id.Id Evergreen.V48.Id.UserId
    , emailAddress : Evergreen.V48.EmailAddress.EmailAddress
    , profileForm : Evergreen.V48.ProfilePage.Model
    , myGroups : Maybe (AssocSet.Set (Evergreen.V48.Id.Id Evergreen.V48.Id.GroupId))
    , adminState : AdminCache
    , adminStatus : Evergreen.V48.AdminStatus.AdminStatus
    }


type LoginStatus
    = LoginStatusPending
    | LoggedIn LoggedIn_
    | NotLoggedIn
        { showLogin : Bool
        , joiningEvent : Maybe ( Evergreen.V48.Id.Id Evergreen.V48.Id.GroupId, Evergreen.V48.Group.EventId )
        }


type Cache item
    = ItemDoesNotExist
    | ItemCached item
    | ItemRequestPending


type alias LoginForm =
    { email : String
    , pressedSubmitEmail : Bool
    , emailSent : Maybe Evergreen.V48.EmailAddress.EmailAddress
    }


type alias LoadedFrontend =
    { navigationKey : Evergreen.V48.Effect.Browser.Navigation.Key
    , loginStatus : LoginStatus
    , route : Evergreen.V48.Route.Route
    , cachedGroups : AssocList.Dict (Evergreen.V48.Id.Id Evergreen.V48.Id.GroupId) (Cache Evergreen.V48.Group.Group)
    , cachedUsers : AssocList.Dict (Evergreen.V48.Id.Id Evergreen.V48.Id.UserId) (Cache Evergreen.V48.FrontendUser.FrontendUser)
    , time : Time.Posix
    , timezone : Time.Zone
    , lastConnectionCheck : Time.Posix
    , loginForm : LoginForm
    , logs : Maybe (Array.Array Log)
    , hasLoginTokenError : Bool
    , groupForm : Evergreen.V48.CreateGroupPage.Model
    , groupCreated : Bool
    , accountDeletedResult : Maybe (Result () ())
    , searchText : String
    , searchList : List (Evergreen.V48.Id.Id Evergreen.V48.Id.GroupId)
    , windowWidth : Quantity.Quantity Int Pixels.Pixels
    , windowHeight : Quantity.Quantity Int Pixels.Pixels
    , groupPage : AssocList.Dict (Evergreen.V48.Id.Id Evergreen.V48.Id.GroupId) Evergreen.V48.GroupPage.Model
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias BackendUser =
    { name : Evergreen.V48.Name.Name
    , description : Evergreen.V48.Description.Description
    , emailAddress : Evergreen.V48.EmailAddress.EmailAddress
    , profileImage : Evergreen.V48.ProfileImage.ProfileImage
    , timezone : Time.Zone
    , allowEventReminders : Bool
    }


type alias LoginTokenData =
    { creationTime : Time.Posix
    , emailAddress : Evergreen.V48.EmailAddress.EmailAddress
    }


type alias DeleteUserTokenData =
    { creationTime : Time.Posix
    , userId : Evergreen.V48.Id.Id Evergreen.V48.Id.UserId
    }


type alias BackendModel =
    { users : AssocList.Dict (Evergreen.V48.Id.Id Evergreen.V48.Id.UserId) BackendUser
    , groups : AssocList.Dict (Evergreen.V48.Id.Id Evergreen.V48.Id.GroupId) Evergreen.V48.Group.Group
    , deletedGroups : AssocList.Dict (Evergreen.V48.Id.Id Evergreen.V48.Id.GroupId) Evergreen.V48.Group.Group
    , sessions : BiDict.Assoc.BiDict Evergreen.V48.Effect.Lamdera.SessionId (Evergreen.V48.Id.Id Evergreen.V48.Id.UserId)
    , loginAttempts : AssocList.Dict Evergreen.V48.Effect.Lamdera.SessionId (List.Nonempty.Nonempty Time.Posix)
    , connections : AssocList.Dict Evergreen.V48.Effect.Lamdera.SessionId (List.Nonempty.Nonempty Evergreen.V48.Effect.Lamdera.ClientId)
    , logs : Array.Array Log
    , time : Time.Posix
    , secretCounter : Int
    , pendingLoginTokens : AssocList.Dict (Evergreen.V48.Id.Id Evergreen.V48.Id.LoginToken) LoginTokenData
    , pendingDeleteUserTokens : AssocList.Dict (Evergreen.V48.Id.Id Evergreen.V48.Id.DeleteUserToken) DeleteUserTokenData
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
    | CreateGroupPageMsg Evergreen.V48.CreateGroupPage.Msg
    | ProfileFormMsg Evergreen.V48.ProfilePage.Msg
    | TypedSearchText String
    | SubmittedSearchBox
    | GroupPageMsg Evergreen.V48.GroupPage.Msg
    | GotWindowSize Int Int
    | GotTimeZone (Result Evergreen.V48.TimeZone.Error ( String, Time.Zone ))
    | ScrolledToTop
    | PressedEnableAdmin
    | PressedDisableAdmin


type BackendMsg
    = SentLoginEmail Evergreen.V48.EmailAddress.EmailAddress (Result Evergreen.V48.Effect.Http.Error Evergreen.V48.Postmark.PostmarkSendResponse)
    | SentDeleteUserEmail (Evergreen.V48.Id.Id Evergreen.V48.Id.UserId) (Result Evergreen.V48.Effect.Http.Error Evergreen.V48.Postmark.PostmarkSendResponse)
    | SentEventReminderEmail (Evergreen.V48.Id.Id Evergreen.V48.Id.UserId) (Evergreen.V48.Id.Id Evergreen.V48.Id.GroupId) Evergreen.V48.Group.EventId (Result Evergreen.V48.Effect.Http.Error Evergreen.V48.Postmark.PostmarkSendResponse)
    | BackendGotTime Time.Posix
    | Connected Evergreen.V48.Effect.Lamdera.SessionId Evergreen.V48.Effect.Lamdera.ClientId
    | Disconnected Evergreen.V48.Effect.Lamdera.SessionId Evergreen.V48.Effect.Lamdera.ClientId


type GroupRequest
    = GroupNotFound_
    | GroupFound_ Evergreen.V48.Group.Group (AssocList.Dict (Evergreen.V48.Id.Id Evergreen.V48.Id.UserId) Evergreen.V48.FrontendUser.FrontendUser)


type ToFrontend
    = GetGroupResponse (Evergreen.V48.Id.Id Evergreen.V48.Id.GroupId) GroupRequest
    | GetUserResponse (Evergreen.V48.Id.Id Evergreen.V48.Id.UserId) (Result () Evergreen.V48.FrontendUser.FrontendUser)
    | CheckLoginResponse
        (Maybe
            { userId : Evergreen.V48.Id.Id Evergreen.V48.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | LoginWithTokenResponse
        (Result
            ()
            { userId : Evergreen.V48.Id.Id Evergreen.V48.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | GetAdminDataResponse AdminModel
    | CreateGroupResponse (Result Evergreen.V48.CreateGroupPage.CreateGroupError ( Evergreen.V48.Id.Id Evergreen.V48.Id.GroupId, Evergreen.V48.Group.Group ))
    | LogoutResponse
    | ChangeNameResponse Evergreen.V48.Name.Name
    | ChangeDescriptionResponse Evergreen.V48.Description.Description
    | ChangeEmailAddressResponse Evergreen.V48.EmailAddress.EmailAddress
    | DeleteUserResponse (Result () ())
    | ChangeProfileImageResponse Evergreen.V48.ProfileImage.ProfileImage
    | GetMyGroupsResponse (List ( Evergreen.V48.Id.Id Evergreen.V48.Id.GroupId, Evergreen.V48.Group.Group ))
    | SearchGroupsResponse String (List ( Evergreen.V48.Id.Id Evergreen.V48.Id.GroupId, Evergreen.V48.Group.Group ))
    | ChangeGroupNameResponse (Evergreen.V48.Id.Id Evergreen.V48.Id.GroupId) Evergreen.V48.GroupName.GroupName
    | ChangeGroupDescriptionResponse (Evergreen.V48.Id.Id Evergreen.V48.Id.GroupId) Evergreen.V48.Description.Description
    | ChangeGroupVisibilityResponse (Evergreen.V48.Id.Id Evergreen.V48.Id.GroupId) Evergreen.V48.Group.GroupVisibility
    | CreateEventResponse (Evergreen.V48.Id.Id Evergreen.V48.Id.GroupId) (Result Evergreen.V48.GroupPage.CreateEventError Evergreen.V48.Event.Event)
    | EditEventResponse (Evergreen.V48.Id.Id Evergreen.V48.Id.GroupId) Evergreen.V48.Group.EventId (Result Evergreen.V48.Group.EditEventError Evergreen.V48.Event.Event) Time.Posix
    | JoinEventResponse (Evergreen.V48.Id.Id Evergreen.V48.Id.GroupId) Evergreen.V48.Group.EventId (Result Evergreen.V48.Group.JoinEventError ())
    | LeaveEventResponse (Evergreen.V48.Id.Id Evergreen.V48.Id.GroupId) Evergreen.V48.Group.EventId (Result () ())
    | ChangeEventCancellationStatusResponse (Evergreen.V48.Id.Id Evergreen.V48.Id.GroupId) Evergreen.V48.Group.EventId (Result Evergreen.V48.Group.EditCancellationStatusError Evergreen.V48.Event.CancellationStatus) Time.Posix
    | DeleteGroupAdminResponse (Evergreen.V48.Id.Id Evergreen.V48.Id.GroupId)
