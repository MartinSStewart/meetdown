module Evergreen.V56.Types exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc
import Browser
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Evergreen.V56.AdminStatus
import Evergreen.V56.Cache
import Evergreen.V56.CreateGroupPage
import Evergreen.V56.Description
import Evergreen.V56.EmailAddress
import Evergreen.V56.Event
import Evergreen.V56.FrontendUser
import Evergreen.V56.Group
import Evergreen.V56.GroupName
import Evergreen.V56.GroupPage
import Evergreen.V56.Id
import Evergreen.V56.Name
import Evergreen.V56.Postmark
import Evergreen.V56.ProfileImage
import Evergreen.V56.ProfilePage
import Evergreen.V56.Route
import Evergreen.V56.TimeZone
import Evergreen.V56.Untrusted
import List.Nonempty
import Pixels
import Quantity
import Time
import Url


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V56.Route.Route
    , routeToken : Evergreen.V56.Route.Token
    , windowSize : Maybe ( Quantity.Quantity Int Pixels.Pixels, Quantity.Quantity Int Pixels.Pixels )
    , time : Maybe Time.Posix
    , timezone : Maybe Time.Zone
    }


type ToBackend
    = GetGroupRequest (Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId)
    | GetUserRequest (List.Nonempty.Nonempty (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId))
    | CheckLoginRequest
    | LoginWithTokenRequest (Evergreen.V56.Id.Id Evergreen.V56.Id.LoginToken) (Maybe ( Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId, Evergreen.V56.Group.EventId ))
    | GetLoginTokenRequest Evergreen.V56.Route.Route (Evergreen.V56.Untrusted.Untrusted Evergreen.V56.EmailAddress.EmailAddress) (Maybe ( Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId, Evergreen.V56.Group.EventId ))
    | GetAdminDataRequest
    | LogoutRequest
    | CreateGroupRequest (Evergreen.V56.Untrusted.Untrusted Evergreen.V56.GroupName.GroupName) (Evergreen.V56.Untrusted.Untrusted Evergreen.V56.Description.Description) Evergreen.V56.Group.GroupVisibility
    | DeleteUserRequest (Evergreen.V56.Id.Id Evergreen.V56.Id.DeleteUserToken)
    | GetMyGroupsRequest
    | SearchGroupsRequest String
    | GroupRequest (Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId) Evergreen.V56.GroupPage.ToBackend
    | ProfileFormRequest Evergreen.V56.ProfilePage.ToBackend


type Log
    = LogUntrustedCheckFailed Time.Posix ToBackend Evergreen.V56.Id.SessionIdFirst4Chars
    | LogLoginEmail Time.Posix (Result Effect.Http.Error Evergreen.V56.Postmark.PostmarkSendResponse) Evergreen.V56.EmailAddress.EmailAddress
    | LogDeleteAccountEmail Time.Posix (Result Effect.Http.Error Evergreen.V56.Postmark.PostmarkSendResponse) (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId)
    | LogEventReminderEmail Time.Posix (Result Effect.Http.Error Evergreen.V56.Postmark.PostmarkSendResponse) (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) (Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId) Evergreen.V56.Group.EventId
    | LogNewEventNotificationEmail Time.Posix (Result Effect.Http.Error Evergreen.V56.Postmark.PostmarkSendResponse) (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) (Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId)
    | LogLoginTokenEmailRequestRateLimited Time.Posix Evergreen.V56.EmailAddress.EmailAddress Evergreen.V56.Id.SessionIdFirst4Chars
    | LogDeleteAccountEmailRequestRateLimited Time.Posix (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) Evergreen.V56.Id.SessionIdFirst4Chars


type alias AdminModel =
    { cachedEmailAddress : AssocList.Dict (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) Evergreen.V56.EmailAddress.EmailAddress
    , logs : Array.Array Log
    , lastLogCheck : Time.Posix
    }


type AdminCache
    = AdminCacheNotRequested
    | AdminCached AdminModel
    | AdminCachePending


type alias LoggedIn_ =
    { userId : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
    , emailAddress : Evergreen.V56.EmailAddress.EmailAddress
    , profileForm : Evergreen.V56.ProfilePage.Model
    , myGroups : Maybe (AssocSet.Set (Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId))
    , subscribedGroups : AssocSet.Set (Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId)
    , adminState : AdminCache
    , adminStatus : Evergreen.V56.AdminStatus.AdminStatus
    }


type LoginStatus
    = LoginStatusPending
    | LoggedIn LoggedIn_
    | NotLoggedIn
        { showLogin : Bool
        , joiningEvent : Maybe ( Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId, Evergreen.V56.Group.EventId )
        }


type alias LoginForm =
    { email : String
    , pressedSubmitEmail : Bool
    , emailSent : Maybe Evergreen.V56.EmailAddress.EmailAddress
    }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , loginStatus : LoginStatus
    , route : Evergreen.V56.Route.Route
    , cachedGroups : AssocList.Dict (Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId) (Evergreen.V56.Cache.Cache Evergreen.V56.Group.Group)
    , cachedUsers : AssocList.Dict (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) (Evergreen.V56.Cache.Cache Evergreen.V56.FrontendUser.FrontendUser)
    , time : Time.Posix
    , timezone : Time.Zone
    , lastConnectionCheck : Time.Posix
    , loginForm : LoginForm
    , logs : Maybe (Array.Array Log)
    , hasLoginTokenError : Bool
    , groupForm : Evergreen.V56.CreateGroupPage.Model
    , groupCreated : Bool
    , accountDeletedResult : Maybe (Result () ())
    , searchText : String
    , searchList : List (Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId)
    , windowWidth : Quantity.Quantity Int Pixels.Pixels
    , windowHeight : Quantity.Quantity Int Pixels.Pixels
    , groupPage : AssocList.Dict (Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId) Evergreen.V56.GroupPage.Model
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias BackendUser =
    { name : Evergreen.V56.Name.Name
    , description : Evergreen.V56.Description.Description
    , emailAddress : Evergreen.V56.EmailAddress.EmailAddress
    , profileImage : Evergreen.V56.ProfileImage.ProfileImage
    , timezone : Time.Zone
    , allowEventReminders : Bool
    , subscribedGroups : AssocSet.Set (Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId)
    }


type alias LoginTokenData =
    { creationTime : Time.Posix
    , emailAddress : Evergreen.V56.EmailAddress.EmailAddress
    }


type alias DeleteUserTokenData =
    { creationTime : Time.Posix
    , userId : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
    }


type alias BackendModel =
    { users : AssocList.Dict (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) BackendUser
    , groups : AssocList.Dict (Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId) Evergreen.V56.Group.Group
    , deletedGroups : AssocList.Dict (Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId) Evergreen.V56.Group.Group
    , sessions : BiDict.Assoc.BiDict Effect.Lamdera.SessionId (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId)
    , loginAttempts : AssocList.Dict Effect.Lamdera.SessionId (List.Nonempty.Nonempty Time.Posix)
    , connections : AssocList.Dict Effect.Lamdera.SessionId (List.Nonempty.Nonempty Effect.Lamdera.ClientId)
    , logs : Array.Array Log
    , time : Time.Posix
    , secretCounter : Int
    , pendingLoginTokens : AssocList.Dict (Evergreen.V56.Id.Id Evergreen.V56.Id.LoginToken) LoginTokenData
    , pendingDeleteUserTokens : AssocList.Dict (Evergreen.V56.Id.Id Evergreen.V56.Id.DeleteUserToken) DeleteUserTokenData
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
    | CreateGroupPageMsg Evergreen.V56.CreateGroupPage.Msg
    | ProfileFormMsg Evergreen.V56.ProfilePage.Msg
    | TypedSearchText String
    | SubmittedSearchBox
    | GroupPageMsg Evergreen.V56.GroupPage.Msg
    | GotWindowSize Int Int
    | GotTimeZone (Result Evergreen.V56.TimeZone.Error ( String, Time.Zone ))
    | ScrolledToTop
    | PressedEnableAdmin
    | PressedDisableAdmin


type BackendMsg
    = SentLoginEmail Evergreen.V56.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V56.Postmark.PostmarkSendResponse)
    | SentDeleteUserEmail (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) (Result Effect.Http.Error Evergreen.V56.Postmark.PostmarkSendResponse)
    | SentEventReminderEmail (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) (Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId) Evergreen.V56.Group.EventId (Result Effect.Http.Error Evergreen.V56.Postmark.PostmarkSendResponse)
    | SentNewEventNotificationEmail (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) (Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId) (Result Effect.Http.Error Evergreen.V56.Postmark.PostmarkSendResponse)
    | BackendGotTime Time.Posix
    | Connected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | Disconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId


type GroupRequest
    = GroupNotFound_
    | GroupFound_ Evergreen.V56.Group.Group (AssocList.Dict (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) Evergreen.V56.FrontendUser.FrontendUser)


type ToFrontend
    = GetGroupResponse (Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId) GroupRequest
    | GetUserResponse (AssocList.Dict (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) (Result () Evergreen.V56.FrontendUser.FrontendUser))
    | CheckLoginResponse
        (Maybe
            { userId : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | LoginWithTokenResponse
        (Result
            ()
            { userId : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | GetAdminDataResponse AdminModel
    | CreateGroupResponse (Result Evergreen.V56.CreateGroupPage.CreateGroupError ( Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId, Evergreen.V56.Group.Group ))
    | LogoutResponse
    | ChangeNameResponse Evergreen.V56.Name.Name
    | ChangeDescriptionResponse Evergreen.V56.Description.Description
    | ChangeEmailAddressResponse Evergreen.V56.EmailAddress.EmailAddress
    | DeleteUserResponse (Result () ())
    | ChangeProfileImageResponse Evergreen.V56.ProfileImage.ProfileImage
    | GetMyGroupsResponse
        { myGroups : List ( Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId, Evergreen.V56.Group.Group )
        , subscribedGroups : List ( Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId, Evergreen.V56.Group.Group )
        }
    | SearchGroupsResponse String (List ( Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId, Evergreen.V56.Group.Group ))
    | ChangeGroupNameResponse (Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId) Evergreen.V56.GroupName.GroupName
    | ChangeGroupDescriptionResponse (Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId) Evergreen.V56.Description.Description
    | ChangeGroupVisibilityResponse (Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId) Evergreen.V56.Group.GroupVisibility
    | CreateEventResponse (Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId) (Result Evergreen.V56.GroupPage.CreateEventError Evergreen.V56.Event.Event)
    | EditEventResponse (Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId) Evergreen.V56.Group.EventId (Result Evergreen.V56.Group.EditEventError Evergreen.V56.Event.Event) Time.Posix
    | JoinEventResponse (Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId) Evergreen.V56.Group.EventId (Result Evergreen.V56.Group.JoinEventError ())
    | LeaveEventResponse (Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId) Evergreen.V56.Group.EventId (Result () ())
    | ChangeEventCancellationStatusResponse (Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId) Evergreen.V56.Group.EventId (Result Evergreen.V56.Group.EditCancellationStatusError Evergreen.V56.Event.CancellationStatus) Time.Posix
    | DeleteGroupAdminResponse (Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId)
    | SubscribeResponse (Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId)
    | UnsubscribeResponse (Evergreen.V56.Id.Id Evergreen.V56.Id.GroupId)
