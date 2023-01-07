module Evergreen.V61.Types exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc
import Browser
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Evergreen.V61.AdminStatus
import Evergreen.V61.Cache
import Evergreen.V61.CreateGroupPage
import Evergreen.V61.Description
import Evergreen.V61.EmailAddress
import Evergreen.V61.Event
import Evergreen.V61.FrontendUser
import Evergreen.V61.Group
import Evergreen.V61.GroupName
import Evergreen.V61.GroupPage
import Evergreen.V61.Id
import Evergreen.V61.Name
import Evergreen.V61.Postmark
import Evergreen.V61.ProfileImage
import Evergreen.V61.ProfilePage
import Evergreen.V61.Route
import Evergreen.V61.TimeZone
import Evergreen.V61.Untrusted
import List.Nonempty
import Pixels
import Quantity
import Time
import Url


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V61.Route.Route
    , routeToken : Evergreen.V61.Route.Token
    , windowSize : Maybe ( Quantity.Quantity Int Pixels.Pixels, Quantity.Quantity Int Pixels.Pixels )
    , time : Maybe Time.Posix
    , timezone : Maybe Time.Zone
    }


type ToBackend
    = GetGroupRequest (Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId)
    | GetUserRequest (List.Nonempty.Nonempty (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId))
    | CheckLoginRequest
    | LoginWithTokenRequest (Evergreen.V61.Id.Id Evergreen.V61.Id.LoginToken) (Maybe ( Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId, Evergreen.V61.Group.EventId ))
    | GetLoginTokenRequest Evergreen.V61.Route.Route (Evergreen.V61.Untrusted.Untrusted Evergreen.V61.EmailAddress.EmailAddress) (Maybe ( Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId, Evergreen.V61.Group.EventId ))
    | GetAdminDataRequest
    | LogoutRequest
    | CreateGroupRequest (Evergreen.V61.Untrusted.Untrusted Evergreen.V61.GroupName.GroupName) (Evergreen.V61.Untrusted.Untrusted Evergreen.V61.Description.Description) Evergreen.V61.Group.GroupVisibility
    | DeleteUserRequest (Evergreen.V61.Id.Id Evergreen.V61.Id.DeleteUserToken)
    | GetMyGroupsRequest
    | SearchGroupsRequest String
    | GroupRequest (Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId) Evergreen.V61.GroupPage.ToBackend
    | ProfileFormRequest Evergreen.V61.ProfilePage.ToBackend


type Log
    = LogUntrustedCheckFailed Time.Posix ToBackend Evergreen.V61.Id.SessionIdFirst4Chars
    | LogLoginEmail Time.Posix (Result Effect.Http.Error Evergreen.V61.Postmark.PostmarkSendResponse) Evergreen.V61.EmailAddress.EmailAddress
    | LogDeleteAccountEmail Time.Posix (Result Effect.Http.Error Evergreen.V61.Postmark.PostmarkSendResponse) (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId)
    | LogEventReminderEmail Time.Posix (Result Effect.Http.Error Evergreen.V61.Postmark.PostmarkSendResponse) (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) (Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId) Evergreen.V61.Group.EventId
    | LogNewEventNotificationEmail Time.Posix (Result Effect.Http.Error Evergreen.V61.Postmark.PostmarkSendResponse) (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) (Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId)
    | LogLoginTokenEmailRequestRateLimited Time.Posix Evergreen.V61.EmailAddress.EmailAddress Evergreen.V61.Id.SessionIdFirst4Chars
    | LogDeleteAccountEmailRequestRateLimited Time.Posix (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) Evergreen.V61.Id.SessionIdFirst4Chars


type alias AdminModel =
    { cachedEmailAddress : AssocList.Dict (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) Evergreen.V61.EmailAddress.EmailAddress
    , logs : Array.Array Log
    , lastLogCheck : Time.Posix
    }


type AdminCache
    = AdminCacheNotRequested
    | AdminCached AdminModel
    | AdminCachePending


type alias LoggedIn_ =
    { userId : Evergreen.V61.Id.Id Evergreen.V61.Id.UserId
    , emailAddress : Evergreen.V61.EmailAddress.EmailAddress
    , profileForm : Evergreen.V61.ProfilePage.Model
    , myGroups : Maybe (AssocSet.Set (Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId))
    , subscribedGroups : AssocSet.Set (Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId)
    , adminState : AdminCache
    , adminStatus : Evergreen.V61.AdminStatus.AdminStatus
    }


type LoginStatus
    = LoginStatusPending
    | LoggedIn LoggedIn_
    | NotLoggedIn
        { showLogin : Bool
        , joiningEvent : Maybe ( Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId, Evergreen.V61.Group.EventId )
        }


type alias LoginForm =
    { email : String
    , pressedSubmitEmail : Bool
    , emailSent : Maybe Evergreen.V61.EmailAddress.EmailAddress
    }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , loginStatus : LoginStatus
    , route : Evergreen.V61.Route.Route
    , cachedGroups : AssocList.Dict (Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId) (Evergreen.V61.Cache.Cache Evergreen.V61.Group.Group)
    , cachedUsers : AssocList.Dict (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) (Evergreen.V61.Cache.Cache Evergreen.V61.FrontendUser.FrontendUser)
    , time : Time.Posix
    , timezone : Time.Zone
    , lastConnectionCheck : Time.Posix
    , loginForm : LoginForm
    , logs : Maybe (Array.Array Log)
    , hasLoginTokenError : Bool
    , groupForm : Evergreen.V61.CreateGroupPage.Model
    , groupCreated : Bool
    , accountDeletedResult : Maybe (Result () ())
    , searchText : String
    , searchList : List (Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId)
    , windowWidth : Quantity.Quantity Int Pixels.Pixels
    , windowHeight : Quantity.Quantity Int Pixels.Pixels
    , groupPage : AssocList.Dict (Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId) Evergreen.V61.GroupPage.Model
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias BackendUser =
    { name : Evergreen.V61.Name.Name
    , description : Evergreen.V61.Description.Description
    , emailAddress : Evergreen.V61.EmailAddress.EmailAddress
    , profileImage : Evergreen.V61.ProfileImage.ProfileImage
    , timezone : Time.Zone
    , allowEventReminders : Bool
    , subscribedGroups : AssocSet.Set (Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId)
    }


type alias LoginTokenData =
    { creationTime : Time.Posix
    , emailAddress : Evergreen.V61.EmailAddress.EmailAddress
    }


type alias DeleteUserTokenData =
    { creationTime : Time.Posix
    , userId : Evergreen.V61.Id.Id Evergreen.V61.Id.UserId
    }


type alias BackendModel =
    { users : AssocList.Dict (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) BackendUser
    , groups : AssocList.Dict (Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId) Evergreen.V61.Group.Group
    , deletedGroups : AssocList.Dict (Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId) Evergreen.V61.Group.Group
    , sessions : BiDict.Assoc.BiDict Effect.Lamdera.SessionId (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId)
    , loginAttempts : AssocList.Dict Effect.Lamdera.SessionId (List.Nonempty.Nonempty Time.Posix)
    , connections : AssocList.Dict Effect.Lamdera.SessionId (List.Nonempty.Nonempty Effect.Lamdera.ClientId)
    , logs : Array.Array Log
    , time : Time.Posix
    , secretCounter : Int
    , pendingLoginTokens : AssocList.Dict (Evergreen.V61.Id.Id Evergreen.V61.Id.LoginToken) LoginTokenData
    , pendingDeleteUserTokens : AssocList.Dict (Evergreen.V61.Id.Id Evergreen.V61.Id.DeleteUserToken) DeleteUserTokenData
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
    | CreateGroupPageMsg Evergreen.V61.CreateGroupPage.Msg
    | ProfileFormMsg Evergreen.V61.ProfilePage.Msg
    | TypedSearchText String
    | SubmittedSearchBox
    | GroupPageMsg Evergreen.V61.GroupPage.Msg
    | GotWindowSize Int Int
    | GotTimeZone (Result Evergreen.V61.TimeZone.Error ( String, Time.Zone ))
    | ScrolledToTop
    | PressedEnableAdmin
    | PressedDisableAdmin


type BackendMsg
    = SentLoginEmail Evergreen.V61.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V61.Postmark.PostmarkSendResponse)
    | SentDeleteUserEmail (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) (Result Effect.Http.Error Evergreen.V61.Postmark.PostmarkSendResponse)
    | SentEventReminderEmail (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) (Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId) Evergreen.V61.Group.EventId (Result Effect.Http.Error Evergreen.V61.Postmark.PostmarkSendResponse)
    | SentNewEventNotificationEmail (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) (Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId) (Result Effect.Http.Error Evergreen.V61.Postmark.PostmarkSendResponse)
    | BackendGotTime Time.Posix
    | Connected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | Disconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId


type GroupRequest
    = GroupNotFound_
    | GroupFound_ Evergreen.V61.Group.Group (AssocList.Dict (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) Evergreen.V61.FrontendUser.FrontendUser)


type ToFrontend
    = GetGroupResponse (Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId) GroupRequest
    | GetUserResponse (AssocList.Dict (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) (Result () Evergreen.V61.FrontendUser.FrontendUser))
    | CheckLoginResponse
        (Maybe
            { userId : Evergreen.V61.Id.Id Evergreen.V61.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | LoginWithTokenResponse
        (Result
            ()
            { userId : Evergreen.V61.Id.Id Evergreen.V61.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | GetAdminDataResponse AdminModel
    | CreateGroupResponse (Result Evergreen.V61.CreateGroupPage.CreateGroupError ( Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId, Evergreen.V61.Group.Group ))
    | LogoutResponse
    | ChangeNameResponse Evergreen.V61.Name.Name
    | ChangeDescriptionResponse Evergreen.V61.Description.Description
    | ChangeEmailAddressResponse Evergreen.V61.EmailAddress.EmailAddress
    | DeleteUserResponse (Result () ())
    | ChangeProfileImageResponse Evergreen.V61.ProfileImage.ProfileImage
    | GetMyGroupsResponse
        { myGroups : List ( Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId, Evergreen.V61.Group.Group )
        , subscribedGroups : List ( Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId, Evergreen.V61.Group.Group )
        }
    | SearchGroupsResponse String (List ( Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId, Evergreen.V61.Group.Group ))
    | ChangeGroupNameResponse (Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId) Evergreen.V61.GroupName.GroupName
    | ChangeGroupDescriptionResponse (Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId) Evergreen.V61.Description.Description
    | ChangeGroupVisibilityResponse (Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId) Evergreen.V61.Group.GroupVisibility
    | CreateEventResponse (Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId) (Result Evergreen.V61.GroupPage.CreateEventError Evergreen.V61.Event.Event)
    | EditEventResponse (Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId) Evergreen.V61.Group.EventId (Result Evergreen.V61.Group.EditEventError Evergreen.V61.Event.Event) Time.Posix
    | JoinEventResponse (Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId) Evergreen.V61.Group.EventId (Result Evergreen.V61.Group.JoinEventError ())
    | LeaveEventResponse (Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId) Evergreen.V61.Group.EventId (Result () ())
    | ChangeEventCancellationStatusResponse (Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId) Evergreen.V61.Group.EventId (Result Evergreen.V61.Group.EditCancellationStatusError Evergreen.V61.Event.CancellationStatus) Time.Posix
    | DeleteGroupAdminResponse (Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId)
    | SubscribeResponse (Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId)
    | UnsubscribeResponse (Evergreen.V61.Id.Id Evergreen.V61.Id.GroupId)
