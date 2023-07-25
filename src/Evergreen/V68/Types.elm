module Evergreen.V68.Types exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc
import Browser
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Evergreen.V68.AdminStatus
import Evergreen.V68.Cache
import Evergreen.V68.CreateGroupPage
import Evergreen.V68.Description
import Evergreen.V68.EmailAddress
import Evergreen.V68.Event
import Evergreen.V68.FrontendUser
import Evergreen.V68.Group
import Evergreen.V68.GroupName
import Evergreen.V68.GroupPage
import Evergreen.V68.Id
import Evergreen.V68.Name
import Evergreen.V68.Postmark
import Evergreen.V68.ProfileImage
import Evergreen.V68.ProfilePage
import Evergreen.V68.Route
import Evergreen.V68.TimeZone
import Evergreen.V68.Untrusted
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
    , route : Evergreen.V68.Route.Route
    , routeToken : Evergreen.V68.Route.Token
    , windowSize : Maybe ( Quantity.Quantity Int Pixels.Pixels, Quantity.Quantity Int Pixels.Pixels )
    , time : Maybe Time.Posix
    , timezone : Maybe Time.Zone
    , theme : ColorTheme
    }


type ToBackend
    = GetGroupRequest (Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId)
    | GetUserRequest (List.Nonempty.Nonempty (Evergreen.V68.Id.Id Evergreen.V68.Id.UserId))
    | CheckLoginRequest
    | LoginWithTokenRequest (Evergreen.V68.Id.Id Evergreen.V68.Id.LoginToken) (Maybe ( Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId, Evergreen.V68.Group.EventId ))
    | GetLoginTokenRequest Evergreen.V68.Route.Route (Evergreen.V68.Untrusted.Untrusted Evergreen.V68.EmailAddress.EmailAddress) (Maybe ( Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId, Evergreen.V68.Group.EventId ))
    | GetAdminDataRequest
    | LogoutRequest
    | CreateGroupRequest (Evergreen.V68.Untrusted.Untrusted Evergreen.V68.GroupName.GroupName) (Evergreen.V68.Untrusted.Untrusted Evergreen.V68.Description.Description) Evergreen.V68.Group.GroupVisibility
    | DeleteUserRequest (Evergreen.V68.Id.Id Evergreen.V68.Id.DeleteUserToken)
    | GetMyGroupsRequest
    | SearchGroupsRequest String
    | GroupRequest (Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId) Evergreen.V68.GroupPage.ToBackend
    | ProfileFormRequest Evergreen.V68.ProfilePage.ToBackend


type Log
    = LogUntrustedCheckFailed Time.Posix ToBackend Evergreen.V68.Id.SessionIdFirst4Chars
    | LogLoginEmail Time.Posix (Result Effect.Http.Error Evergreen.V68.Postmark.PostmarkSendResponse) Evergreen.V68.EmailAddress.EmailAddress
    | LogDeleteAccountEmail Time.Posix (Result Effect.Http.Error Evergreen.V68.Postmark.PostmarkSendResponse) (Evergreen.V68.Id.Id Evergreen.V68.Id.UserId)
    | LogEventReminderEmail Time.Posix (Result Effect.Http.Error Evergreen.V68.Postmark.PostmarkSendResponse) (Evergreen.V68.Id.Id Evergreen.V68.Id.UserId) (Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId) Evergreen.V68.Group.EventId
    | LogNewEventNotificationEmail Time.Posix (Result Effect.Http.Error Evergreen.V68.Postmark.PostmarkSendResponse) (Evergreen.V68.Id.Id Evergreen.V68.Id.UserId) (Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId)
    | LogLoginTokenEmailRequestRateLimited Time.Posix Evergreen.V68.EmailAddress.EmailAddress Evergreen.V68.Id.SessionIdFirst4Chars
    | LogDeleteAccountEmailRequestRateLimited Time.Posix (Evergreen.V68.Id.Id Evergreen.V68.Id.UserId) Evergreen.V68.Id.SessionIdFirst4Chars


type alias AdminModel =
    { cachedEmailAddress : AssocList.Dict (Evergreen.V68.Id.Id Evergreen.V68.Id.UserId) Evergreen.V68.EmailAddress.EmailAddress
    , logs : Array.Array Log
    , lastLogCheck : Time.Posix
    }


type AdminCache
    = AdminCacheNotRequested
    | AdminCached AdminModel
    | AdminCachePending


type alias LoggedIn_ =
    { userId : Evergreen.V68.Id.Id Evergreen.V68.Id.UserId
    , emailAddress : Evergreen.V68.EmailAddress.EmailAddress
    , profileForm : Evergreen.V68.ProfilePage.Model
    , myGroups : Maybe (AssocSet.Set (Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId))
    , subscribedGroups : AssocSet.Set (Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId)
    , adminState : AdminCache
    , adminStatus : Evergreen.V68.AdminStatus.AdminStatus
    }


type LoginStatus
    = LoginStatusPending
    | LoggedIn LoggedIn_
    | NotLoggedIn
        { showLogin : Bool
        , joiningEvent : Maybe ( Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId, Evergreen.V68.Group.EventId )
        }


type alias LoginForm =
    { email : String
    , pressedSubmitEmail : Bool
    , emailSent : Maybe Evergreen.V68.EmailAddress.EmailAddress
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
    , route : Evergreen.V68.Route.Route
    , cachedGroups : AssocList.Dict (Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId) (Evergreen.V68.Cache.Cache Evergreen.V68.Group.Group)
    , cachedUsers : AssocList.Dict (Evergreen.V68.Id.Id Evergreen.V68.Id.UserId) (Evergreen.V68.Cache.Cache Evergreen.V68.FrontendUser.FrontendUser)
    , time : Time.Posix
    , timezone : Time.Zone
    , lastConnectionCheck : Time.Posix
    , loginForm : LoginForm
    , logs : Maybe (Array.Array Log)
    , hasLoginTokenError : Bool
    , groupForm : Evergreen.V68.CreateGroupPage.Model
    , groupCreated : Bool
    , accountDeletedResult : Maybe (Result () ())
    , searchText : String
    , searchList : List (Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId)
    , windowWidth : Quantity.Quantity Int Pixels.Pixels
    , windowHeight : Quantity.Quantity Int Pixels.Pixels
    , groupPage : AssocList.Dict (Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId) Evergreen.V68.GroupPage.Model
    , loadedUserConfig : LoadedUserConfig
    , miniLanguageSelectorOpened : Bool
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias BackendUser =
    { name : Evergreen.V68.Name.Name
    , description : Evergreen.V68.Description.Description
    , emailAddress : Evergreen.V68.EmailAddress.EmailAddress
    , profileImage : Evergreen.V68.ProfileImage.ProfileImage
    , timezone : Time.Zone
    , allowEventReminders : Bool
    , subscribedGroups : AssocSet.Set (Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId)
    }


type alias LoginTokenData =
    { creationTime : Time.Posix
    , emailAddress : Evergreen.V68.EmailAddress.EmailAddress
    }


type alias DeleteUserTokenData =
    { creationTime : Time.Posix
    , userId : Evergreen.V68.Id.Id Evergreen.V68.Id.UserId
    }


type alias BackendModel =
    { users : AssocList.Dict (Evergreen.V68.Id.Id Evergreen.V68.Id.UserId) BackendUser
    , groups : AssocList.Dict (Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId) Evergreen.V68.Group.Group
    , deletedGroups : AssocList.Dict (Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId) Evergreen.V68.Group.Group
    , sessions : BiDict.Assoc.BiDict Effect.Lamdera.SessionId (Evergreen.V68.Id.Id Evergreen.V68.Id.UserId)
    , loginAttempts : AssocList.Dict Effect.Lamdera.SessionId (List.Nonempty.Nonempty Time.Posix)
    , connections : AssocList.Dict Effect.Lamdera.SessionId (List.Nonempty.Nonempty Effect.Lamdera.ClientId)
    , logs : Array.Array Log
    , time : Time.Posix
    , secretCounter : Int
    , pendingLoginTokens : AssocList.Dict (Evergreen.V68.Id.Id Evergreen.V68.Id.LoginToken) LoginTokenData
    , pendingDeleteUserTokens : AssocList.Dict (Evergreen.V68.Id.Id Evergreen.V68.Id.DeleteUserToken) DeleteUserTokenData
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
    | CreateGroupPageMsg Evergreen.V68.CreateGroupPage.Msg
    | ProfileFormMsg Evergreen.V68.ProfilePage.Msg
    | TypedSearchText String
    | SubmittedSearchBox
    | GroupPageMsg Evergreen.V68.GroupPage.Msg
    | GotWindowSize Int Int
    | GotTimeZone (Result Evergreen.V68.TimeZone.Error ( String, Time.Zone ))
    | ScrolledToTop
    | PressedEnableAdmin
    | PressedDisableAdmin
    | PressedThemeToggle
    | LanguageSelected Language
    | GotPrefersDarkTheme Bool
    | GotLanguage String
    | ToggleLanguageSelect


type BackendMsg
    = SentLoginEmail Evergreen.V68.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V68.Postmark.PostmarkSendResponse)
    | SentDeleteUserEmail (Evergreen.V68.Id.Id Evergreen.V68.Id.UserId) (Result Effect.Http.Error Evergreen.V68.Postmark.PostmarkSendResponse)
    | SentEventReminderEmail (Evergreen.V68.Id.Id Evergreen.V68.Id.UserId) (Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId) Evergreen.V68.Group.EventId (Result Effect.Http.Error Evergreen.V68.Postmark.PostmarkSendResponse)
    | SentNewEventNotificationEmail (Evergreen.V68.Id.Id Evergreen.V68.Id.UserId) (Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId) (Result Effect.Http.Error Evergreen.V68.Postmark.PostmarkSendResponse)
    | BackendGotTime Time.Posix
    | Connected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | Disconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NoOpBackendMsg


type GroupRequest
    = GroupNotFound_
    | GroupFound_ Evergreen.V68.Group.Group (AssocList.Dict (Evergreen.V68.Id.Id Evergreen.V68.Id.UserId) Evergreen.V68.FrontendUser.FrontendUser)


type ToFrontend
    = GetGroupResponse (Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId) GroupRequest
    | GetUserResponse (AssocList.Dict (Evergreen.V68.Id.Id Evergreen.V68.Id.UserId) (Result () Evergreen.V68.FrontendUser.FrontendUser))
    | CheckLoginResponse
        (Maybe
            { userId : Evergreen.V68.Id.Id Evergreen.V68.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | LoginWithTokenResponse
        (Result
            ()
            { userId : Evergreen.V68.Id.Id Evergreen.V68.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | GetAdminDataResponse AdminModel
    | CreateGroupResponse (Result Evergreen.V68.CreateGroupPage.CreateGroupError ( Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId, Evergreen.V68.Group.Group ))
    | LogoutResponse
    | ChangeNameResponse Evergreen.V68.Name.Name
    | ChangeDescriptionResponse Evergreen.V68.Description.Description
    | ChangeEmailAddressResponse Evergreen.V68.EmailAddress.EmailAddress
    | DeleteUserResponse (Result () ())
    | ChangeProfileImageResponse Evergreen.V68.ProfileImage.ProfileImage
    | GetMyGroupsResponse
        { myGroups : List ( Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId, Evergreen.V68.Group.Group )
        , subscribedGroups : List ( Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId, Evergreen.V68.Group.Group )
        }
    | SearchGroupsResponse String (List ( Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId, Evergreen.V68.Group.Group ))
    | ChangeGroupNameResponse (Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId) Evergreen.V68.GroupName.GroupName
    | ChangeGroupDescriptionResponse (Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId) Evergreen.V68.Description.Description
    | ChangeGroupVisibilityResponse (Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId) Evergreen.V68.Group.GroupVisibility
    | CreateEventResponse (Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId) (Result Evergreen.V68.GroupPage.CreateEventError Evergreen.V68.Event.Event)
    | EditEventResponse (Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId) Evergreen.V68.Group.EventId (Result Evergreen.V68.Group.EditEventError Evergreen.V68.Event.Event) Time.Posix
    | JoinEventResponse (Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId) Evergreen.V68.Group.EventId (Result Evergreen.V68.Group.JoinEventError ())
    | LeaveEventResponse (Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId) Evergreen.V68.Group.EventId (Result () ())
    | ChangeEventCancellationStatusResponse (Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId) Evergreen.V68.Group.EventId (Result Evergreen.V68.Group.EditCancellationStatusError Evergreen.V68.Event.CancellationStatus) Time.Posix
    | DeleteGroupAdminResponse (Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId)
    | SubscribeResponse (Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId)
    | UnsubscribeResponse (Evergreen.V68.Id.Id Evergreen.V68.Id.GroupId)
