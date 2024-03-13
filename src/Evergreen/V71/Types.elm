module Evergreen.V71.Types exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc
import Browser
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Evergreen.V71.AdminStatus
import Evergreen.V71.Cache
import Evergreen.V71.CreateGroupPage
import Evergreen.V71.Description
import Evergreen.V71.EmailAddress
import Evergreen.V71.Event
import Evergreen.V71.FrontendUser
import Evergreen.V71.Group
import Evergreen.V71.GroupName
import Evergreen.V71.GroupPage
import Evergreen.V71.Id
import Evergreen.V71.Name
import Evergreen.V71.Postmark
import Evergreen.V71.ProfileImage
import Evergreen.V71.ProfilePage
import Evergreen.V71.Route
import Evergreen.V71.TimeZone
import Evergreen.V71.Untrusted
import List.Nonempty
import Pixels
import Quantity
import Time
import Url


type ColorTheme
    = LightTheme
    | DarkTheme


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V71.Route.Route
    , routeToken : Evergreen.V71.Route.Token
    , windowSize : Maybe ( Quantity.Quantity Int Pixels.Pixels, Quantity.Quantity Int Pixels.Pixels )
    , time : Maybe Time.Posix
    , timezone : Maybe Time.Zone
    , theme : ColorTheme
    }


type ToBackend
    = GetGroupRequest (Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId)
    | GetUserRequest (List.Nonempty.Nonempty (Evergreen.V71.Id.Id Evergreen.V71.Id.UserId))
    | CheckLoginRequest
    | LoginWithTokenRequest (Evergreen.V71.Id.Id Evergreen.V71.Id.LoginToken) (Maybe ( Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId, Evergreen.V71.Group.EventId ))
    | GetLoginTokenRequest Evergreen.V71.Route.Route (Evergreen.V71.Untrusted.Untrusted Evergreen.V71.EmailAddress.EmailAddress) (Maybe ( Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId, Evergreen.V71.Group.EventId ))
    | GetAdminDataRequest
    | LogoutRequest
    | CreateGroupRequest (Evergreen.V71.Untrusted.Untrusted Evergreen.V71.GroupName.GroupName) (Evergreen.V71.Untrusted.Untrusted Evergreen.V71.Description.Description) Evergreen.V71.Group.GroupVisibility
    | DeleteUserRequest (Evergreen.V71.Id.Id Evergreen.V71.Id.DeleteUserToken)
    | GetMyGroupsRequest
    | SearchGroupsRequest String
    | GroupRequest (Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId) Evergreen.V71.GroupPage.ToBackend
    | ProfileFormRequest Evergreen.V71.ProfilePage.ToBackend


type Log
    = LogUntrustedCheckFailed Time.Posix ToBackend Evergreen.V71.Id.SessionIdFirst4Chars
    | LogLoginEmail Time.Posix (Result Effect.Http.Error Evergreen.V71.Postmark.PostmarkSendResponse) Evergreen.V71.EmailAddress.EmailAddress
    | LogDeleteAccountEmail Time.Posix (Result Effect.Http.Error Evergreen.V71.Postmark.PostmarkSendResponse) (Evergreen.V71.Id.Id Evergreen.V71.Id.UserId)
    | LogEventReminderEmail Time.Posix (Result Effect.Http.Error Evergreen.V71.Postmark.PostmarkSendResponse) (Evergreen.V71.Id.Id Evergreen.V71.Id.UserId) (Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId) Evergreen.V71.Group.EventId
    | LogNewEventNotificationEmail Time.Posix (Result Effect.Http.Error Evergreen.V71.Postmark.PostmarkSendResponse) (Evergreen.V71.Id.Id Evergreen.V71.Id.UserId) (Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId)
    | LogLoginTokenEmailRequestRateLimited Time.Posix Evergreen.V71.EmailAddress.EmailAddress Evergreen.V71.Id.SessionIdFirst4Chars
    | LogDeleteAccountEmailRequestRateLimited Time.Posix (Evergreen.V71.Id.Id Evergreen.V71.Id.UserId) Evergreen.V71.Id.SessionIdFirst4Chars


type alias AdminModel =
    { cachedEmailAddress : AssocList.Dict (Evergreen.V71.Id.Id Evergreen.V71.Id.UserId) Evergreen.V71.EmailAddress.EmailAddress
    , logs : Array.Array Log
    , lastLogCheck : Time.Posix
    }


type AdminCache
    = AdminCacheNotRequested
    | AdminCached AdminModel
    | AdminCachePending


type alias LoggedIn_ =
    { userId : Evergreen.V71.Id.Id Evergreen.V71.Id.UserId
    , emailAddress : Evergreen.V71.EmailAddress.EmailAddress
    , profileForm : Evergreen.V71.ProfilePage.Model
    , myGroups : Maybe (AssocSet.Set (Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId))
    , subscribedGroups : AssocSet.Set (Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId)
    , adminState : AdminCache
    , adminStatus : Evergreen.V71.AdminStatus.AdminStatus
    }


type LoginStatus
    = LoginStatusPending
    | LoggedIn LoggedIn_
    | NotLoggedIn
        { showLogin : Bool
        , joiningEvent : Maybe ( Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId, Evergreen.V71.Group.EventId )
        }


type alias LoginForm =
    { email : String
    , pressedSubmitEmail : Bool
    , emailSent : Maybe Evergreen.V71.EmailAddress.EmailAddress
    }


type Language
    = English
    | French
    | Spanish
    | Thai


type alias LoadedUserConfig =
    { theme : ColorTheme
    , language : Language
    }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , loginStatus : LoginStatus
    , route : Evergreen.V71.Route.Route
    , cachedGroups : AssocList.Dict (Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId) (Evergreen.V71.Cache.Cache Evergreen.V71.Group.Group)
    , cachedUsers : AssocList.Dict (Evergreen.V71.Id.Id Evergreen.V71.Id.UserId) (Evergreen.V71.Cache.Cache Evergreen.V71.FrontendUser.FrontendUser)
    , time : Time.Posix
    , timezone : Time.Zone
    , lastConnectionCheck : Time.Posix
    , loginForm : LoginForm
    , logs : Maybe (Array.Array Log)
    , hasLoginTokenError : Bool
    , groupForm : Evergreen.V71.CreateGroupPage.Model
    , groupCreated : Bool
    , accountDeletedResult : Maybe (Result () ())
    , searchText : String
    , searchList : List (Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId)
    , windowWidth : Quantity.Quantity Int Pixels.Pixels
    , windowHeight : Quantity.Quantity Int Pixels.Pixels
    , groupPage : AssocList.Dict (Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId) Evergreen.V71.GroupPage.Model
    , loadedUserConfig : LoadedUserConfig
    , miniLanguageSelectorOpened : Bool
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias BackendUser =
    { name : Evergreen.V71.Name.Name
    , description : Evergreen.V71.Description.Description
    , emailAddress : Evergreen.V71.EmailAddress.EmailAddress
    , profileImage : Evergreen.V71.ProfileImage.ProfileImage
    , timezone : Time.Zone
    , allowEventReminders : Bool
    , subscribedGroups : AssocSet.Set (Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId)
    }


type alias LoginTokenData =
    { creationTime : Time.Posix
    , emailAddress : Evergreen.V71.EmailAddress.EmailAddress
    }


type alias DeleteUserTokenData =
    { creationTime : Time.Posix
    , userId : Evergreen.V71.Id.Id Evergreen.V71.Id.UserId
    }


type alias BackendModel =
    { users : AssocList.Dict (Evergreen.V71.Id.Id Evergreen.V71.Id.UserId) BackendUser
    , groups : AssocList.Dict (Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId) Evergreen.V71.Group.Group
    , deletedGroups : AssocList.Dict (Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId) Evergreen.V71.Group.Group
    , sessions : BiDict.Assoc.BiDict Effect.Lamdera.SessionId (Evergreen.V71.Id.Id Evergreen.V71.Id.UserId)
    , loginAttempts : AssocList.Dict Effect.Lamdera.SessionId (List.Nonempty.Nonempty Time.Posix)
    , connections : AssocList.Dict Effect.Lamdera.SessionId (List.Nonempty.Nonempty Effect.Lamdera.ClientId)
    , logs : Array.Array Log
    , time : Time.Posix
    , secretCounter : Int
    , pendingLoginTokens : AssocList.Dict (Evergreen.V71.Id.Id Evergreen.V71.Id.LoginToken) LoginTokenData
    , pendingDeleteUserTokens : AssocList.Dict (Evergreen.V71.Id.Id Evergreen.V71.Id.DeleteUserToken) DeleteUserTokenData
    }


type FrontendMsg
    = NoOpFrontendMsg
    | UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotTime Time.Posix
    | PressedLogin
    | PressedLogout
    | TypedEmail String
    | PressedSubmitLogin
    | PressedCancelLogin
    | CreateGroupPageMsg Evergreen.V71.CreateGroupPage.Msg
    | ProfileFormMsg Evergreen.V71.ProfilePage.Msg
    | TypedSearchText String
    | SubmittedSearchBox
    | GroupPageMsg Evergreen.V71.GroupPage.Msg
    | GotWindowSize Int Int
    | GotTimeZone (Result Evergreen.V71.TimeZone.Error ( String, Time.Zone ))
    | ScrolledToTop
    | PressedEnableAdmin
    | PressedDisableAdmin
    | PressedThemeToggle
    | LanguageSelected Language
    | GotPrefersDarkTheme Bool
    | GotLanguage String
    | ToggleLanguageSelect


type BackendMsg
    = SentLoginEmail Evergreen.V71.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V71.Postmark.PostmarkSendResponse)
    | SentDeleteUserEmail (Evergreen.V71.Id.Id Evergreen.V71.Id.UserId) (Result Effect.Http.Error Evergreen.V71.Postmark.PostmarkSendResponse)
    | SentEventReminderEmail (Evergreen.V71.Id.Id Evergreen.V71.Id.UserId) (Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId) Evergreen.V71.Group.EventId (Result Effect.Http.Error Evergreen.V71.Postmark.PostmarkSendResponse)
    | SentNewEventNotificationEmail (Evergreen.V71.Id.Id Evergreen.V71.Id.UserId) (Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId) (Result Effect.Http.Error Evergreen.V71.Postmark.PostmarkSendResponse)
    | BackendGotTime Time.Posix
    | Connected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | Disconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NoOpBackendMsg


type GroupRequest
    = GroupNotFound_
    | GroupFound_ Evergreen.V71.Group.Group (AssocList.Dict (Evergreen.V71.Id.Id Evergreen.V71.Id.UserId) Evergreen.V71.FrontendUser.FrontendUser)


type ToFrontend
    = GetGroupResponse (Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId) GroupRequest
    | GetUserResponse (AssocList.Dict (Evergreen.V71.Id.Id Evergreen.V71.Id.UserId) (Result () Evergreen.V71.FrontendUser.FrontendUser))
    | CheckLoginResponse
        (Maybe
            { userId : Evergreen.V71.Id.Id Evergreen.V71.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | LoginWithTokenResponse
        (Result
            ()
            { userId : Evergreen.V71.Id.Id Evergreen.V71.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | GetAdminDataResponse AdminModel
    | CreateGroupResponse (Result Evergreen.V71.CreateGroupPage.CreateGroupError ( Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId, Evergreen.V71.Group.Group ))
    | LogoutResponse
    | ChangeNameResponse Evergreen.V71.Name.Name
    | ChangeDescriptionResponse Evergreen.V71.Description.Description
    | ChangeEmailAddressResponse Evergreen.V71.EmailAddress.EmailAddress
    | DeleteUserResponse (Result () ())
    | ChangeProfileImageResponse Evergreen.V71.ProfileImage.ProfileImage
    | GetMyGroupsResponse
        { myGroups : List ( Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId, Evergreen.V71.Group.Group )
        , subscribedGroups : List ( Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId, Evergreen.V71.Group.Group )
        }
    | SearchGroupsResponse String (List ( Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId, Evergreen.V71.Group.Group ))
    | ChangeGroupNameResponse (Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId) Evergreen.V71.GroupName.GroupName
    | ChangeGroupDescriptionResponse (Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId) Evergreen.V71.Description.Description
    | ChangeGroupVisibilityResponse (Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId) Evergreen.V71.Group.GroupVisibility
    | CreateEventResponse (Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId) (Result Evergreen.V71.GroupPage.CreateEventError Evergreen.V71.Event.Event)
    | EditEventResponse (Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId) Evergreen.V71.Group.EventId (Result Evergreen.V71.Group.EditEventError Evergreen.V71.Event.Event) Time.Posix
    | JoinEventResponse (Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId) Evergreen.V71.Group.EventId (Result Evergreen.V71.Group.JoinEventError ())
    | LeaveEventResponse (Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId) Evergreen.V71.Group.EventId (Result () ())
    | ChangeEventCancellationStatusResponse (Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId) Evergreen.V71.Group.EventId (Result Evergreen.V71.Group.EditCancellationStatusError Evergreen.V71.Event.CancellationStatus) Time.Posix
    | DeleteGroupAdminResponse (Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId)
    | SubscribeResponse (Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId)
    | UnsubscribeResponse (Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId)
    | DeleteGroupUserResponse (Evergreen.V71.Id.Id Evergreen.V71.Id.GroupId)
