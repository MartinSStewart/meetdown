module Types exposing (..)

import AdminStatus exposing (AdminStatus)
import Array exposing (Array)
import AssocList as Dict exposing (Dict)
import AssocSet exposing (Set)
import BiDict.Assoc exposing (BiDict)
import Browser exposing (UrlRequest)
import Cache exposing (Cache)
import CreateGroupPage exposing (CreateGroupError)
import Description exposing (Description)
import Effect.Browser.Navigation exposing (Key)
import Effect.Http as Http
import Effect.Lamdera exposing (ClientId, SessionId)
import EmailAddress exposing (EmailAddress)
import Event exposing (CancellationStatus, Event)
import FrontendUser exposing (FrontendUser)
import Group exposing (EventId, Group, GroupVisibility, JoinEventError)
import GroupName exposing (GroupName)
import GroupPage exposing (CreateEventError)
import HttpHelpers
import Id exposing (DeleteUserToken, GroupId, Id, LoginToken, SessionIdFirst4Chars, UserId)
import List.Nonempty exposing (Nonempty)
import Name exposing (Name)
import Pixels exposing (Pixels)
import Postmark
import ProfileImage exposing (ProfileImage)
import ProfilePage
import Quantity exposing (Quantity)
import Route exposing (Route)
import Time
import TimeZone
import Untrusted exposing (Untrusted)
import Url exposing (Url)


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias LoadingFrontend =
    { navigationKey : Key
    , route : Route
    , routeToken : Route.Token
    , windowSize : Maybe ( Quantity Int Pixels, Quantity Int Pixels )
    , time : Maybe Time.Posix
    , timezone : Maybe Time.Zone
    }


type alias LoadedFrontend =
    { navigationKey : Key
    , loginStatus : LoginStatus
    , route : Route
    , cachedGroups : Dict (Id GroupId) (Cache Group)
    , cachedUsers : Dict (Id UserId) (Cache FrontendUser)
    , time : Time.Posix
    , timezone : Time.Zone
    , lastConnectionCheck : Time.Posix
    , loginForm : LoginForm
    , logs : Maybe (Array Log)
    , hasLoginTokenError : Bool
    , groupForm : CreateGroupPage.Model
    , groupCreated : Bool
    , accountDeletedResult : Maybe (Result () ())
    , searchText : String
    , searchList : List (Id GroupId)
    , windowWidth : Quantity Int Pixels
    , windowHeight : Quantity Int Pixels
    , groupPage : Dict (Id GroupId) GroupPage.Model
    , loadedUserConfig : LoadedUserConfig
    , miniLanguageSelectorOpened : Bool
    }


type alias LoadedUserConfig =
    { theme : ColorTheme
    , language : Language
    }


type ColorTheme
    = LightTheme
    | DarkTheme


type Language
    = English
    | French
    | Spanish


type GroupRequest
    = GroupNotFound_
    | GroupFound_ Group (Dict (Id UserId) FrontendUser)


type AdminCache
    = AdminCacheNotRequested
    | AdminCached AdminModel
    | AdminCachePending


type alias LoginForm =
    { email : String
    , pressedSubmitEmail : Bool
    , emailSent : Maybe EmailAddress
    }


type LoginStatus
    = LoginStatusPending
    | LoggedIn LoggedIn_
    | NotLoggedIn { showLogin : Bool, joiningEvent : Maybe ( Id GroupId, EventId ) }


type alias LoggedIn_ =
    { userId : Id UserId
    , emailAddress : EmailAddress
    , profileForm : ProfilePage.Model
    , myGroups : Maybe (Set (Id GroupId))
    , subscribedGroups : Set (Id GroupId)
    , adminState : AdminCache
    , adminStatus : AdminStatus
    }


type alias AdminModel =
    { cachedEmailAddress : Dict (Id UserId) EmailAddress
    , logs : Array Log
    , lastLogCheck : Time.Posix
    }


type alias BackendModel =
    { users : Dict (Id UserId) BackendUser
    , groups : Dict (Id GroupId) Group
    , deletedGroups : Dict (Id GroupId) Group
    , sessions : BiDict SessionId (Id UserId)
    , loginAttempts : Dict SessionId (Nonempty Time.Posix)
    , connections : Dict SessionId (Nonempty ClientId)
    , logs : Array Log
    , time : Time.Posix
    , secretCounter : Int
    , pendingLoginTokens : Dict (Id LoginToken) LoginTokenData
    , pendingDeleteUserTokens : Dict (Id DeleteUserToken) DeleteUserTokenData
    }


type alias LoginTokenData =
    { creationTime : Time.Posix, emailAddress : EmailAddress }


type alias DeleteUserTokenData =
    { creationTime : Time.Posix, userId : Id UserId }


type Log
    = LogUntrustedCheckFailed Time.Posix ToBackend SessionIdFirst4Chars
    | LogLoginEmail Time.Posix (Result Http.Error Postmark.PostmarkSendResponse) EmailAddress
    | LogDeleteAccountEmail Time.Posix (Result Http.Error Postmark.PostmarkSendResponse) (Id UserId)
    | LogEventReminderEmail Time.Posix (Result Http.Error Postmark.PostmarkSendResponse) (Id UserId) (Id GroupId) EventId
    | LogNewEventNotificationEmail Time.Posix (Result Http.Error Postmark.PostmarkSendResponse) (Id UserId) (Id GroupId)
    | LogLoginTokenEmailRequestRateLimited Time.Posix EmailAddress SessionIdFirst4Chars
    | LogDeleteAccountEmailRequestRateLimited Time.Posix (Id UserId) SessionIdFirst4Chars


logData : AdminModel -> Log -> { time : Time.Posix, isError : Bool, message : String }
logData model log =
    let
        getEmailAddress userId =
            case Dict.get userId model.cachedEmailAddress of
                Just address ->
                    EmailAddress.toString address

                Nothing ->
                    "<not found>"

        emailErrorToString email error =
            "Tried sending a login email to "
                ++ email
                ++ " but got this error "
                ++ HttpHelpers.httpErrorToString error
    in
    case log of
        LogUntrustedCheckFailed time _ _ ->
            { time = time, isError = True, message = "Trust check failed: TODO" }

        LogLoginEmail time result emailAddress ->
            { time = time
            , isError =
                case result of
                    Ok _ ->
                        False

                    Err _ ->
                        True
            , message =
                case result of
                    Ok _ ->
                        "Sent an email to " ++ EmailAddress.toString emailAddress

                    Err error ->
                        emailErrorToString (EmailAddress.toString emailAddress) error
            }

        LogDeleteAccountEmail time result userId ->
            { time = time
            , isError =
                case result of
                    Ok _ ->
                        False

                    Err _ ->
                        True
            , message =
                case result of
                    Ok _ ->
                        "Sent an email to " ++ getEmailAddress userId ++ " for deleting their account"

                    Err error ->
                        emailErrorToString (getEmailAddress userId) error
            }

        LogEventReminderEmail time result userId _ _ ->
            { time = time
            , isError =
                case result of
                    Ok _ ->
                        False

                    Err _ ->
                        True
            , message =
                case result of
                    Ok _ ->
                        "Sent an email to " ++ getEmailAddress userId ++ " to notify of an upcoming event"

                    Err error ->
                        emailErrorToString (getEmailAddress userId) error
            }

        LogNewEventNotificationEmail time result userId _ ->
            { time = time
            , isError =
                case result of
                    Ok _ ->
                        False

                    Err _ ->
                        True
            , message =
                case result of
                    Ok _ ->
                        "Sent an email to " ++ getEmailAddress userId ++ " to notify of a new event"

                    Err error ->
                        emailErrorToString (getEmailAddress userId) error
            }

        LogLoginTokenEmailRequestRateLimited time emailAddress sessionId ->
            { time = time
            , isError = False
            , message =
                "Login request to "
                    ++ EmailAddress.toString emailAddress
                    ++ " was not sent due to rate limiting. First 4 chars of sessionId: "
                    ++ Id.sessionIdFirst4CharsToString sessionId
            }

        LogDeleteAccountEmailRequestRateLimited time userId sessionId ->
            { time = time
            , isError = False
            , message =
                "Login request to "
                    ++ getEmailAddress userId
                    ++ " was not sent due to rate limiting. First 4 chars of sessionId: "
                    ++ Id.sessionIdFirst4CharsToString sessionId
            }


type alias BackendUser =
    { name : Name
    , description : Description
    , emailAddress : EmailAddress
    , profileImage : ProfileImage
    , timezone : Time.Zone
    , allowEventReminders : Bool
    , subscribedGroups : Set (Id GroupId)
    }


userToFrontend : BackendUser -> FrontendUser
userToFrontend backendUser =
    { name = backendUser.name
    , description = backendUser.description
    , profileImage = backendUser.profileImage
    }


type FrontendMsg
    = NoOpFrontendMsg
    | UrlClicked UrlRequest
    | UrlChanged Url
    | GotTime Time.Posix
    | PressedLogin
    | PressedLogout
    | TypedEmail String
    | PressedSubmitLogin
    | PressedCancelLogin
    | CreateGroupPageMsg CreateGroupPage.Msg
    | ProfileFormMsg ProfilePage.Msg
    | TypedSearchText String
    | SubmittedSearchBox
    | GroupPageMsg GroupPage.Msg
    | GotWindowSize Int Int
    | GotTimeZone (Result TimeZone.Error ( String, Time.Zone ))
    | ScrolledToTop
    | PressedEnableAdmin
    | PressedDisableAdmin
    | PressedThemeToggle
    | LanguageSelected Language
    | GotPrefersDarkTheme Bool
    | GotLanguage String
    | ToggleLanguageSelect


type ToBackend
    = GetGroupRequest (Id GroupId)
    | GetUserRequest (Nonempty (Id UserId))
    | CheckLoginRequest
    | LoginWithTokenRequest (Id LoginToken) (Maybe ( Id GroupId, EventId ))
    | GetLoginTokenRequest Route (Untrusted EmailAddress) (Maybe ( Id GroupId, EventId ))
    | GetAdminDataRequest
    | LogoutRequest
    | CreateGroupRequest (Untrusted GroupName) (Untrusted Description) GroupVisibility
    | DeleteUserRequest (Id DeleteUserToken)
    | GetMyGroupsRequest
    | SearchGroupsRequest String
    | GroupRequest (Id GroupId) GroupPage.ToBackend
    | ProfileFormRequest ProfilePage.ToBackend


type BackendMsg
    = SentLoginEmail EmailAddress (Result Http.Error Postmark.PostmarkSendResponse)
    | SentDeleteUserEmail (Id UserId) (Result Http.Error Postmark.PostmarkSendResponse)
    | SentEventReminderEmail (Id UserId) (Id GroupId) EventId (Result Http.Error Postmark.PostmarkSendResponse)
    | SentNewEventNotificationEmail (Id UserId) (Id GroupId) (Result Http.Error Postmark.PostmarkSendResponse)
    | BackendGotTime Time.Posix
    | Connected SessionId ClientId
    | Disconnected SessionId ClientId


type ToFrontend
    = GetGroupResponse (Id GroupId) GroupRequest
    | GetUserResponse (Dict (Id UserId) (Result () FrontendUser))
    | CheckLoginResponse (Maybe { userId : Id UserId, user : BackendUser, isAdmin : Bool })
    | LoginWithTokenResponse (Result () { userId : Id UserId, user : BackendUser, isAdmin : Bool })
    | GetAdminDataResponse AdminModel
    | CreateGroupResponse (Result CreateGroupError ( Id GroupId, Group ))
    | LogoutResponse
    | ChangeNameResponse Name
    | ChangeDescriptionResponse Description
    | ChangeEmailAddressResponse EmailAddress
    | DeleteUserResponse (Result () ())
    | ChangeProfileImageResponse ProfileImage
    | GetMyGroupsResponse { myGroups : List ( Id GroupId, Group ), subscribedGroups : List ( Id GroupId, Group ) }
    | SearchGroupsResponse String (List ( Id GroupId, Group ))
    | ChangeGroupNameResponse (Id GroupId) GroupName
    | ChangeGroupDescriptionResponse (Id GroupId) Description
    | ChangeGroupVisibilityResponse (Id GroupId) GroupVisibility
    | CreateEventResponse (Id GroupId) (Result CreateEventError Event)
    | EditEventResponse (Id GroupId) EventId (Result Group.EditEventError Event) Time.Posix
    | JoinEventResponse (Id GroupId) EventId (Result JoinEventError ())
    | LeaveEventResponse (Id GroupId) EventId (Result () ())
    | ChangeEventCancellationStatusResponse (Id GroupId) EventId (Result Group.EditCancellationStatusError CancellationStatus) Time.Posix
    | DeleteGroupAdminResponse (Id GroupId)
    | SubscribeResponse (Id GroupId)
    | UnsubscribeResponse (Id GroupId)
