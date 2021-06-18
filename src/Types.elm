module Types exposing (..)

import Array exposing (Array)
import AssocList as Dict exposing (Dict)
import AssocSet exposing (Set)
import BiDict.Assoc exposing (BiDict)
import Browser exposing (UrlRequest)
import Browser.Navigation
import CreateGroupForm exposing (CreateGroupError, GroupFormValidated)
import Description exposing (Description)
import EmailAddress exposing (EmailAddress)
import Event exposing (CancellationStatus, Event, EventType)
import EventDuration exposing (EventDuration)
import EventName exposing (EventName)
import FrontendUser exposing (FrontendUser)
import Group exposing (EventId, Group, GroupVisibility, JoinEventError)
import GroupName exposing (GroupName)
import GroupPage exposing (CreateEventError)
import Id exposing (ClientId, DeleteUserToken, GroupId, Id, LoginToken, SessionId, UserId)
import List.Nonempty exposing (Nonempty)
import MaxAttendees exposing (MaxAttendees)
import Name exposing (Name)
import Pixels exposing (Pixels)
import ProfileForm
import ProfileImage exposing (ProfileImage)
import Quantity exposing (Quantity)
import Route exposing (Route)
import SendGrid exposing (Email)
import Time
import TimeZone
import Untrusted exposing (Untrusted)
import Url exposing (Url)


type NavigationKey
    = RealNavigationKey Browser.Navigation.Key
    | MockNavigationKey


type FrontendModel
    = Loading LoadingFrontend
    | Loaded LoadedFrontend


type alias LoadingFrontend =
    { navigationKey : NavigationKey
    , route : Route
    , routeToken : Route.Token
    , windowSize : Maybe ( Quantity Int Pixels, Quantity Int Pixels )
    , time : Maybe Time.Posix
    , timezone : Maybe Time.Zone
    }


type alias LoadedFrontend =
    { navigationKey : NavigationKey
    , loginStatus : LoginStatus
    , route : Route
    , cachedGroups : Dict GroupId GroupCache
    , cachedUsers : Dict (Id UserId) UserCache
    , time : Time.Posix
    , timezone : Time.Zone
    , lastConnectionCheck : Time.Posix
    , loginForm : LoginForm
    , logs : Maybe (Array Log)
    , hasLoginTokenError : Bool
    , groupForm : CreateGroupForm.Model
    , groupCreated : Bool
    , accountDeletedResult : Maybe (Result () ())
    , searchBox : String
    , searchList : List GroupId
    , windowWidth : Quantity Int Pixels
    , windowHeight : Quantity Int Pixels
    , groupPage : Dict GroupId GroupPage.Model
    }


type GroupRequest
    = GroupNotFound_
    | GroupFound_ Group (Dict (Id UserId) FrontendUser)


type GroupCache
    = GroupNotFound
    | GroupFound Group
    | GroupRequestPending


type UserCache
    = UserNotFound
    | UserFound FrontendUser
    | UserRequestPending


mapUserCache : (FrontendUser -> FrontendUser) -> UserCache -> UserCache
mapUserCache mapFunc userCache =
    case userCache of
        UserNotFound ->
            UserNotFound

        UserFound frontendUser ->
            mapFunc frontendUser |> UserFound

        UserRequestPending ->
            UserRequestPending


type alias LoginForm =
    { email : String
    , pressedSubmitEmail : Bool
    , emailSent : Maybe EmailAddress
    }


type LoginStatus
    = LoginStatusPending
    | LoggedIn LoggedIn_
    | NotLoggedIn { showLogin : Bool, joiningEvent : Maybe ( GroupId, EventId ) }


type alias LoggedIn_ =
    { userId : Id UserId
    , emailAddress : EmailAddress
    , profileForm : ProfileForm.Model
    , myGroups : Maybe (Set GroupId)
    , adminState : Maybe AdminModel
    }


type alias AdminModel =
    { cachedEmailAddress : Dict (Id UserId) EmailAddress
    , logs : Array Log
    }


type alias BackendModel =
    { users : Dict (Id UserId) BackendUser
    , groups : Dict GroupId Group
    , groupIdCounter : Int
    , sessions : BiDict SessionId (Id UserId)
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
    = LogUntrustedCheckFailed Time.Posix ToBackend
    | LogLoginEmail Time.Posix (Result SendGrid.Error ()) EmailAddress
    | LogDeleteAccountEmail Time.Posix (Result SendGrid.Error ()) (Id UserId)
    | LogEventReminderEmail Time.Posix (Result SendGrid.Error ()) (Id UserId) GroupId EventId


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
                ++ (case error of
                        SendGrid.StatusCode400 errors ->
                            List.map (\a -> a.message) errors
                                |> String.join ", "
                                |> (++) "StatusCode400: "

                        SendGrid.StatusCode401 errors ->
                            List.map (\a -> a.message) errors
                                |> String.join ", "
                                |> (++) "StatusCode401: "

                        SendGrid.StatusCode403 { errors } ->
                            List.filterMap (\a -> a.message) errors
                                |> String.join ", "
                                |> (++) "StatusCode403: "

                        SendGrid.StatusCode413 errors ->
                            List.map (\a -> a.message) errors
                                |> String.join ", "
                                |> (++) "StatusCode413: "

                        SendGrid.UnknownError { statusCode, body } ->
                            "UnknownError: " ++ String.fromInt statusCode ++ " " ++ body

                        SendGrid.NetworkError ->
                            "NetworkError"

                        SendGrid.Timeout ->
                            "Timeout"

                        SendGrid.BadUrl url ->
                            "BadUrl: " ++ url
                   )
    in
    case log of
        LogUntrustedCheckFailed time _ ->
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
                    Ok () ->
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
                    Ok () ->
                        "Sent an email to " ++ getEmailAddress userId ++ " for deleting their account"

                    Err error ->
                        emailErrorToString (getEmailAddress userId) error
            }

        LogEventReminderEmail time result userId groupId eventId ->
            { time = time
            , isError =
                case result of
                    Ok _ ->
                        False

                    Err _ ->
                        True
            , message =
                case result of
                    Ok () ->
                        "Sent an email to " ++ getEmailAddress userId ++ " to notify of an upcoming event"

                    Err error ->
                        emailErrorToString (getEmailAddress userId) error
            }


type alias BackendUser =
    { name : Name
    , description : Description
    , emailAddress : EmailAddress
    , profileImage : ProfileImage
    , timezone : Time.Zone
    , allowEventReminders : Bool
    }


userToFrontend : BackendUser -> FrontendUser
userToFrontend backendUser =
    { name = backendUser.name
    , description = backendUser.description
    , profileImage = backendUser.profileImage
    }


type FrontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | GotTime Time.Posix
    | PressedLogin
    | PressedLogout
    | TypedEmail String
    | PressedSubmitLogin
    | PressedCancelLogin
    | PressedCreateGroup
    | GroupFormMsg CreateGroupForm.Msg
    | ProfileFormMsg ProfileForm.Msg
    | CroppedImage { requestId : Int, croppedImageUrl : String }
    | TypedSearchText String
    | SubmittedSearchBox
    | GroupPageMsg GroupPage.Msg
    | GotWindowSize (Quantity Int Pixels) (Quantity Int Pixels)
    | GotTimeZone (Result TimeZone.Error ( String, Time.Zone ))


type ToBackend
    = GetGroupRequest GroupId
    | GetUserRequest (Id UserId)
    | CheckLoginRequest
    | LoginWithTokenRequest (Id LoginToken) (Maybe ( GroupId, EventId ))
    | GetLoginTokenRequest Route (Untrusted EmailAddress) (Maybe ( GroupId, EventId ))
    | GetAdminDataRequest
    | LogoutRequest
    | CreateGroupRequest (Untrusted GroupName) (Untrusted Description) GroupVisibility
    | ChangeNameRequest (Untrusted Name)
    | ChangeDescriptionRequest (Untrusted Description)
    | ChangeEmailAddressRequest (Untrusted EmailAddress)
    | SendDeleteUserEmailRequest
    | DeleteUserRequest (Id DeleteUserToken)
    | ChangeProfileImageRequest (Untrusted ProfileImage)
    | GetMyGroupsRequest
    | SearchGroupsRequest String
    | ChangeGroupNameRequest GroupId (Untrusted GroupName)
    | ChangeGroupDescriptionRequest GroupId (Untrusted Description)
    | CreateEventRequest GroupId (Untrusted EventName) (Untrusted Description) (Untrusted EventType) Time.Posix (Untrusted EventDuration) (Untrusted MaxAttendees)
    | EditEventRequest GroupId EventId (Untrusted EventName) (Untrusted Description) (Untrusted EventType) Time.Posix (Untrusted EventDuration) (Untrusted MaxAttendees)
    | JoinEventRequest GroupId EventId
    | LeaveEventRequest GroupId EventId
    | ChangeEventCancellationStatusRequest GroupId EventId CancellationStatus


type BackendMsg
    = SentLoginEmail EmailAddress (Result SendGrid.Error ())
    | SentDeleteUserEmail (Id UserId) (Result SendGrid.Error ())
    | SentEventReminderEmail (Id UserId) GroupId EventId (Result SendGrid.Error ())
    | BackendGotTime Time.Posix
    | Connected SessionId ClientId
    | Disconnected SessionId ClientId


type ToFrontend
    = GetGroupResponse GroupId GroupRequest
    | GetUserResponse (Id UserId) (Result () FrontendUser)
    | CheckLoginResponse (Maybe ( Id UserId, BackendUser ))
    | LoginWithTokenResponse (Result () ( Id UserId, BackendUser ))
    | GetAdminDataResponse (Array Log)
    | CreateGroupResponse (Result CreateGroupError ( GroupId, Group ))
    | LogoutResponse
    | ChangeNameResponse Name
    | ChangeDescriptionResponse Description
    | ChangeEmailAddressResponse EmailAddress
    | DeleteUserResponse (Result () ())
    | ChangeProfileImageResponse ProfileImage
    | GetMyGroupsResponse (List ( GroupId, Group ))
    | SearchGroupsResponse String (List ( GroupId, Group ))
    | ChangeGroupNameResponse GroupId GroupName
    | ChangeGroupDescriptionResponse GroupId Description
    | CreateEventResponse GroupId (Result CreateEventError Event)
    | EditEventResponse GroupId EventId (Result Group.EditEventError Event) Time.Posix
    | JoinEventResponse GroupId EventId (Result JoinEventError ())
    | LeaveEventResponse GroupId EventId (Result () ())
    | ChangeEventCancellationStatusResponse GroupId EventId (Result Group.EditCancellationStatusError CancellationStatus) Time.Posix
