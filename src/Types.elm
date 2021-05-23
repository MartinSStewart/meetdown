module Types exposing (..)

import Array exposing (Array)
import AssocList exposing (Dict)
import AssocSet exposing (Set)
import BiDict.Assoc exposing (BiDict)
import Browser exposing (UrlRequest)
import Browser.Navigation
import Description exposing (Description)
import EmailAddress exposing (EmailAddress)
import FrontendUser exposing (FrontendUser)
import Group exposing (Group, GroupVisibility)
import GroupForm exposing (CreateGroupError, GroupFormValidated)
import GroupName exposing (GroupName)
import Id exposing (ClientId, DeleteUserToken, GroupId, Id, LoginToken, SessionId, UserId)
import List.Nonempty exposing (Nonempty)
import Name exposing (Name)
import ProfileForm
import ProfileImage exposing (ProfileImage)
import Route exposing (Route)
import SendGrid exposing (Email)
import Time
import Untrusted exposing (Untrusted)
import Url exposing (Url)


type NavigationKey
    = RealNavigationKey Browser.Navigation.Key
    | MockNavigationKey


type FrontendModel
    = Loading NavigationKey ( Route, Route.Token )
    | Loaded LoadedFrontend


type alias LoadedFrontend =
    { navigationKey : NavigationKey
    , loginStatus : LoginStatus
    , route : Route
    , cachedGroups : Dict GroupId GroupRequest
    , cachedUsers : Dict (Id UserId) FrontendUser
    , time : Time.Posix
    , lastConnectionCheck : Time.Posix
    , loginForm : LoginForm
    , logs : Maybe (Array Log)
    , hasLoginError : Bool
    , groupForm : GroupForm.Model
    , groupCreated : Bool
    , accountDeletedResult : Maybe (Result () ())
    , searchBox : String
    , searchList : List GroupId
    }


type GroupRequest
    = GroupNotFoundOrIsPrivate
    | GroupFound Group


type alias LoginForm =
    { email : String
    , pressedSubmitEmail : Bool
    , emailSent : Maybe EmailAddress
    }


type LoginStatus
    = LoginStatusPending
    | LoggedIn LoggedIn_
    | NotLoggedIn { showLogin : Bool }


type alias LoggedIn_ =
    { userId : Id UserId
    , user : BackendUser
    , profileForm : ProfileForm.Model
    , myGroups : Maybe (Set GroupId)
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
    = UntrustedCheckFailed Time.Posix ToBackendRequest
    | SendGridSendEmail Time.Posix (Result SendGrid.Error ()) EmailAddress


logTime : Log -> Time.Posix
logTime log =
    case log of
        UntrustedCheckFailed time _ ->
            time

        SendGridSendEmail time _ _ ->
            time


logIsError : Log -> Bool
logIsError log =
    case log of
        UntrustedCheckFailed _ _ ->
            True

        SendGridSendEmail _ result _ ->
            case result of
                Ok _ ->
                    False

                Err _ ->
                    True


logToString : Log -> String
logToString log =
    case log of
        SendGridSendEmail _ result email ->
            case result of
                Ok () ->
                    "Sent an email to " ++ EmailAddress.toString email

                Err error ->
                    "Tried sending a login email to "
                        ++ EmailAddress.toString email
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

        UntrustedCheckFailed _ toBackend ->
            "Trust check failed: TODO"


type alias BackendUser =
    { name : Name
    , description : Description
    , emailAddress : EmailAddress
    , profileImage : ProfileImage
    }


userToFrontend : BackendUser -> FrontendUser
userToFrontend backendUser =
    { name = backendUser.name
    , profileImage = backendUser.profileImage
    }


type FrontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | GotTime Time.Posix
    | PressedLogin
    | PressedLogout
    | TypedEmail String
    | PressedSubmitEmail
    | PressedCreateGroup
    | GroupFormMsg GroupForm.Msg
    | ProfileFormMsg ProfileForm.Msg
    | CroppedImage { requestId : Int, croppedImageUrl : String }
    | TypedSearchText String
    | SubmittedSearchBox


type ToBackend
    = ToBackend (Nonempty ToBackendRequest)


type ToBackendRequest
    = GetGroupRequest GroupId
    | CheckLoginRequest
    | LoginWithTokenRequest (Id LoginToken)
    | GetLoginTokenRequest Route (Untrusted EmailAddress)
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


type BackendMsg
    = SentLoginEmail EmailAddress (Result SendGrid.Error ())
    | SentDeleteUserEmail EmailAddress (Result SendGrid.Error ())
    | BackendGotTime Time.Posix
    | Connected SessionId ClientId
    | Disconnected SessionId ClientId


type ToFrontend
    = GetGroupResponse GroupId GroupRequest
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
