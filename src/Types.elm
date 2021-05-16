module Types exposing (..)

import Array exposing (Array)
import AssocList exposing (Dict)
import AssocSet exposing (Set)
import Avataaars exposing (Avataaar)
import Browser exposing (UrlRequest)
import Browser.Navigation
import EmailAddress exposing (EmailAddress)
import Id exposing (ClientId, CryptoHash, GroupId, LoginToken, SessionId, UserId)
import List.Nonempty exposing (Nonempty)
import Route exposing (Route)
import SendGrid
import String.Nonempty exposing (NonemptyString)
import Time
import Untrusted exposing (Untrusted)
import Url exposing (Url)


type NavigationKey
    = RealNavigationKey Browser.Navigation.Key
    | MockNavigationKey


type FrontendModel
    = Loading NavigationKey ( Route, Maybe (CryptoHash LoginToken) )
    | Loaded LoadedFrontend


type alias LoadedFrontend =
    { navigationKey : NavigationKey
    , loginStatus : LoginStatus
    , route : Route
    , group : Maybe ( GroupId, Maybe FrontendGroup )
    , time : Time.Posix
    , lastConnectionCheck : Time.Posix
    , showLogin : Bool
    , email : String
    , pressedSubmitEmail : Bool
    , emailSent : Bool
    , logs : Maybe (Array Log)
    , hasLoginError : Bool
    }


type LoginStatus
    = LoggedIn (CryptoHash UserId) BackendUser
    | NotLoggedIn


type alias BackendModel =
    { users : Dict (CryptoHash UserId) BackendUser
    , groups : Dict GroupId BackendGroup
    , sessions : Dict SessionId { userId : CryptoHash UserId, connections : Nonempty ClientId }
    , logs : Array Log
    , time : Time.Posix
    , secretCounter : Int
    , pendingLoginTokens : Dict (CryptoHash LoginToken) { creationTime : Time.Posix, emailAddress : EmailAddress }
    }


type alias Log =
    { isError : Bool, title : NonemptyString, message : String, creationTime : Time.Posix }


type alias BackendUser =
    { name : NonemptyString
    , emailAddress : EmailAddress
    , profileImage : Avataaar
    }


type alias FrontendUser =
    { name : NonemptyString
    , profileImage : Avataaar
    }


type alias BackendGroup =
    { ownerId : CryptoHash UserId
    , name : NonemptyString
    , events : List Event
    , isPrivate : Bool
    }


type alias FrontendGroup =
    { ownerId : CryptoHash UserId
    , owner : FrontendUser
    , name : NonemptyString
    , events : List Event
    , isPrivate : Bool
    }


type alias Event =
    { attendees : Set (CryptoHash UserId)
    , startTime : Time.Posix
    , endTime : Time.Posix
    , isCancelled : Bool
    , description : NonemptyString
    }


type FrontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | GotTime Time.Posix
    | PressedLogin
    | PressedLogout
    | TypedEmail String
    | PressedSubmitEmail


type ToBackend
    = ToBackend (Nonempty ToBackendRequest)


type ToBackendRequest
    = GetGroupRequest GroupId
    | CheckLoginRequest
    | LoginWithTokenRequest (CryptoHash LoginToken)
    | LoginRequest Route (Untrusted EmailAddress)
    | GetAdminDataRequest
    | LogoutRequest


type BackendMsg
    = SentLoginEmail EmailAddress (Result SendGrid.Error ())
    | BackendGotTime Time.Posix


type ToFrontend
    = GetGroupResponse GroupId (Maybe FrontendGroup)
    | CheckLoginResponse LoginStatus
    | LoginWithTokenResponse (Result () ( CryptoHash UserId, BackendUser ))
    | GetAdminDataResponse (Array Log)
