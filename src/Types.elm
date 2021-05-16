module Types exposing (..)

import Array exposing (Array)
import AssocList exposing (Dict)
import AssocSet exposing (Set)
import Avataaars exposing (Avataaar)
import Browser exposing (UrlRequest)
import Browser.Navigation
import Email exposing (Email)
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
    = LoggedIn UserId BackendUser
    | NotLoggedIn


type alias BackendModel =
    { users : Dict UserId BackendUser
    , groups : Dict GroupId BackendGroup
    , sessions : Dict SessionId { userId : UserId, connections : Nonempty ClientId }
    , logs : Array Log
    , time : Time.Posix
    , secretCounter : Int
    }


type alias Log =
    { isError : Bool, title : NonemptyString, message : String, time : Time.Posix }


type alias BackendUser =
    { name : NonemptyString
    , emailAddress : Email
    , profileImage : Avataaar
    }


type alias FrontendUser =
    { name : NonemptyString
    , profileImage : Avataaar
    }


type alias BackendGroup =
    { ownerId : UserId
    , name : NonemptyString
    , events : List Event
    , isPrivate : Bool
    }


type alias FrontendGroup =
    { ownerId : UserId
    , owner : FrontendUser
    , name : NonemptyString
    , events : List Event
    , isPrivate : Bool
    }


type alias Event =
    { attendees : Set UserId
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
    | TypedEmail String
    | PressedSubmitEmail


type alias ToBackend =
    Nonempty ToBackendRequest


type ToBackendRequest
    = GetGroupRequest GroupId
    | CheckLoginRequest
    | LoginWithTokenRequest (CryptoHash LoginToken)
    | LoginRequest Route (Untrusted Email)
    | GetAdminDataRequest


type BackendMsg
    = SentLoginEmail Email (Result SendGrid.Error ())
    | BackendGotTime Time.Posix


type ToFrontend
    = GetGroupResponse GroupId (Maybe FrontendGroup)
    | CheckLoginResponse LoginStatus
    | LoginWithTokenResponse (Result () ( UserId, BackendUser ))
    | GetAdminDataResponse (Array Log)
