module Evergreen.V74.Types exposing (..)

import Array
import Browser
import Effect.Browser.Navigation
import Effect.Http
import Effect.Lamdera
import Evergreen.V74.AdminStatus
import Evergreen.V74.BiDict.Assoc2
import Evergreen.V74.Cache
import Evergreen.V74.CreateGroupPage
import Evergreen.V74.Description
import Evergreen.V74.EmailAddress
import Evergreen.V74.Event
import Evergreen.V74.FrontendUser
import Evergreen.V74.Group
import Evergreen.V74.GroupName
import Evergreen.V74.GroupPage
import Evergreen.V74.Id
import Evergreen.V74.Name
import Evergreen.V74.Postmark
import Evergreen.V74.ProfileImage
import Evergreen.V74.ProfilePage
import Evergreen.V74.Route
import Evergreen.V74.TimeZone
import Evergreen.V74.Untrusted
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
    , route : Evergreen.V74.Route.Route
    , routeToken : Evergreen.V74.Route.Token
    , windowSize : Maybe ( Quantity.Quantity Int Pixels.Pixels, Quantity.Quantity Int Pixels.Pixels )
    , time : Maybe Time.Posix
    , timezone : Maybe (Result () Time.Zone)
    , theme : ColorTheme
    }


type ToBackend
    = GetGroupRequest (Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId)
    | GetUserRequest (List.Nonempty.Nonempty (Evergreen.V74.Id.Id Evergreen.V74.Id.UserId))
    | CheckLoginRequest
    | LoginWithTokenRequest (Evergreen.V74.Id.Id Evergreen.V74.Id.LoginToken) (Maybe ( Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId, Evergreen.V74.Group.EventId ))
    | GetLoginTokenRequest Evergreen.V74.Route.Route (Evergreen.V74.Untrusted.Untrusted Evergreen.V74.EmailAddress.EmailAddress) (Maybe ( Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId, Evergreen.V74.Group.EventId ))
    | GetAdminDataRequest
    | LogoutRequest
    | CreateGroupRequest (Evergreen.V74.Untrusted.Untrusted Evergreen.V74.GroupName.GroupName) (Evergreen.V74.Untrusted.Untrusted Evergreen.V74.Description.Description) Evergreen.V74.Group.GroupVisibility
    | DeleteUserRequest (Evergreen.V74.Id.Id Evergreen.V74.Id.DeleteUserToken)
    | GetMyGroupsRequest
    | SearchGroupsRequest String
    | GroupRequest (Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId) Evergreen.V74.GroupPage.ToBackend
    | ProfileFormRequest Evergreen.V74.ProfilePage.ToBackend


type Log
    = LogUntrustedCheckFailed Time.Posix ToBackend Evergreen.V74.Id.SessionIdFirst4Chars
    | LogLoginEmail Time.Posix (Result Effect.Http.Error Evergreen.V74.Postmark.PostmarkSendResponse) Evergreen.V74.EmailAddress.EmailAddress
    | LogDeleteAccountEmail Time.Posix (Result Effect.Http.Error Evergreen.V74.Postmark.PostmarkSendResponse) (Evergreen.V74.Id.Id Evergreen.V74.Id.UserId)
    | LogEventReminderEmail Time.Posix (Result Effect.Http.Error Evergreen.V74.Postmark.PostmarkSendResponse) (Evergreen.V74.Id.Id Evergreen.V74.Id.UserId) (Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId) Evergreen.V74.Group.EventId
    | LogNewEventNotificationEmail Time.Posix (Result Effect.Http.Error Evergreen.V74.Postmark.PostmarkSendResponse) (Evergreen.V74.Id.Id Evergreen.V74.Id.UserId) (Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId)
    | LogLoginTokenEmailRequestRateLimited Time.Posix Evergreen.V74.EmailAddress.EmailAddress Evergreen.V74.Id.SessionIdFirst4Chars
    | LogDeleteAccountEmailRequestRateLimited Time.Posix (Evergreen.V74.Id.Id Evergreen.V74.Id.UserId) Evergreen.V74.Id.SessionIdFirst4Chars


type alias AdminModel =
    { cachedEmailAddress : SeqDict.SeqDict (Evergreen.V74.Id.Id Evergreen.V74.Id.UserId) Evergreen.V74.EmailAddress.EmailAddress
    , logs : Array.Array Log
    , lastLogCheck : Time.Posix
    }


type AdminCache
    = AdminCacheNotRequested
    | AdminCached AdminModel
    | AdminCachePending


type alias LoggedIn_ =
    { userId : Evergreen.V74.Id.Id Evergreen.V74.Id.UserId
    , emailAddress : Evergreen.V74.EmailAddress.EmailAddress
    , profileForm : Evergreen.V74.ProfilePage.Model
    , myGroups : Maybe (SeqSet.SeqSet (Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId))
    , subscribedGroups : SeqSet.SeqSet (Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId)
    , adminState : AdminCache
    , adminStatus : Evergreen.V74.AdminStatus.AdminStatus
    }


type LoginStatus
    = LoginStatusPending
    | LoggedIn LoggedIn_
    | NotLoggedIn
        { showLogin : Bool
        , joiningEvent : Maybe ( Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId, Evergreen.V74.Group.EventId )
        }


type alias LoginForm =
    { email : String
    , pressedSubmitEmail : Bool
    , emailSent : Maybe Evergreen.V74.EmailAddress.EmailAddress
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
    , route : Evergreen.V74.Route.Route
    , cachedGroups : SeqDict.SeqDict (Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId) (Evergreen.V74.Cache.Cache Evergreen.V74.Group.Group)
    , cachedUsers : SeqDict.SeqDict (Evergreen.V74.Id.Id Evergreen.V74.Id.UserId) (Evergreen.V74.Cache.Cache Evergreen.V74.FrontendUser.FrontendUser)
    , time : Time.Posix
    , timezone : Result () Time.Zone
    , lastConnectionCheck : Time.Posix
    , loginForm : LoginForm
    , logs : Maybe (Array.Array Log)
    , hasLoginTokenError : Bool
    , groupForm : Evergreen.V74.CreateGroupPage.Model
    , groupCreated : Bool
    , accountDeletedResult : Maybe (Result () ())
    , searchText : String
    , searchList : List (Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId)
    , windowWidth : Quantity.Quantity Int Pixels.Pixels
    , windowHeight : Quantity.Quantity Int Pixels.Pixels
    , groupPage : SeqDict.SeqDict (Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId) Evergreen.V74.GroupPage.Model
    , loadedUserConfig : LoadedUserConfig
    , miniLanguageSelectorOpened : Bool
    }


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias BackendUser =
    { name : Evergreen.V74.Name.Name
    , description : Evergreen.V74.Description.Description
    , emailAddress : Evergreen.V74.EmailAddress.EmailAddress
    , profileImage : Evergreen.V74.ProfileImage.ProfileImage
    , timezone : Time.Zone
    , allowEventReminders : Bool
    , subscribedGroups : SeqSet.SeqSet (Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId)
    }


type alias LoginTokenData =
    { creationTime : Time.Posix
    , emailAddress : Evergreen.V74.EmailAddress.EmailAddress
    }


type alias DeleteUserTokenData =
    { creationTime : Time.Posix
    , userId : Evergreen.V74.Id.Id Evergreen.V74.Id.UserId
    }


type alias BackendModel =
    { users : SeqDict.SeqDict (Evergreen.V74.Id.Id Evergreen.V74.Id.UserId) BackendUser
    , groups : SeqDict.SeqDict (Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId) Evergreen.V74.Group.Group
    , deletedGroups : SeqDict.SeqDict (Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId) Evergreen.V74.Group.Group
    , sessions : Evergreen.V74.BiDict.Assoc2.BiDict Effect.Lamdera.SessionId (Evergreen.V74.Id.Id Evergreen.V74.Id.UserId)
    , loginAttempts : SeqDict.SeqDict Effect.Lamdera.SessionId (List.Nonempty.Nonempty Time.Posix)
    , connections : SeqDict.SeqDict Effect.Lamdera.SessionId (List.Nonempty.Nonempty Effect.Lamdera.ClientId)
    , logs : Array.Array Log
    , time : Time.Posix
    , secretCounter : Int
    , pendingLoginTokens : SeqDict.SeqDict (Evergreen.V74.Id.Id Evergreen.V74.Id.LoginToken) LoginTokenData
    , pendingDeleteUserTokens : SeqDict.SeqDict (Evergreen.V74.Id.Id Evergreen.V74.Id.DeleteUserToken) DeleteUserTokenData
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
    | CreateGroupPageMsg Evergreen.V74.CreateGroupPage.Msg
    | ProfileFormMsg Evergreen.V74.ProfilePage.Msg
    | TypedSearchText String
    | SubmittedSearchBox
    | GroupPageMsg Evergreen.V74.GroupPage.Msg
    | GotWindowSize Int Int
    | GotTimeZone (Result Evergreen.V74.TimeZone.Error ( String, Time.Zone ))
    | ScrolledToTop
    | PressedEnableAdmin
    | PressedDisableAdmin
    | PressedThemeToggle
    | LanguageSelected Language
    | GotPrefersDarkTheme Bool
    | GotLanguage String
    | ToggleLanguageSelect


type BackendMsg
    = SentLoginEmail Evergreen.V74.EmailAddress.EmailAddress (Result Effect.Http.Error Evergreen.V74.Postmark.PostmarkSendResponse)
    | SentDeleteUserEmail (Evergreen.V74.Id.Id Evergreen.V74.Id.UserId) (Result Effect.Http.Error Evergreen.V74.Postmark.PostmarkSendResponse)
    | SentEventReminderEmail (Evergreen.V74.Id.Id Evergreen.V74.Id.UserId) (Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId) Evergreen.V74.Group.EventId (Result Effect.Http.Error Evergreen.V74.Postmark.PostmarkSendResponse)
    | SentNewEventNotificationEmail (Evergreen.V74.Id.Id Evergreen.V74.Id.UserId) (Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId) (Result Effect.Http.Error Evergreen.V74.Postmark.PostmarkSendResponse)
    | BackendGotTime Time.Posix
    | Connected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | Disconnected Effect.Lamdera.SessionId Effect.Lamdera.ClientId
    | NoOpBackendMsg


type GroupRequest
    = GroupNotFound_
    | GroupFound_ Evergreen.V74.Group.Group (SeqDict.SeqDict (Evergreen.V74.Id.Id Evergreen.V74.Id.UserId) Evergreen.V74.FrontendUser.FrontendUser)


type ToFrontend
    = GetGroupResponse (Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId) GroupRequest
    | GetUserResponse (SeqDict.SeqDict (Evergreen.V74.Id.Id Evergreen.V74.Id.UserId) (Result () Evergreen.V74.FrontendUser.FrontendUser))
    | CheckLoginResponse
        (Maybe
            { userId : Evergreen.V74.Id.Id Evergreen.V74.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | LoginWithTokenResponse
        (Result
            ()
            { userId : Evergreen.V74.Id.Id Evergreen.V74.Id.UserId
            , user : BackendUser
            , isAdmin : Bool
            }
        )
    | GetAdminDataResponse AdminModel
    | CreateGroupResponse (Result Evergreen.V74.CreateGroupPage.CreateGroupError ( Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId, Evergreen.V74.Group.Group ))
    | LogoutResponse
    | ChangeNameResponse Evergreen.V74.Name.Name
    | ChangeDescriptionResponse Evergreen.V74.Description.Description
    | ChangeEmailAddressResponse Evergreen.V74.EmailAddress.EmailAddress
    | DeleteUserResponse (Result () ())
    | ChangeProfileImageResponse Evergreen.V74.ProfileImage.ProfileImage
    | GetMyGroupsResponse
        { myGroups : List ( Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId, Evergreen.V74.Group.Group )
        , subscribedGroups : List ( Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId, Evergreen.V74.Group.Group )
        }
    | SearchGroupsResponse String (List ( Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId, Evergreen.V74.Group.Group ))
    | ChangeGroupNameResponse (Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId) Evergreen.V74.GroupName.GroupName
    | ChangeGroupDescriptionResponse (Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId) Evergreen.V74.Description.Description
    | ChangeGroupVisibilityResponse (Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId) Evergreen.V74.Group.GroupVisibility
    | CreateEventResponse (Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId) (Result Evergreen.V74.GroupPage.CreateEventError Evergreen.V74.Event.Event)
    | EditEventResponse (Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId) Evergreen.V74.Group.EventId (Result Evergreen.V74.Group.EditEventError Evergreen.V74.Event.Event) Time.Posix
    | JoinEventResponse (Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId) Evergreen.V74.Group.EventId (Result Evergreen.V74.Group.JoinEventError ())
    | LeaveEventResponse (Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId) Evergreen.V74.Group.EventId (Result () ())
    | ChangeEventCancellationStatusResponse (Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId) Evergreen.V74.Group.EventId (Result Evergreen.V74.Group.EditCancellationStatusError Evergreen.V74.Event.CancellationStatus) Time.Posix
    | DeleteGroupAdminResponse (Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId)
    | SubscribeResponse (Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId)
    | UnsubscribeResponse (Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId)
    | DeleteGroupUserResponse (Evergreen.V74.Id.Id Evergreen.V74.Id.GroupId)
