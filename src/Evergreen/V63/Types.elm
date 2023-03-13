module Evergreen.V63.Types exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc
import Browser
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Evergreen.V63.AdminStatus
import Evergreen.V63.Cache
import Evergreen.V63.CreateGroupPage
import Evergreen.V63.Description
import Evergreen.V63.EmailAddress
import Evergreen.V63.Event
import Evergreen.V63.FrontendUser
import Evergreen.V63.Group
import Evergreen.V63.GroupName
import Evergreen.V63.GroupPage
import Evergreen.V63.Id
import Evergreen.V63.Name
import Evergreen.V63.Postmark
import Evergreen.V63.ProfileImage
import Evergreen.V63.ProfilePage
import Evergreen.V63.Route
import Evergreen.V63.TimeZone
import Evergreen.V63.Untrusted
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
    , route : Evergreen.V63.Route.Route
    , routeToken : Evergreen.V63.Route.Token
    , windowSize : Maybe ( Quantity.Quantity Int Pixels.Pixels, Quantity.Quantity Int Pixels.Pixels )
    , time : Maybe Time.Posix
    , timezone : Maybe Time.Zone
    , theme : ColorTheme
    }


type ToBackend
    = GetGroupRequest (Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId)
    | GetUserRequest (List.Nonempty.Nonempty (Evergreen.V63.Id.Id Evergreen.V63.Id.UserId))
    | CheckLoginRequest
    | LoginWithTokenRequest (Evergreen.V63.Id.Id Evergreen.V63.Id.LoginToken) (Maybe ( Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId, Evergreen.V63.Group.EventId ))
    | GetLoginTokenRequest Evergreen.V63.Route.Route (Evergreen.V63.Untrusted.Untrusted Evergreen.V63.EmailAddress.EmailAddress) (Maybe ( Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId, Evergreen.V63.Group.EventId ))
    | GetAdminDataRequest
    | LogoutRequest
    | CreateGroupRequest (Evergreen.V63.Untrusted.Untrusted Evergreen.V63.GroupName.GroupName) (Evergreen.V63.Untrusted.Untrusted Evergreen.V63.Description.Description) Evergreen.V63.Group.GroupVisibility
    | DeleteUserRequest (Evergreen.V63.Id.Id Evergreen.V63.Id.DeleteUserToken)
    | GetMyGroupsRequest
    | SearchGroupsRequest String
    | GroupRequest (Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId) Evergreen.V63.GroupPage.ToBackend
    | ProfileFormRequest Evergreen.V63.ProfilePage.ToBackend


type Log
    = LogUntrustedCheckFailed Time.Posix ToBackend Evergreen.V63.Id.SessionIdFirst4Chars
    | LogLoginEmail Time.Posix (Result Effect.Http.Error Evergreen.V63.Postmark.PostmarkSendResponse) Evergreen.V63.EmailAddress.EmailAddress
    | LogDeleteAccountEmail Time.Posix (Result Effect.Http.Error Evergreen.V63.Postmark.PostmarkSendResponse) (Evergreen.V63.Id.Id Evergreen.V63.Id.UserId)
    | LogEventReminderEmail Time.Posix (Result Effect.Http.Error Evergreen.V63.Postmark.PostmarkSendResponse) (Evergreen.V63.Id.Id Evergreen.V63.Id.UserId) (Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId) Evergreen.V63.Group.EventId
    | LogNewEventNotificationEmail Time.Posix (Result Effect.Http.Error Evergreen.V63.Postmark.PostmarkSendResponse) (Evergreen.V63.Id.Id Evergreen.V63.Id.UserId) (Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId)
    | LogLoginTokenEmailRequestRateLimited Time.Posix Evergreen.V63.EmailAddress.EmailAddress Evergreen.V63.Id.SessionIdFirst4Chars
    | LogDeleteAccountEmailRequestRateLimited Time.Posix (Evergreen.V63.Id.Id Evergreen.V63.Id.UserId) Evergreen.V63.Id.SessionIdFirst4Chars


type alias AdminModel =
    { cachedEmailAddress : AssocList.Dict (Evergreen.V63.Id.Id Evergreen.V63.Id.UserId) Evergreen.V63.EmailAddress.EmailAddress
    , logs : Array.Array Log
    , lastLogCheck : Time.Posix
    }


type AdminCache
    = AdminCacheNotRequested
    | AdminCached AdminModel
    | AdminCachePending


type alias LoggedIn_ =
    { userId : Evergreen.V63.Id.Id Evergreen.V63.Id.UserId
    , emailAddress : Evergreen.V63.EmailAddress.EmailAddress
    , profileForm : Evergreen.V63.ProfilePage.Model
    , myGroups : Maybe (AssocSet.Set (Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId))
    , subscribedGroups : AssocSet.Set (Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId)
    , adminState : AdminCache
    , adminStatus : Evergreen.V63.AdminStatus.AdminStatus
    }


type LoginStatus
    = LoginStatusPending
    | LoggedIn LoggedIn_
    | NotLoggedIn
        { showLogin : Bool
        , joiningEvent : Maybe ( Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId, Evergreen.V63.Group.EventId )
        }


type alias LoginForm =
    { email : String
    , pressedSubmitEmail : Bool
    , emailSent : Maybe Evergreen.V63.EmailAddress.EmailAddress
    }


type Language
    = English
    | French
    | Spanish


type alias LoadedUserConfig =
    { theme : ColorTheme
    , language : Language
    }


type alias LoadedFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , loginStatus : LoginStatus
    , route : Evergreen.V63.Route.Route
    , cachedGroups : AssocList.Dict (Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId) (Evergreen.V63.Cache.Cache Evergreen.V63.Group.Group)
    , cachedUsers : AssocList.Dict (Evergreen.V63.Id.Id Evergreen.V63.Id.UserId) (Evergreen.V63.Cache.Cache Evergreen.V63.FrontendUser.FrontendUser)
    , time : Time.Posix
    , timezone : Time.Zone
    , lastConnectionCheck : Time.Posix
    , loginForm : LoginForm
    , logs : Maybe (Array.Array Log)
    , hasLoginTokenError : Bool
    , groupForm : Evergreen.V63.CreateGroupPage.Model
    , groupCreated : Bool
    , accountDeletedResult : Maybe (Result () ())
    , searchText : String
    , searchList : List (Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId)
    , windowWidth : Quantity.Quantity Int Pixels.Pixels
    , windowHeight : Quantity.Quantity Int Pixels.Pixels
    , groupPage : AssocList.Dict (Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId) Evergreen.V63.GroupPage.Model
    , loadedUserConfig : LoadedUserConfig
    , miniLanguageSelectorOpened : Bool
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias BackendUser =
    { name : Evergreen.V63.Name.Name
    , description : Evergreen.V63.Description.Description
    , emailAddress : Evergreen.V63.EmailAddress.EmailAddress
    , profileImage : Evergreen.V63.ProfileImage.ProfileImage
    , timezone : Time.Zone
    , allowEventReminders : Bool
    , subscribedGroups : AssocSet.Set (Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId)
    }


type alias LoginTokenData =
    { creationTime : Time.Posix
    , emailAddress : Evergreen.V63.EmailAddress.EmailAddress
    }


type alias DeleteUserTokenData =
    { creationTime : Time.Posix
    , userId : Evergreen.V63.Id.Id Evergreen.V63.Id.UserId
    }


type alias BackendModel =
    { users : AssocList.Dict (Evergreen.V63.Id.Id Evergreen.V63.Id.UserId) BackendUser
    , groups : AssocList.Dict (Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId) Evergreen.V63.Group.Group
    , deletedGroups : AssocList.Dict (Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId) Evergreen.V63.Group.Group
    , sessions : BiDict.Assoc.BiDict Effect.Lamdera.SessionId (Evergreen.V63.Id.Id Evergreen.V63.Id.UserId)
    , loginAttempts : AssocList.Dict Effect.Lamdera.SessionId (List.Nonempty.Nonempty Time.Posix)
    , connections : AssocList.Dict Effect.Lamdera.SessionId (List.Nonempty.Nonempty Effect.Lamdera.ClientId)
    , logs : Array.Array Log
    , time : Time.Posix
    , secretCounter : Int
    , pendingLoginTokens : AssocList.Dict (Evergreen.V63.Id.Id Evergreen.V63.Id.LoginToken) LoginTokenData
    , pendingDeleteUserTokens : AssocList.Dict (Evergreen.V63.Id.Id Evergreen.V63.Id.DeleteUserToken) DeleteUserTokenData
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
    | CreateGroupPageMsg Evergreen.V63.CreateGroupPage.Msg
    | ProfileFormMsg Evergreen.V63.ProfilePage.Msg
    | TypedSearchText String
    | SubmittedSearchBox
    | GroupPageMsg Evergreen.V63.GroupPage.Msg
    | GotWindowSize Int Int
    | GotTimeZone (Result Evergreen.V63.TimeZone.Error ( String, Time.Zone ))
    | ScrolledToTop
    | PressedEnableAdmin
    | PressedDisableAdmin
    | PressedThemeToggle
    | LanguageSelected Language
    | GotPrefersDarkTheme Bool
    | GotLanguage String
    | ToggleLanguageSelect


type BackendMsg
    = SentLoginEmail Evergreen.V63.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V63.Postmark.PostmarkSendResponse)
    | SentDeleteUserEmail (Evergreen.V63.Id.Id Evergreen.V63.Id.UserId) (Result Effect.Http.Error Evergreen.V63.Postmark.PostmarkSendResponse)
    | SentEventReminderEmail (Evergreen.V63.Id.Id Evergreen.V63.Id.UserId) (Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId) Evergreen.V63.Group.EventId (Result Effect.Http.Error Evergreen.V63.Postmark.PostmarkSendResponse)
    | SentNewEventNotificationEmail (Evergreen.V63.Id.Id Evergreen.V63.Id.UserId) (Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId) (Result Effect.Http.Error Evergreen.V63.Postmark.PostmarkSendResponse)
    | BackendGotTime Time.Posix
    | Connected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | Disconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId


type GroupRequest
    = GroupNotFound_
    | GroupFound_ Evergreen.V63.Group.Group (AssocList.Dict (Evergreen.V63.Id.Id Evergreen.V63.Id.UserId) Evergreen.V63.FrontendUser.FrontendUser)


type ToFrontend
    = GetGroupResponse (Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId) GroupRequest
    | GetUserResponse (AssocList.Dict (Evergreen.V63.Id.Id Evergreen.V63.Id.UserId) (Result () Evergreen.V63.FrontendUser.FrontendUser))
    | CheckLoginResponse
        (Maybe
            { userId : Evergreen.V63.Id.Id Evergreen.V63.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | LoginWithTokenResponse
        (Result
            ()
            { userId : Evergreen.V63.Id.Id Evergreen.V63.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | GetAdminDataResponse AdminModel
    | CreateGroupResponse (Result Evergreen.V63.CreateGroupPage.CreateGroupError ( Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId, Evergreen.V63.Group.Group ))
    | LogoutResponse
    | ChangeNameResponse Evergreen.V63.Name.Name
    | ChangeDescriptionResponse Evergreen.V63.Description.Description
    | ChangeEmailAddressResponse Evergreen.V63.EmailAddress.EmailAddress
    | DeleteUserResponse (Result () ())
    | ChangeProfileImageResponse Evergreen.V63.ProfileImage.ProfileImage
    | GetMyGroupsResponse
        { myGroups : List ( Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId, Evergreen.V63.Group.Group )
        , subscribedGroups : List ( Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId, Evergreen.V63.Group.Group )
        }
    | SearchGroupsResponse String (List ( Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId, Evergreen.V63.Group.Group ))
    | ChangeGroupNameResponse (Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId) Evergreen.V63.GroupName.GroupName
    | ChangeGroupDescriptionResponse (Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId) Evergreen.V63.Description.Description
    | ChangeGroupVisibilityResponse (Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId) Evergreen.V63.Group.GroupVisibility
    | CreateEventResponse (Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId) (Result Evergreen.V63.GroupPage.CreateEventError Evergreen.V63.Event.Event)
    | EditEventResponse (Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId) Evergreen.V63.Group.EventId (Result Evergreen.V63.Group.EditEventError Evergreen.V63.Event.Event) Time.Posix
    | JoinEventResponse (Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId) Evergreen.V63.Group.EventId (Result Evergreen.V63.Group.JoinEventError ())
    | LeaveEventResponse (Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId) Evergreen.V63.Group.EventId (Result () ())
    | ChangeEventCancellationStatusResponse (Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId) Evergreen.V63.Group.EventId (Result Evergreen.V63.Group.EditCancellationStatusError Evergreen.V63.Event.CancellationStatus) Time.Posix
    | DeleteGroupAdminResponse (Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId)
    | SubscribeResponse (Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId)
    | UnsubscribeResponse (Evergreen.V63.Id.Id Evergreen.V63.Id.GroupId)
