module Types exposing (..)

import AssocList exposing (Dict)
import AssocSet exposing (Set)
import Avataaars exposing (Avataaar)
import Browser exposing (UrlRequest)
import Browser.Navigation
import Email exposing (Email)
import Id exposing (ClientId, GroupId, SessionId, UserId)
import List.Nonempty exposing (Nonempty)
import String.Nonempty exposing (NonemptyString)
import Time
import Url exposing (Url)


type NavigationKey
    = RealNavigationKey Browser.Navigation.Key
    | MockNavigationKey


type FrontendModel
    = Loading NavigationKey Route
    | Loaded LoadedFrontend


type alias LoadedFrontend =
    { navigationKey : NavigationKey
    , loginStatus : LoginStatus
    , route : Route
    , group : Maybe ( GroupId, Result () FrontendGroup )
    , time : Time.Posix
    , lastConnectionCheck : Time.Posix
    }


type Route
    = Homepage
    | GroupRoute GroupId


type LoginStatus
    = LoggedIn UserId BackendUser
    | NotLoggedIn


type alias BackendModel =
    { users : Dict UserId BackendUser
    , groups : Dict GroupId BackendGroup
    , sessions : Dict SessionId { userId : UserId, connections : Nonempty ClientId }
    }


type alias BackendUser =
    { name : NonemptyString
    , emailAddress : Email
    , emailConfirmed : Bool
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
    | NoOpFrontendMsg


type ToBackend
    = CheckLoginAndGetGroupRequest GroupId
    | GetGroupRequest GroupId
    | CheckLoginRequest


type BackendMsg
    = NoOpBackendMsg


type ToFrontend
    = CheckLoginAndGetGroupResponse LoginStatus GroupId (Maybe FrontendGroup)
    | GetGroupResponse GroupId (Maybe FrontendGroup)
    | CheckLoginResponse LoginStatus
