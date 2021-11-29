module Evergreen.V49.Types exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc
import Browser
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Evergreen.V49.AdminStatus
import Evergreen.V49.CreateGroupPage
import Evergreen.V49.Description
import Evergreen.V49.EmailAddress
import Evergreen.V49.Event
import Evergreen.V49.FrontendUser
import Evergreen.V49.Group
import Evergreen.V49.GroupName
import Evergreen.V49.GroupPage
import Evergreen.V49.Id
import Evergreen.V49.Name
import Evergreen.V49.Postmark
import Evergreen.V49.ProfileImage
import Evergreen.V49.ProfilePage
import Evergreen.V49.Route
import Evergreen.V49.TimeZone
import Evergreen.V49.Untrusted
import List.Nonempty
import Pixels
import Quantity
import Time
import Url


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V49.Route.Route
    , routeToken : Evergreen.V49.Route.Token
    , windowSize : Maybe ( Quantity.Quantity Int Pixels.Pixels, Quantity.Quantity Int Pixels.Pixels )
    , time : Maybe Time.Posix
    , timezone : Maybe Time.Zone
    }


type ToBackend
    = GetGroupRequest (Evergreen.V49.Id.Id Evergreen.V49.Id.GroupId)
    | GetUserRequest (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId)
    | CheckLoginRequest
    | LoginWithTokenRequest (Evergreen.V49.Id.Id Evergreen.V49.Id.LoginToken) (Maybe ( Evergreen.V49.Id.Id Evergreen.V49.Id.GroupId, Evergreen.V49.Group.EventId ))
    | GetLoginTokenRequest Evergreen.V49.Route.Route (Evergreen.V49.Untrusted.Untrusted Evergreen.V49.EmailAddress.EmailAddress) (Maybe ( Evergreen.V49.Id.Id Evergreen.V49.Id.GroupId, Evergreen.V49.Group.EventId ))
    | GetAdminDataRequest
    | LogoutRequest
    | CreateGroupRequest (Evergreen.V49.Untrusted.Untrusted Evergreen.V49.GroupName.GroupName) (Evergreen.V49.Untrusted.Untrusted Evergreen.V49.Description.Description) Evergreen.V49.Group.GroupVisibility
    | DeleteUserRequest (Evergreen.V49.Id.Id Evergreen.V49.Id.DeleteUserToken)
    | GetMyGroupsRequest
    | SearchGroupsRequest String
    | GroupRequest (Evergreen.V49.Id.Id Evergreen.V49.Id.GroupId) Evergreen.V49.GroupPage.ToBackend
    | ProfileFormRequest Evergreen.V49.ProfilePage.ToBackend


type Log
    = LogUntrustedCheckFailed Time.Posix ToBackend Evergreen.V49.Id.SessionIdFirst4Chars
    | LogLoginEmail Time.Posix (Result Effect.Http.Error Evergreen.V49.Postmark.PostmarkSendResponse) Evergreen.V49.EmailAddress.EmailAddress
    | LogDeleteAccountEmail Time.Posix (Result Effect.Http.Error Evergreen.V49.Postmark.PostmarkSendResponse) (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId)
    | LogEventReminderEmail Time.Posix (Result Effect.Http.Error Evergreen.V49.Postmark.PostmarkSendResponse) (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) (Evergreen.V49.Id.Id Evergreen.V49.Id.GroupId) Evergreen.V49.Group.EventId
    | LogLoginTokenEmailRequestRateLimited Time.Posix Evergreen.V49.EmailAddress.EmailAddress Evergreen.V49.Id.SessionIdFirst4Chars
    | LogDeleteAccountEmailRequestRateLimited Time.Posix (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) Evergreen.V49.Id.SessionIdFirst4Chars


type alias AdminModel =
    { cachedEmailAddress : AssocList.Dict (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) Evergreen.V49.EmailAddress.EmailAddress
    , logs : Array.Array Log
    , lastLogCheck : Time.Posix
    }


type AdminCache
    = AdminCacheNotRequested
    | AdminCached AdminModel
    | AdminCachePending


type alias LoggedIn_ =
    { userId : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
    , emailAddress : Evergreen.V49.EmailAddress.EmailAddress
    , profileForm : Evergreen.V49.ProfilePage.Model
    , myGroups : Maybe (AssocSet.Set (Evergreen.V49.Id.Id Evergreen.V49.Id.GroupId))
    , adminState : AdminCache
    , adminStatus : Evergreen.V49.AdminStatus.AdminStatus
    }


type LoginStatus
    = LoginStatusPending
    | LoggedIn LoggedIn_
    | NotLoggedIn
        { showLogin : Bool
        , joiningEvent : Maybe ( Evergreen.V49.Id.Id Evergreen.V49.Id.GroupId, Evergreen.V49.Group.EventId )
        }


type Cache item
    = ItemDoesNotExist
    | ItemCached item
    | ItemRequestPending


type alias LoginForm =
    { email : String
    , pressedSubmitEmail : Bool
    , emailSent : Maybe Evergreen.V49.EmailAddress.EmailAddress
    }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , loginStatus : LoginStatus
    , route : Evergreen.V49.Route.Route
    , cachedGroups : AssocList.Dict (Evergreen.V49.Id.Id Evergreen.V49.Id.GroupId) (Cache Evergreen.V49.Group.Group)
    , cachedUsers : AssocList.Dict (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) (Cache Evergreen.V49.FrontendUser.FrontendUser)
    , time : Time.Posix
    , timezone : Time.Zone
    , lastConnectionCheck : Time.Posix
    , loginForm : LoginForm
    , logs : Maybe (Array.Array Log)
    , hasLoginTokenError : Bool
    , groupForm : Evergreen.V49.CreateGroupPage.Model
    , groupCreated : Bool
    , accountDeletedResult : Maybe (Result () ())
    , searchText : String
    , searchList : List (Evergreen.V49.Id.Id Evergreen.V49.Id.GroupId)
    , windowWidth : Quantity.Quantity Int Pixels.Pixels
    , windowHeight : Quantity.Quantity Int Pixels.Pixels
    , groupPage : AssocList.Dict (Evergreen.V49.Id.Id Evergreen.V49.Id.GroupId) Evergreen.V49.GroupPage.Model
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias BackendUser =
    { name : Evergreen.V49.Name.Name
    , description : Evergreen.V49.Description.Description
    , emailAddress : Evergreen.V49.EmailAddress.EmailAddress
    , profileImage : Evergreen.V49.ProfileImage.ProfileImage
    , timezone : Time.Zone
    , allowEventReminders : Bool
    }


type alias LoginTokenData =
    { creationTime : Time.Posix
    , emailAddress : Evergreen.V49.EmailAddress.EmailAddress
    }


type alias DeleteUserTokenData =
    { creationTime : Time.Posix
    , userId : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
    }


type alias BackendModel =
    { users : AssocList.Dict (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) BackendUser
    , groups : AssocList.Dict (Evergreen.V49.Id.Id Evergreen.V49.Id.GroupId) Evergreen.V49.Group.Group
    , deletedGroups : AssocList.Dict (Evergreen.V49.Id.Id Evergreen.V49.Id.GroupId) Evergreen.V49.Group.Group
    , sessions : BiDict.Assoc.BiDict Effect.Lamdera.SessionId (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId)
    , loginAttempts : AssocList.Dict Effect.Lamdera.SessionId (List.Nonempty.Nonempty Time.Posix)
    , connections : AssocList.Dict Effect.Lamdera.SessionId (List.Nonempty.Nonempty Effect.Lamdera.ClientId)
    , logs : Array.Array Log
    , time : Time.Posix
    , secretCounter : Int
    , pendingLoginTokens : AssocList.Dict (Evergreen.V49.Id.Id Evergreen.V49.Id.LoginToken) LoginTokenData
    , pendingDeleteUserTokens : AssocList.Dict (Evergreen.V49.Id.Id Evergreen.V49.Id.DeleteUserToken) DeleteUserTokenData
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
    | CreateGroupPageMsg Evergreen.V49.CreateGroupPage.Msg
    | ProfileFormMsg Evergreen.V49.ProfilePage.Msg
    | TypedSearchText String
    | SubmittedSearchBox
    | GroupPageMsg Evergreen.V49.GroupPage.Msg
    | GotWindowSize Int Int
    | GotTimeZone (Result Evergreen.V49.TimeZone.Error ( String, Time.Zone ))
    | ScrolledToTop
    | PressedEnableAdmin
    | PressedDisableAdmin


type BackendMsg
    = SentLoginEmail Evergreen.V49.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V49.Postmark.PostmarkSendResponse)
    | SentDeleteUserEmail (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) (Result Effect.Http.Error Evergreen.V49.Postmark.PostmarkSendResponse)
    | SentEventReminderEmail (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) (Evergreen.V49.Id.Id Evergreen.V49.Id.GroupId) Evergreen.V49.Group.EventId (Result Effect.Http.Error Evergreen.V49.Postmark.PostmarkSendResponse)
    | BackendGotTime Time.Posix
    | Connected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | Disconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId


type GroupRequest
    = GroupNotFound_
    | GroupFound_ Evergreen.V49.Group.Group (AssocList.Dict (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) Evergreen.V49.FrontendUser.FrontendUser)


type ToFrontend
    = GetGroupResponse (Evergreen.V49.Id.Id Evergreen.V49.Id.GroupId) GroupRequest
    | GetUserResponse (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) (Result () Evergreen.V49.FrontendUser.FrontendUser)
    | CheckLoginResponse
        (Maybe
            { userId : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | LoginWithTokenResponse
        (Result
            ()
            { userId : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | GetAdminDataResponse AdminModel
    | CreateGroupResponse (Result Evergreen.V49.CreateGroupPage.CreateGroupError ( Evergreen.V49.Id.Id Evergreen.V49.Id.GroupId, Evergreen.V49.Group.Group ))
    | LogoutResponse
    | ChangeNameResponse Evergreen.V49.Name.Name
    | ChangeDescriptionResponse Evergreen.V49.Description.Description
    | ChangeEmailAddressResponse Evergreen.V49.EmailAddress.EmailAddress
    | DeleteUserResponse (Result () ())
    | ChangeProfileImageResponse Evergreen.V49.ProfileImage.ProfileImage
    | GetMyGroupsResponse (List ( Evergreen.V49.Id.Id Evergreen.V49.Id.GroupId, Evergreen.V49.Group.Group ))
    | SearchGroupsResponse String (List ( Evergreen.V49.Id.Id Evergreen.V49.Id.GroupId, Evergreen.V49.Group.Group ))
    | ChangeGroupNameResponse (Evergreen.V49.Id.Id Evergreen.V49.Id.GroupId) Evergreen.V49.GroupName.GroupName
    | ChangeGroupDescriptionResponse (Evergreen.V49.Id.Id Evergreen.V49.Id.GroupId) Evergreen.V49.Description.Description
    | ChangeGroupVisibilityResponse (Evergreen.V49.Id.Id Evergreen.V49.Id.GroupId) Evergreen.V49.Group.GroupVisibility
    | CreateEventResponse (Evergreen.V49.Id.Id Evergreen.V49.Id.GroupId) (Result Evergreen.V49.GroupPage.CreateEventError Evergreen.V49.Event.Event)
    | EditEventResponse (Evergreen.V49.Id.Id Evergreen.V49.Id.GroupId) Evergreen.V49.Group.EventId (Result Evergreen.V49.Group.EditEventError Evergreen.V49.Event.Event) Time.Posix
    | JoinEventResponse (Evergreen.V49.Id.Id Evergreen.V49.Id.GroupId) Evergreen.V49.Group.EventId (Result Evergreen.V49.Group.JoinEventError ())
    | LeaveEventResponse (Evergreen.V49.Id.Id Evergreen.V49.Id.GroupId) Evergreen.V49.Group.EventId (Result () ())
    | ChangeEventCancellationStatusResponse (Evergreen.V49.Id.Id Evergreen.V49.Id.GroupId) Evergreen.V49.Group.EventId (Result Evergreen.V49.Group.EditCancellationStatusError Evergreen.V49.Event.CancellationStatus) Time.Posix
    | DeleteGroupAdminResponse (Evergreen.V49.Id.Id Evergreen.V49.Id.GroupId)
