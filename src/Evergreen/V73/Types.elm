module Evergreen.V73.Types exposing (..)

import Array
import Browser
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Evergreen.V73.AdminStatus
import Evergreen.V73.BiDict.Assoc2
import Evergreen.V73.Cache
import Evergreen.V73.CreateGroupPage
import Evergreen.V73.Description
import Evergreen.V73.EmailAddress
import Evergreen.V73.Event
import Evergreen.V73.FrontendUser
import Evergreen.V73.Group
import Evergreen.V73.GroupName
import Evergreen.V73.GroupPage
import Evergreen.V73.Id
import Evergreen.V73.Name
import Evergreen.V73.Postmark
import Evergreen.V73.ProfileImage
import Evergreen.V73.ProfilePage
import Evergreen.V73.Route
import Evergreen.V73.TimeZone
import Evergreen.V73.Untrusted
import List.Nonempty
import Pixels
import Quantity
import SeqDict
import SeqSet
import Time
import Url


type ColorTheme
    = LightTheme
    | DarkTheme


type alias LoadingFrontend =
    { navigationKey : Effect.Browser.Navigation.Key
    , route : Evergreen.V73.Route.Route
    , routeToken : Evergreen.V73.Route.Token
    , windowSize : Maybe ( Quantity.Quantity Int Pixels.Pixels, Quantity.Quantity Int Pixels.Pixels )
    , time : Maybe Time.Posix
    , timezone : Maybe Time.Zone
    , theme : ColorTheme
    }


type ToBackend
    = GetGroupRequest (Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId)
    | GetUserRequest (List.Nonempty.Nonempty (Evergreen.V73.Id.Id Evergreen.V73.Id.UserId))
    | CheckLoginRequest
    | LoginWithTokenRequest (Evergreen.V73.Id.Id Evergreen.V73.Id.LoginToken) (Maybe ( Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId, Evergreen.V73.Group.EventId ))
    | GetLoginTokenRequest Evergreen.V73.Route.Route (Evergreen.V73.Untrusted.Untrusted Evergreen.V73.EmailAddress.EmailAddress) (Maybe ( Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId, Evergreen.V73.Group.EventId ))
    | GetAdminDataRequest
    | LogoutRequest
    | CreateGroupRequest (Evergreen.V73.Untrusted.Untrusted Evergreen.V73.GroupName.GroupName) (Evergreen.V73.Untrusted.Untrusted Evergreen.V73.Description.Description) Evergreen.V73.Group.GroupVisibility
    | DeleteUserRequest (Evergreen.V73.Id.Id Evergreen.V73.Id.DeleteUserToken)
    | GetMyGroupsRequest
    | SearchGroupsRequest String
    | GroupRequest (Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId) Evergreen.V73.GroupPage.ToBackend
    | ProfileFormRequest Evergreen.V73.ProfilePage.ToBackend


type Log
    = LogUntrustedCheckFailed Time.Posix ToBackend Evergreen.V73.Id.SessionIdFirst4Chars
    | LogLoginEmail Time.Posix (Result Effect.Http.Error Evergreen.V73.Postmark.PostmarkSendResponse) Evergreen.V73.EmailAddress.EmailAddress
    | LogDeleteAccountEmail Time.Posix (Result Effect.Http.Error Evergreen.V73.Postmark.PostmarkSendResponse) (Evergreen.V73.Id.Id Evergreen.V73.Id.UserId)
    | LogEventReminderEmail Time.Posix (Result Effect.Http.Error Evergreen.V73.Postmark.PostmarkSendResponse) (Evergreen.V73.Id.Id Evergreen.V73.Id.UserId) (Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId) Evergreen.V73.Group.EventId
    | LogNewEventNotificationEmail Time.Posix (Result Effect.Http.Error Evergreen.V73.Postmark.PostmarkSendResponse) (Evergreen.V73.Id.Id Evergreen.V73.Id.UserId) (Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId)
    | LogLoginTokenEmailRequestRateLimited Time.Posix Evergreen.V73.EmailAddress.EmailAddress Evergreen.V73.Id.SessionIdFirst4Chars
    | LogDeleteAccountEmailRequestRateLimited Time.Posix (Evergreen.V73.Id.Id Evergreen.V73.Id.UserId) Evergreen.V73.Id.SessionIdFirst4Chars


type alias AdminModel =
    { cachedEmailAddress : SeqDict.SeqDict (Evergreen.V73.Id.Id Evergreen.V73.Id.UserId) Evergreen.V73.EmailAddress.EmailAddress
    , logs : Array.Array Log
    , lastLogCheck : Time.Posix
    }


type AdminCache
    = AdminCacheNotRequested
    | AdminCached AdminModel
    | AdminCachePending


type alias LoggedIn_ =
    { userId : Evergreen.V73.Id.Id Evergreen.V73.Id.UserId
    , emailAddress : Evergreen.V73.EmailAddress.EmailAddress
    , profileForm : Evergreen.V73.ProfilePage.Model
    , myGroups : Maybe (SeqSet.SeqSet (Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId))
    , subscribedGroups : SeqSet.SeqSet (Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId)
    , adminState : AdminCache
    , adminStatus : Evergreen.V73.AdminStatus.AdminStatus
    }


type LoginStatus
    = LoginStatusPending
    | LoggedIn LoggedIn_
    | NotLoggedIn
        { showLogin : Bool
        , joiningEvent : Maybe ( Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId, Evergreen.V73.Group.EventId )
        }


type alias LoginForm =
    { email : String
    , pressedSubmitEmail : Bool
    , emailSent : Maybe Evergreen.V73.EmailAddress.EmailAddress
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
    , route : Evergreen.V73.Route.Route
    , cachedGroups : SeqDict.SeqDict (Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId) (Evergreen.V73.Cache.Cache Evergreen.V73.Group.Group)
    , cachedUsers : SeqDict.SeqDict (Evergreen.V73.Id.Id Evergreen.V73.Id.UserId) (Evergreen.V73.Cache.Cache Evergreen.V73.FrontendUser.FrontendUser)
    , time : Time.Posix
    , timezone : Time.Zone
    , lastConnectionCheck : Time.Posix
    , loginForm : LoginForm
    , logs : Maybe (Array.Array Log)
    , hasLoginTokenError : Bool
    , groupForm : Evergreen.V73.CreateGroupPage.Model
    , groupCreated : Bool
    , accountDeletedResult : Maybe (Result () ())
    , searchText : String
    , searchList : List (Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId)
    , windowWidth : Quantity.Quantity Int Pixels.Pixels
    , windowHeight : Quantity.Quantity Int Pixels.Pixels
    , groupPage : SeqDict.SeqDict (Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId) Evergreen.V73.GroupPage.Model
    , loadedUserConfig : LoadedUserConfig
    , miniLanguageSelectorOpened : Bool
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias BackendUser =
    { name : Evergreen.V73.Name.Name
    , description : Evergreen.V73.Description.Description
    , emailAddress : Evergreen.V73.EmailAddress.EmailAddress
    , profileImage : Evergreen.V73.ProfileImage.ProfileImage
    , timezone : Time.Zone
    , allowEventReminders : Bool
    , subscribedGroups : SeqSet.SeqSet (Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId)
    }


type alias LoginTokenData =
    { creationTime : Time.Posix
    , emailAddress : Evergreen.V73.EmailAddress.EmailAddress
    }


type alias DeleteUserTokenData =
    { creationTime : Time.Posix
    , userId : Evergreen.V73.Id.Id Evergreen.V73.Id.UserId
    }


type alias BackendModel =
    { users : SeqDict.SeqDict (Evergreen.V73.Id.Id Evergreen.V73.Id.UserId) BackendUser
    , groups : SeqDict.SeqDict (Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId) Evergreen.V73.Group.Group
    , deletedGroups : SeqDict.SeqDict (Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId) Evergreen.V73.Group.Group
    , sessions : Evergreen.V73.BiDict.Assoc2.BiDict Effect.Lamdera.SessionId (Evergreen.V73.Id.Id Evergreen.V73.Id.UserId)
    , loginAttempts : SeqDict.SeqDict Effect.Lamdera.SessionId (List.Nonempty.Nonempty Time.Posix)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (List.Nonempty.Nonempty Effect.Lamdera.ClientId)
    , logs : Array.Array Log
    , time : Time.Posix
    , secretCounter : Int
    , pendingLoginTokens : SeqDict.SeqDict (Evergreen.V73.Id.Id Evergreen.V73.Id.LoginToken) LoginTokenData
    , pendingDeleteUserTokens : SeqDict.SeqDict (Evergreen.V73.Id.Id Evergreen.V73.Id.DeleteUserToken) DeleteUserTokenData
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
    | CreateGroupPageMsg Evergreen.V73.CreateGroupPage.Msg
    | ProfileFormMsg Evergreen.V73.ProfilePage.Msg
    | TypedSearchText String
    | SubmittedSearchBox
    | GroupPageMsg Evergreen.V73.GroupPage.Msg
    | GotWindowSize Int Int
    | GotTimeZone (Result Evergreen.V73.TimeZone.Error ( String, Time.Zone ))
    | ScrolledToTop
    | PressedEnableAdmin
    | PressedDisableAdmin
    | PressedThemeToggle
    | LanguageSelected Language
    | GotPrefersDarkTheme Bool
    | GotLanguage String
    | ToggleLanguageSelect


type BackendMsg
    = SentLoginEmail Evergreen.V73.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V73.Postmark.PostmarkSendResponse)
    | SentDeleteUserEmail (Evergreen.V73.Id.Id Evergreen.V73.Id.UserId) (Result Effect.Http.Error Evergreen.V73.Postmark.PostmarkSendResponse)
    | SentEventReminderEmail (Evergreen.V73.Id.Id Evergreen.V73.Id.UserId) (Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId) Evergreen.V73.Group.EventId (Result Effect.Http.Error Evergreen.V73.Postmark.PostmarkSendResponse)
    | SentNewEventNotificationEmail (Evergreen.V73.Id.Id Evergreen.V73.Id.UserId) (Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId) (Result Effect.Http.Error Evergreen.V73.Postmark.PostmarkSendResponse)
    | BackendGotTime Time.Posix
    | Connected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | Disconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NoOpBackendMsg


type GroupRequest
    = GroupNotFound_
    | GroupFound_ Evergreen.V73.Group.Group (SeqDict.SeqDict (Evergreen.V73.Id.Id Evergreen.V73.Id.UserId) Evergreen.V73.FrontendUser.FrontendUser)


type ToFrontend
    = GetGroupResponse (Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId) GroupRequest
    | GetUserResponse (SeqDict.SeqDict (Evergreen.V73.Id.Id Evergreen.V73.Id.UserId) (Result () Evergreen.V73.FrontendUser.FrontendUser))
    | CheckLoginResponse
        (Maybe
            { userId : Evergreen.V73.Id.Id Evergreen.V73.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | LoginWithTokenResponse
        (Result
            ()
            { userId : Evergreen.V73.Id.Id Evergreen.V73.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | GetAdminDataResponse AdminModel
    | CreateGroupResponse (Result Evergreen.V73.CreateGroupPage.CreateGroupError ( Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId, Evergreen.V73.Group.Group ))
    | LogoutResponse
    | ChangeNameResponse Evergreen.V73.Name.Name
    | ChangeDescriptionResponse Evergreen.V73.Description.Description
    | ChangeEmailAddressResponse Evergreen.V73.EmailAddress.EmailAddress
    | DeleteUserResponse (Result () ())
    | ChangeProfileImageResponse Evergreen.V73.ProfileImage.ProfileImage
    | GetMyGroupsResponse
        { myGroups : List ( Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId, Evergreen.V73.Group.Group )
        , subscribedGroups : List ( Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId, Evergreen.V73.Group.Group )
        }
    | SearchGroupsResponse String (List ( Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId, Evergreen.V73.Group.Group ))
    | ChangeGroupNameResponse (Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId) Evergreen.V73.GroupName.GroupName
    | ChangeGroupDescriptionResponse (Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId) Evergreen.V73.Description.Description
    | ChangeGroupVisibilityResponse (Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId) Evergreen.V73.Group.GroupVisibility
    | CreateEventResponse (Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId) (Result Evergreen.V73.GroupPage.CreateEventError Evergreen.V73.Event.Event)
    | EditEventResponse (Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId) Evergreen.V73.Group.EventId (Result Evergreen.V73.Group.EditEventError Evergreen.V73.Event.Event) Time.Posix
    | JoinEventResponse (Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId) Evergreen.V73.Group.EventId (Result Evergreen.V73.Group.JoinEventError ())
    | LeaveEventResponse (Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId) Evergreen.V73.Group.EventId (Result () ())
    | ChangeEventCancellationStatusResponse (Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId) Evergreen.V73.Group.EventId (Result Evergreen.V73.Group.EditCancellationStatusError Evergreen.V73.Event.CancellationStatus) Time.Posix
    | DeleteGroupAdminResponse (Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId)
    | SubscribeResponse (Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId)
    | UnsubscribeResponse (Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId)
    | DeleteGroupUserResponse (Evergreen.V73.Id.Id Evergreen.V73.Id.GroupId)
