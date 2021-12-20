module Evergreen.V50.Types exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc
import Browser
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Evergreen.V50.AdminStatus
import Evergreen.V50.CreateGroupPage
import Evergreen.V50.Description
import Evergreen.V50.EmailAddress
import Evergreen.V50.Event
import Evergreen.V50.FrontendUser
import Evergreen.V50.Group
import Evergreen.V50.GroupName
import Evergreen.V50.GroupPage
import Evergreen.V50.Id
import Evergreen.V50.Name
import Evergreen.V50.Postmark
import Evergreen.V50.ProfileImage
import Evergreen.V50.ProfilePage
import Evergreen.V50.Route
import Evergreen.V50.TimeZone
import Evergreen.V50.Untrusted
import List.Nonempty
import Pixels
import Quantity
import Time
import Url


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V50.Route.Route
    , routeToken : Evergreen.V50.Route.Token
    , windowSize : Maybe ( Quantity.Quantity Int Pixels.Pixels, Quantity.Quantity Int Pixels.Pixels )
    , time : Maybe Time.Posix
    , timezone : Maybe Time.Zone
    }


type ToBackend
    = GetGroupRequest (Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId)
    | GetUserRequest (Evergreen.V50.Id.Id Evergreen.V50.Id.UserId)
    | CheckLoginRequest
    | LoginWithTokenRequest (Evergreen.V50.Id.Id Evergreen.V50.Id.LoginToken) (Maybe ( Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId, Evergreen.V50.Group.EventId ))
    | GetLoginTokenRequest Evergreen.V50.Route.Route (Evergreen.V50.Untrusted.Untrusted Evergreen.V50.EmailAddress.EmailAddress) (Maybe ( Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId, Evergreen.V50.Group.EventId ))
    | GetAdminDataRequest
    | LogoutRequest
    | CreateGroupRequest (Evergreen.V50.Untrusted.Untrusted Evergreen.V50.GroupName.GroupName) (Evergreen.V50.Untrusted.Untrusted Evergreen.V50.Description.Description) Evergreen.V50.Group.GroupVisibility
    | DeleteUserRequest (Evergreen.V50.Id.Id Evergreen.V50.Id.DeleteUserToken)
    | GetMyGroupsRequest
    | SearchGroupsRequest String
    | GroupRequest (Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId) Evergreen.V50.GroupPage.ToBackend
    | ProfileFormRequest Evergreen.V50.ProfilePage.ToBackend


type Log
    = LogUntrustedCheckFailed Time.Posix ToBackend Evergreen.V50.Id.SessionIdFirst4Chars
    | LogLoginEmail Time.Posix (Result Effect.Http.Error Evergreen.V50.Postmark.PostmarkSendResponse) Evergreen.V50.EmailAddress.EmailAddress
    | LogDeleteAccountEmail Time.Posix (Result Effect.Http.Error Evergreen.V50.Postmark.PostmarkSendResponse) (Evergreen.V50.Id.Id Evergreen.V50.Id.UserId)
    | LogEventReminderEmail Time.Posix (Result Effect.Http.Error Evergreen.V50.Postmark.PostmarkSendResponse) (Evergreen.V50.Id.Id Evergreen.V50.Id.UserId) (Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId) Evergreen.V50.Group.EventId
    | LogNewEventNotificationEmail Time.Posix (Result Effect.Http.Error Evergreen.V50.Postmark.PostmarkSendResponse) (Evergreen.V50.Id.Id Evergreen.V50.Id.UserId) (Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId)
    | LogLoginTokenEmailRequestRateLimited Time.Posix Evergreen.V50.EmailAddress.EmailAddress Evergreen.V50.Id.SessionIdFirst4Chars
    | LogDeleteAccountEmailRequestRateLimited Time.Posix (Evergreen.V50.Id.Id Evergreen.V50.Id.UserId) Evergreen.V50.Id.SessionIdFirst4Chars


type alias AdminModel =
    { cachedEmailAddress : AssocList.Dict (Evergreen.V50.Id.Id Evergreen.V50.Id.UserId) Evergreen.V50.EmailAddress.EmailAddress
    , logs : Array.Array Log
    , lastLogCheck : Time.Posix
    }


type AdminCache
    = AdminCacheNotRequested
    | AdminCached AdminModel
    | AdminCachePending


type alias LoggedIn_ =
    { userId : Evergreen.V50.Id.Id Evergreen.V50.Id.UserId
    , emailAddress : Evergreen.V50.EmailAddress.EmailAddress
    , profileForm : Evergreen.V50.ProfilePage.Model
    , myGroups : Maybe (AssocSet.Set (Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId))
    , subscribedGroups : AssocSet.Set (Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId)
    , adminState : AdminCache
    , adminStatus : Evergreen.V50.AdminStatus.AdminStatus
    }


type LoginStatus
    = LoginStatusPending
    | LoggedIn LoggedIn_
    | NotLoggedIn
        { showLogin : Bool
        , joiningEvent : Maybe ( Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId, Evergreen.V50.Group.EventId )
        }


type Cache item
    = ItemDoesNotExist
    | ItemCached item
    | ItemRequestPending


type alias LoginForm =
    { email : String
    , pressedSubmitEmail : Bool
    , emailSent : Maybe Evergreen.V50.EmailAddress.EmailAddress
    }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , loginStatus : LoginStatus
    , route : Evergreen.V50.Route.Route
    , cachedGroups : AssocList.Dict (Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId) (Cache Evergreen.V50.Group.Group)
    , cachedUsers : AssocList.Dict (Evergreen.V50.Id.Id Evergreen.V50.Id.UserId) (Cache Evergreen.V50.FrontendUser.FrontendUser)
    , time : Time.Posix
    , timezone : Time.Zone
    , lastConnectionCheck : Time.Posix
    , loginForm : LoginForm
    , logs : Maybe (Array.Array Log)
    , hasLoginTokenError : Bool
    , groupForm : Evergreen.V50.CreateGroupPage.Model
    , groupCreated : Bool
    , accountDeletedResult : Maybe (Result () ())
    , searchText : String
    , searchList : List (Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId)
    , windowWidth : Quantity.Quantity Int Pixels.Pixels
    , windowHeight : Quantity.Quantity Int Pixels.Pixels
    , groupPage : AssocList.Dict (Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId) Evergreen.V50.GroupPage.Model
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias BackendUser =
    { name : Evergreen.V50.Name.Name
    , description : Evergreen.V50.Description.Description
    , emailAddress : Evergreen.V50.EmailAddress.EmailAddress
    , profileImage : Evergreen.V50.ProfileImage.ProfileImage
    , timezone : Time.Zone
    , allowEventReminders : Bool
    , subscribedGroups : AssocSet.Set (Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId)
    }


type alias LoginTokenData =
    { creationTime : Time.Posix
    , emailAddress : Evergreen.V50.EmailAddress.EmailAddress
    }


type alias DeleteUserTokenData =
    { creationTime : Time.Posix
    , userId : Evergreen.V50.Id.Id Evergreen.V50.Id.UserId
    }


type alias BackendModel =
    { users : AssocList.Dict (Evergreen.V50.Id.Id Evergreen.V50.Id.UserId) BackendUser
    , groups : AssocList.Dict (Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId) Evergreen.V50.Group.Group
    , deletedGroups : AssocList.Dict (Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId) Evergreen.V50.Group.Group
    , sessions : BiDict.Assoc.BiDict Effect.Lamdera.SessionId (Evergreen.V50.Id.Id Evergreen.V50.Id.UserId)
    , loginAttempts : AssocList.Dict Effect.Lamdera.SessionId (List.Nonempty.Nonempty Time.Posix)
    , connections : AssocList.Dict Effect.Lamdera.SessionId (List.Nonempty.Nonempty Effect.Lamdera.ClientId)
    , logs : Array.Array Log
    , time : Time.Posix
    , secretCounter : Int
    , pendingLoginTokens : AssocList.Dict (Evergreen.V50.Id.Id Evergreen.V50.Id.LoginToken) LoginTokenData
    , pendingDeleteUserTokens : AssocList.Dict (Evergreen.V50.Id.Id Evergreen.V50.Id.DeleteUserToken) DeleteUserTokenData
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
    | CreateGroupPageMsg Evergreen.V50.CreateGroupPage.Msg
    | ProfileFormMsg Evergreen.V50.ProfilePage.Msg
    | TypedSearchText String
    | SubmittedSearchBox
    | GroupPageMsg Evergreen.V50.GroupPage.Msg
    | GotWindowSize Int Int
    | GotTimeZone (Result Evergreen.V50.TimeZone.Error ( String, Time.Zone ))
    | ScrolledToTop
    | PressedEnableAdmin
    | PressedDisableAdmin


type BackendMsg
    = SentLoginEmail Evergreen.V50.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V50.Postmark.PostmarkSendResponse)
    | SentDeleteUserEmail (Evergreen.V50.Id.Id Evergreen.V50.Id.UserId) (Result Effect.Http.Error Evergreen.V50.Postmark.PostmarkSendResponse)
    | SentEventReminderEmail (Evergreen.V50.Id.Id Evergreen.V50.Id.UserId) (Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId) Evergreen.V50.Group.EventId (Result Effect.Http.Error Evergreen.V50.Postmark.PostmarkSendResponse)
    | SentNewEventNotificationEmail (Evergreen.V50.Id.Id Evergreen.V50.Id.UserId) (Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId) (Result Effect.Http.Error Evergreen.V50.Postmark.PostmarkSendResponse)
    | BackendGotTime Time.Posix
    | Connected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | Disconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId


type GroupRequest
    = GroupNotFound_
    | GroupFound_ Evergreen.V50.Group.Group (AssocList.Dict (Evergreen.V50.Id.Id Evergreen.V50.Id.UserId) Evergreen.V50.FrontendUser.FrontendUser)


type ToFrontend
    = GetGroupResponse (Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId) GroupRequest
    | GetUserResponse (Evergreen.V50.Id.Id Evergreen.V50.Id.UserId) (Result () Evergreen.V50.FrontendUser.FrontendUser)
    | CheckLoginResponse
        (Maybe
            { userId : Evergreen.V50.Id.Id Evergreen.V50.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | LoginWithTokenResponse
        (Result
            ()
            { userId : Evergreen.V50.Id.Id Evergreen.V50.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | GetAdminDataResponse AdminModel
    | CreateGroupResponse (Result Evergreen.V50.CreateGroupPage.CreateGroupError ( Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId, Evergreen.V50.Group.Group ))
    | LogoutResponse
    | ChangeNameResponse Evergreen.V50.Name.Name
    | ChangeDescriptionResponse Evergreen.V50.Description.Description
    | ChangeEmailAddressResponse Evergreen.V50.EmailAddress.EmailAddress
    | DeleteUserResponse (Result () ())
    | ChangeProfileImageResponse Evergreen.V50.ProfileImage.ProfileImage
    | GetMyGroupsResponse
        { myGroups : List ( Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId, Evergreen.V50.Group.Group )
        , subscribedGroups : List ( Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId, Evergreen.V50.Group.Group )
        }
    | SearchGroupsResponse String (List ( Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId, Evergreen.V50.Group.Group ))
    | ChangeGroupNameResponse (Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId) Evergreen.V50.GroupName.GroupName
    | ChangeGroupDescriptionResponse (Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId) Evergreen.V50.Description.Description
    | ChangeGroupVisibilityResponse (Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId) Evergreen.V50.Group.GroupVisibility
    | CreateEventResponse (Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId) (Result Evergreen.V50.GroupPage.CreateEventError Evergreen.V50.Event.Event)
    | EditEventResponse (Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId) Evergreen.V50.Group.EventId (Result Evergreen.V50.Group.EditEventError Evergreen.V50.Event.Event) Time.Posix
    | JoinEventResponse (Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId) Evergreen.V50.Group.EventId (Result Evergreen.V50.Group.JoinEventError ())
    | LeaveEventResponse (Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId) Evergreen.V50.Group.EventId (Result () ())
    | ChangeEventCancellationStatusResponse (Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId) Evergreen.V50.Group.EventId (Result Evergreen.V50.Group.EditCancellationStatusError Evergreen.V50.Event.CancellationStatus) Time.Posix
    | DeleteGroupAdminResponse (Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId)
    | SubscribeResponse (Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId)
    | UnsubscribeResponse (Evergreen.V50.Id.Id Evergreen.V50.Id.GroupId)
