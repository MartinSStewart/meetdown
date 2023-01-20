module Evergreen.V62.Types exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc
import Browser
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Evergreen.V62.AdminStatus
import Evergreen.V62.Cache
import Evergreen.V62.CreateGroupPage
import Evergreen.V62.Description
import Evergreen.V62.EmailAddress
import Evergreen.V62.Event
import Evergreen.V62.FrontendUser
import Evergreen.V62.Group
import Evergreen.V62.GroupName
import Evergreen.V62.GroupPage
import Evergreen.V62.Id
import Evergreen.V62.Name
import Evergreen.V62.Postmark
import Evergreen.V62.ProfileImage
import Evergreen.V62.ProfilePage
import Evergreen.V62.Route
import Evergreen.V62.TimeZone
import Evergreen.V62.Untrusted
import List.Nonempty
import Pixels
import Quantity
import Time
import Url


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V62.Route.Route
    , routeToken : Evergreen.V62.Route.Token
    , windowSize : Maybe ( Quantity.Quantity Int Pixels.Pixels, Quantity.Quantity Int Pixels.Pixels )
    , time : Maybe Time.Posix
    , timezone : Maybe Time.Zone
    }


type ToBackend
    = GetGroupRequest (Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId)
    | GetUserRequest (List.Nonempty.Nonempty (Evergreen.V62.Id.Id Evergreen.V62.Id.UserId))
    | CheckLoginRequest
    | LoginWithTokenRequest (Evergreen.V62.Id.Id Evergreen.V62.Id.LoginToken) (Maybe ( Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId, Evergreen.V62.Group.EventId ))
    | GetLoginTokenRequest Evergreen.V62.Route.Route (Evergreen.V62.Untrusted.Untrusted Evergreen.V62.EmailAddress.EmailAddress) (Maybe ( Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId, Evergreen.V62.Group.EventId ))
    | GetAdminDataRequest
    | LogoutRequest
    | CreateGroupRequest (Evergreen.V62.Untrusted.Untrusted Evergreen.V62.GroupName.GroupName) (Evergreen.V62.Untrusted.Untrusted Evergreen.V62.Description.Description) Evergreen.V62.Group.GroupVisibility
    | DeleteUserRequest (Evergreen.V62.Id.Id Evergreen.V62.Id.DeleteUserToken)
    | GetMyGroupsRequest
    | SearchGroupsRequest String
    | GroupRequest (Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId) Evergreen.V62.GroupPage.ToBackend
    | ProfileFormRequest Evergreen.V62.ProfilePage.ToBackend


type Log
    = LogUntrustedCheckFailed Time.Posix ToBackend Evergreen.V62.Id.SessionIdFirst4Chars
    | LogLoginEmail Time.Posix (Result Effect.Http.Error Evergreen.V62.Postmark.PostmarkSendResponse) Evergreen.V62.EmailAddress.EmailAddress
    | LogDeleteAccountEmail Time.Posix (Result Effect.Http.Error Evergreen.V62.Postmark.PostmarkSendResponse) (Evergreen.V62.Id.Id Evergreen.V62.Id.UserId)
    | LogEventReminderEmail Time.Posix (Result Effect.Http.Error Evergreen.V62.Postmark.PostmarkSendResponse) (Evergreen.V62.Id.Id Evergreen.V62.Id.UserId) (Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId) Evergreen.V62.Group.EventId
    | LogNewEventNotificationEmail Time.Posix (Result Effect.Http.Error Evergreen.V62.Postmark.PostmarkSendResponse) (Evergreen.V62.Id.Id Evergreen.V62.Id.UserId) (Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId)
    | LogLoginTokenEmailRequestRateLimited Time.Posix Evergreen.V62.EmailAddress.EmailAddress Evergreen.V62.Id.SessionIdFirst4Chars
    | LogDeleteAccountEmailRequestRateLimited Time.Posix (Evergreen.V62.Id.Id Evergreen.V62.Id.UserId) Evergreen.V62.Id.SessionIdFirst4Chars


type alias AdminModel =
    { cachedEmailAddress : AssocList.Dict (Evergreen.V62.Id.Id Evergreen.V62.Id.UserId) Evergreen.V62.EmailAddress.EmailAddress
    , logs : Array.Array Log
    , lastLogCheck : Time.Posix
    }


type AdminCache
    = AdminCacheNotRequested
    | AdminCached AdminModel
    | AdminCachePending


type alias LoggedIn_ =
    { userId : Evergreen.V62.Id.Id Evergreen.V62.Id.UserId
    , emailAddress : Evergreen.V62.EmailAddress.EmailAddress
    , profileForm : Evergreen.V62.ProfilePage.Model
    , myGroups : Maybe (AssocSet.Set (Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId))
    , subscribedGroups : AssocSet.Set (Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId)
    , adminState : AdminCache
    , adminStatus : Evergreen.V62.AdminStatus.AdminStatus
    }


type LoginStatus
    = LoginStatusPending
    | LoggedIn LoggedIn_
    | NotLoggedIn
        { showLogin : Bool
        , joiningEvent : Maybe ( Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId, Evergreen.V62.Group.EventId )
        }


type alias LoginForm =
    { email : String
    , pressedSubmitEmail : Bool
    , emailSent : Maybe Evergreen.V62.EmailAddress.EmailAddress
    }


type ColorTheme
    = LightTheme
    | DarkTheme


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , loginStatus : LoginStatus
    , route : Evergreen.V62.Route.Route
    , cachedGroups : AssocList.Dict (Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId) (Evergreen.V62.Cache.Cache Evergreen.V62.Group.Group)
    , cachedUsers : AssocList.Dict (Evergreen.V62.Id.Id Evergreen.V62.Id.UserId) (Evergreen.V62.Cache.Cache Evergreen.V62.FrontendUser.FrontendUser)
    , time : Time.Posix
    , timezone : Time.Zone
    , lastConnectionCheck : Time.Posix
    , loginForm : LoginForm
    , logs : Maybe (Array.Array Log)
    , hasLoginTokenError : Bool
    , groupForm : Evergreen.V62.CreateGroupPage.Model
    , groupCreated : Bool
    , accountDeletedResult : Maybe (Result () ())
    , searchText : String
    , searchList : List (Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId)
    , windowWidth : Quantity.Quantity Int Pixels.Pixels
    , windowHeight : Quantity.Quantity Int Pixels.Pixels
    , groupPage : AssocList.Dict (Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId) Evergreen.V62.GroupPage.Model
    , theme : ColorTheme
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias BackendUser =
    { name : Evergreen.V62.Name.Name
    , description : Evergreen.V62.Description.Description
    , emailAddress : Evergreen.V62.EmailAddress.EmailAddress
    , profileImage : Evergreen.V62.ProfileImage.ProfileImage
    , timezone : Time.Zone
    , allowEventReminders : Bool
    , subscribedGroups : AssocSet.Set (Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId)
    }


type alias LoginTokenData =
    { creationTime : Time.Posix
    , emailAddress : Evergreen.V62.EmailAddress.EmailAddress
    }


type alias DeleteUserTokenData =
    { creationTime : Time.Posix
    , userId : Evergreen.V62.Id.Id Evergreen.V62.Id.UserId
    }


type alias BackendModel =
    { users : AssocList.Dict (Evergreen.V62.Id.Id Evergreen.V62.Id.UserId) BackendUser
    , groups : AssocList.Dict (Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId) Evergreen.V62.Group.Group
    , deletedGroups : AssocList.Dict (Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId) Evergreen.V62.Group.Group
    , sessions : BiDict.Assoc.BiDict Effect.Lamdera.SessionId (Evergreen.V62.Id.Id Evergreen.V62.Id.UserId)
    , loginAttempts : AssocList.Dict Effect.Lamdera.SessionId (List.Nonempty.Nonempty Time.Posix)
    , connections : AssocList.Dict Effect.Lamdera.SessionId (List.Nonempty.Nonempty Effect.Lamdera.ClientId)
    , logs : Array.Array Log
    , time : Time.Posix
    , secretCounter : Int
    , pendingLoginTokens : AssocList.Dict (Evergreen.V62.Id.Id Evergreen.V62.Id.LoginToken) LoginTokenData
    , pendingDeleteUserTokens : AssocList.Dict (Evergreen.V62.Id.Id Evergreen.V62.Id.DeleteUserToken) DeleteUserTokenData
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
    | CreateGroupPageMsg Evergreen.V62.CreateGroupPage.Msg
    | ProfileFormMsg Evergreen.V62.ProfilePage.Msg
    | TypedSearchText String
    | SubmittedSearchBox
    | GroupPageMsg Evergreen.V62.GroupPage.Msg
    | GotWindowSize Int Int
    | GotTimeZone (Result Evergreen.V62.TimeZone.Error ( String, Time.Zone ))
    | ScrolledToTop
    | PressedEnableAdmin
    | PressedDisableAdmin
    | PressedThemeToggle
    | GotPrefersDarkTheme Bool


type BackendMsg
    = SentLoginEmail Evergreen.V62.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V62.Postmark.PostmarkSendResponse)
    | SentDeleteUserEmail (Evergreen.V62.Id.Id Evergreen.V62.Id.UserId) (Result Effect.Http.Error Evergreen.V62.Postmark.PostmarkSendResponse)
    | SentEventReminderEmail (Evergreen.V62.Id.Id Evergreen.V62.Id.UserId) (Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId) Evergreen.V62.Group.EventId (Result Effect.Http.Error Evergreen.V62.Postmark.PostmarkSendResponse)
    | SentNewEventNotificationEmail (Evergreen.V62.Id.Id Evergreen.V62.Id.UserId) (Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId) (Result Effect.Http.Error Evergreen.V62.Postmark.PostmarkSendResponse)
    | BackendGotTime Time.Posix
    | Connected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | Disconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId


type GroupRequest
    = GroupNotFound_
    | GroupFound_ Evergreen.V62.Group.Group (AssocList.Dict (Evergreen.V62.Id.Id Evergreen.V62.Id.UserId) Evergreen.V62.FrontendUser.FrontendUser)


type ToFrontend
    = GetGroupResponse (Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId) GroupRequest
    | GetUserResponse (AssocList.Dict (Evergreen.V62.Id.Id Evergreen.V62.Id.UserId) (Result () Evergreen.V62.FrontendUser.FrontendUser))
    | CheckLoginResponse
        (Maybe
            { userId : Evergreen.V62.Id.Id Evergreen.V62.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | LoginWithTokenResponse
        (Result
            ()
            { userId : Evergreen.V62.Id.Id Evergreen.V62.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | GetAdminDataResponse AdminModel
    | CreateGroupResponse (Result Evergreen.V62.CreateGroupPage.CreateGroupError ( Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId, Evergreen.V62.Group.Group ))
    | LogoutResponse
    | ChangeNameResponse Evergreen.V62.Name.Name
    | ChangeDescriptionResponse Evergreen.V62.Description.Description
    | ChangeEmailAddressResponse Evergreen.V62.EmailAddress.EmailAddress
    | DeleteUserResponse (Result () ())
    | ChangeProfileImageResponse Evergreen.V62.ProfileImage.ProfileImage
    | GetMyGroupsResponse
        { myGroups : List ( Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId, Evergreen.V62.Group.Group )
        , subscribedGroups : List ( Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId, Evergreen.V62.Group.Group )
        }
    | SearchGroupsResponse String (List ( Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId, Evergreen.V62.Group.Group ))
    | ChangeGroupNameResponse (Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId) Evergreen.V62.GroupName.GroupName
    | ChangeGroupDescriptionResponse (Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId) Evergreen.V62.Description.Description
    | ChangeGroupVisibilityResponse (Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId) Evergreen.V62.Group.GroupVisibility
    | CreateEventResponse (Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId) (Result Evergreen.V62.GroupPage.CreateEventError Evergreen.V62.Event.Event)
    | EditEventResponse (Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId) Evergreen.V62.Group.EventId (Result Evergreen.V62.Group.EditEventError Evergreen.V62.Event.Event) Time.Posix
    | JoinEventResponse (Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId) Evergreen.V62.Group.EventId (Result Evergreen.V62.Group.JoinEventError ())
    | LeaveEventResponse (Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId) Evergreen.V62.Group.EventId (Result () ())
    | ChangeEventCancellationStatusResponse (Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId) Evergreen.V62.Group.EventId (Result Evergreen.V62.Group.EditCancellationStatusError Evergreen.V62.Event.CancellationStatus) Time.Posix
    | DeleteGroupAdminResponse (Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId)
    | SubscribeResponse (Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId)
    | UnsubscribeResponse (Evergreen.V62.Id.Id Evergreen.V62.Id.GroupId)
