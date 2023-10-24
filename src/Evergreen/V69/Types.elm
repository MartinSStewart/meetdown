module Evergreen.V69.Types exposing (..)

import Array
import AssocList
import AssocSet
import BiDict.Assoc
import Browser
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Evergreen.V69.AdminStatus
import Evergreen.V69.Cache
import Evergreen.V69.CreateGroupPage
import Evergreen.V69.Description
import Evergreen.V69.EmailAddress
import Evergreen.V69.Event
import Evergreen.V69.FrontendUser
import Evergreen.V69.Group
import Evergreen.V69.GroupName
import Evergreen.V69.GroupPage
import Evergreen.V69.Id
import Evergreen.V69.Name
import Evergreen.V69.Postmark
import Evergreen.V69.ProfileImage
import Evergreen.V69.ProfilePage
import Evergreen.V69.Route
import Evergreen.V69.TimeZone
import Evergreen.V69.Untrusted
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
    , route : Evergreen.V69.Route.Route
    , routeToken : Evergreen.V69.Route.Token
    , windowSize : Maybe ( Quantity.Quantity Int Pixels.Pixels, Quantity.Quantity Int Pixels.Pixels )
    , time : Maybe Time.Posix
    , timezone : Maybe Time.Zone
    , theme : ColorTheme
    }


type ToBackend
    = GetGroupRequest (Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId)
    | GetUserRequest (List.Nonempty.Nonempty (Evergreen.V69.Id.Id Evergreen.V69.Id.UserId))
    | CheckLoginRequest
    | LoginWithTokenRequest (Evergreen.V69.Id.Id Evergreen.V69.Id.LoginToken) (Maybe ( Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId, Evergreen.V69.Group.EventId ))
    | GetLoginTokenRequest Evergreen.V69.Route.Route (Evergreen.V69.Untrusted.Untrusted Evergreen.V69.EmailAddress.EmailAddress) (Maybe ( Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId, Evergreen.V69.Group.EventId ))
    | GetAdminDataRequest
    | LogoutRequest
    | CreateGroupRequest (Evergreen.V69.Untrusted.Untrusted Evergreen.V69.GroupName.GroupName) (Evergreen.V69.Untrusted.Untrusted Evergreen.V69.Description.Description) Evergreen.V69.Group.GroupVisibility
    | DeleteUserRequest (Evergreen.V69.Id.Id Evergreen.V69.Id.DeleteUserToken)
    | GetMyGroupsRequest
    | SearchGroupsRequest String
    | GroupRequest (Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId) Evergreen.V69.GroupPage.ToBackend
    | ProfileFormRequest Evergreen.V69.ProfilePage.ToBackend


type Log
    = LogUntrustedCheckFailed Time.Posix ToBackend Evergreen.V69.Id.SessionIdFirst4Chars
    | LogLoginEmail Time.Posix (Result Effect.Http.Error Evergreen.V69.Postmark.PostmarkSendResponse) Evergreen.V69.EmailAddress.EmailAddress
    | LogDeleteAccountEmail Time.Posix (Result Effect.Http.Error Evergreen.V69.Postmark.PostmarkSendResponse) (Evergreen.V69.Id.Id Evergreen.V69.Id.UserId)
    | LogEventReminderEmail Time.Posix (Result Effect.Http.Error Evergreen.V69.Postmark.PostmarkSendResponse) (Evergreen.V69.Id.Id Evergreen.V69.Id.UserId) (Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId) Evergreen.V69.Group.EventId
    | LogNewEventNotificationEmail Time.Posix (Result Effect.Http.Error Evergreen.V69.Postmark.PostmarkSendResponse) (Evergreen.V69.Id.Id Evergreen.V69.Id.UserId) (Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId)
    | LogLoginTokenEmailRequestRateLimited Time.Posix Evergreen.V69.EmailAddress.EmailAddress Evergreen.V69.Id.SessionIdFirst4Chars
    | LogDeleteAccountEmailRequestRateLimited Time.Posix (Evergreen.V69.Id.Id Evergreen.V69.Id.UserId) Evergreen.V69.Id.SessionIdFirst4Chars


type alias AdminModel =
    { cachedEmailAddress : AssocList.Dict (Evergreen.V69.Id.Id Evergreen.V69.Id.UserId) Evergreen.V69.EmailAddress.EmailAddress
    , logs : Array.Array Log
    , lastLogCheck : Time.Posix
    }


type AdminCache
    = AdminCacheNotRequested
    | AdminCached AdminModel
    | AdminCachePending


type alias LoggedIn_ =
    { userId : Evergreen.V69.Id.Id Evergreen.V69.Id.UserId
    , emailAddress : Evergreen.V69.EmailAddress.EmailAddress
    , profileForm : Evergreen.V69.ProfilePage.Model
    , myGroups : Maybe (AssocSet.Set (Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId))
    , subscribedGroups : AssocSet.Set (Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId)
    , adminState : AdminCache
    , adminStatus : Evergreen.V69.AdminStatus.AdminStatus
    }


type LoginStatus
    = LoginStatusPending
    | LoggedIn LoggedIn_
    | NotLoggedIn
        { showLogin : Bool
        , joiningEvent : Maybe ( Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId, Evergreen.V69.Group.EventId )
        }


type alias LoginForm =
    { email : String
    , pressedSubmitEmail : Bool
    , emailSent : Maybe Evergreen.V69.EmailAddress.EmailAddress
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
    , route : Evergreen.V69.Route.Route
    , cachedGroups : AssocList.Dict (Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId) (Evergreen.V69.Cache.Cache Evergreen.V69.Group.Group)
    , cachedUsers : AssocList.Dict (Evergreen.V69.Id.Id Evergreen.V69.Id.UserId) (Evergreen.V69.Cache.Cache Evergreen.V69.FrontendUser.FrontendUser)
    , time : Time.Posix
    , timezone : Time.Zone
    , lastConnectionCheck : Time.Posix
    , loginForm : LoginForm
    , logs : Maybe (Array.Array Log)
    , hasLoginTokenError : Bool
    , groupForm : Evergreen.V69.CreateGroupPage.Model
    , groupCreated : Bool
    , accountDeletedResult : Maybe (Result () ())
    , searchText : String
    , searchList : List (Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId)
    , windowWidth : Quantity.Quantity Int Pixels.Pixels
    , windowHeight : Quantity.Quantity Int Pixels.Pixels
    , groupPage : AssocList.Dict (Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId) Evergreen.V69.GroupPage.Model
    , loadedUserConfig : LoadedUserConfig
    , miniLanguageSelectorOpened : Bool
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias BackendUser =
    { name : Evergreen.V69.Name.Name
    , description : Evergreen.V69.Description.Description
    , emailAddress : Evergreen.V69.EmailAddress.EmailAddress
    , profileImage : Evergreen.V69.ProfileImage.ProfileImage
    , timezone : Time.Zone
    , allowEventReminders : Bool
    , subscribedGroups : AssocSet.Set (Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId)
    }


type alias LoginTokenData =
    { creationTime : Time.Posix
    , emailAddress : Evergreen.V69.EmailAddress.EmailAddress
    }


type alias DeleteUserTokenData =
    { creationTime : Time.Posix
    , userId : Evergreen.V69.Id.Id Evergreen.V69.Id.UserId
    }


type alias BackendModel =
    { users : AssocList.Dict (Evergreen.V69.Id.Id Evergreen.V69.Id.UserId) BackendUser
    , groups : AssocList.Dict (Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId) Evergreen.V69.Group.Group
    , deletedGroups : AssocList.Dict (Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId) Evergreen.V69.Group.Group
    , sessions : BiDict.Assoc.BiDict Effect.Lamdera.SessionId (Evergreen.V69.Id.Id Evergreen.V69.Id.UserId)
    , loginAttempts : AssocList.Dict Effect.Lamdera.SessionId (List.Nonempty.Nonempty Time.Posix)
    , connections : AssocList.Dict Effect.Lamdera.SessionId (List.Nonempty.Nonempty Effect.Lamdera.ClientId)
    , logs : Array.Array Log
    , time : Time.Posix
    , secretCounter : Int
    , pendingLoginTokens : AssocList.Dict (Evergreen.V69.Id.Id Evergreen.V69.Id.LoginToken) LoginTokenData
    , pendingDeleteUserTokens : AssocList.Dict (Evergreen.V69.Id.Id Evergreen.V69.Id.DeleteUserToken) DeleteUserTokenData
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
    | CreateGroupPageMsg Evergreen.V69.CreateGroupPage.Msg
    | ProfileFormMsg Evergreen.V69.ProfilePage.Msg
    | TypedSearchText String
    | SubmittedSearchBox
    | GroupPageMsg Evergreen.V69.GroupPage.Msg
    | GotWindowSize Int Int
    | GotTimeZone (Result Evergreen.V69.TimeZone.Error ( String, Time.Zone ))
    | ScrolledToTop
    | PressedEnableAdmin
    | PressedDisableAdmin
    | PressedThemeToggle
    | LanguageSelected Language
    | GotPrefersDarkTheme Bool
    | GotLanguage String
    | ToggleLanguageSelect


type BackendMsg
    = SentLoginEmail Evergreen.V69.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V69.Postmark.PostmarkSendResponse)
    | SentDeleteUserEmail (Evergreen.V69.Id.Id Evergreen.V69.Id.UserId) (Result Effect.Http.Error Evergreen.V69.Postmark.PostmarkSendResponse)
    | SentEventReminderEmail (Evergreen.V69.Id.Id Evergreen.V69.Id.UserId) (Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId) Evergreen.V69.Group.EventId (Result Effect.Http.Error Evergreen.V69.Postmark.PostmarkSendResponse)
    | SentNewEventNotificationEmail (Evergreen.V69.Id.Id Evergreen.V69.Id.UserId) (Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId) (Result Effect.Http.Error Evergreen.V69.Postmark.PostmarkSendResponse)
    | BackendGotTime Time.Posix
    | Connected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | Disconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NoOpBackendMsg


type GroupRequest
    = GroupNotFound_
    | GroupFound_ Evergreen.V69.Group.Group (AssocList.Dict (Evergreen.V69.Id.Id Evergreen.V69.Id.UserId) Evergreen.V69.FrontendUser.FrontendUser)


type ToFrontend
    = GetGroupResponse (Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId) GroupRequest
    | GetUserResponse (AssocList.Dict (Evergreen.V69.Id.Id Evergreen.V69.Id.UserId) (Result () Evergreen.V69.FrontendUser.FrontendUser))
    | CheckLoginResponse
        (Maybe
            { userId : Evergreen.V69.Id.Id Evergreen.V69.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | LoginWithTokenResponse
        (Result
            ()
            { userId : Evergreen.V69.Id.Id Evergreen.V69.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | GetAdminDataResponse AdminModel
    | CreateGroupResponse (Result Evergreen.V69.CreateGroupPage.CreateGroupError ( Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId, Evergreen.V69.Group.Group ))
    | LogoutResponse
    | ChangeNameResponse Evergreen.V69.Name.Name
    | ChangeDescriptionResponse Evergreen.V69.Description.Description
    | ChangeEmailAddressResponse Evergreen.V69.EmailAddress.EmailAddress
    | DeleteUserResponse (Result () ())
    | ChangeProfileImageResponse Evergreen.V69.ProfileImage.ProfileImage
    | GetMyGroupsResponse
        { myGroups : List ( Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId, Evergreen.V69.Group.Group )
        , subscribedGroups : List ( Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId, Evergreen.V69.Group.Group )
        }
    | SearchGroupsResponse String (List ( Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId, Evergreen.V69.Group.Group ))
    | ChangeGroupNameResponse (Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId) Evergreen.V69.GroupName.GroupName
    | ChangeGroupDescriptionResponse (Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId) Evergreen.V69.Description.Description
    | ChangeGroupVisibilityResponse (Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId) Evergreen.V69.Group.GroupVisibility
    | CreateEventResponse (Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId) (Result Evergreen.V69.GroupPage.CreateEventError Evergreen.V69.Event.Event)
    | EditEventResponse (Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId) Evergreen.V69.Group.EventId (Result Evergreen.V69.Group.EditEventError Evergreen.V69.Event.Event) Time.Posix
    | JoinEventResponse (Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId) Evergreen.V69.Group.EventId (Result Evergreen.V69.Group.JoinEventError ())
    | LeaveEventResponse (Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId) Evergreen.V69.Group.EventId (Result () ())
    | ChangeEventCancellationStatusResponse (Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId) Evergreen.V69.Group.EventId (Result Evergreen.V69.Group.EditCancellationStatusError Evergreen.V69.Event.CancellationStatus) Time.Posix
    | DeleteGroupAdminResponse (Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId)
    | SubscribeResponse (Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId)
    | UnsubscribeResponse (Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId)
    | DeleteGroupUserResponse (Evergreen.V69.Id.Id Evergreen.V69.Id.GroupId)
