module Types exposing (..)

import AssocList exposing (Dict)
import AssocSet exposing (Set)
import Avataaars exposing (Avataaar)
import Browser exposing (UrlRequest)
import Browser.Navigation
import Email exposing (Email)
import Lamdera
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
    , group : Maybe ( GroupId, Group )
    , time : Time.Posix
    , lastConnectionCheck : Time.Posix
    }


initLoadedFrontend : NavigationKey -> Route -> Time.Posix -> LoadedFrontend
initLoadedFrontend navigationKey route time =
    { navigationKey = navigationKey
    , loginStatus = NotLoggedIn
    , route = route
    , group = Nothing
    , time = time
    , lastConnectionCheck = time
    }


type SessionId
    = SessionId Lamdera.SessionId


type ClientId
    = ClientId Lamdera.ClientId


type Route
    = Homepage
    | GroupRoute GroupId


type LoginStatus
    = LoggedIn UserId User
    | NotLoggedIn


type alias BackendModel =
    { users : Dict UserId User
    , groups : Dict GroupId Group
    , sessions : Dict SessionId { userId : UserId, connections : Nonempty ClientId }
    }


type UserId
    = UserId Int


type GroupId
    = GroupId Int


type alias User =
    { name : NonemptyString
    , emailAddress : Email
    , emailConfirmed : Bool
    , profileImage : Avataaar
    }


type alias Group =
    { owner : UserId
    , events : List Event
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
    = NoOpToBackend


type BackendMsg
    = NoOpBackendMsg


type ToFrontend
    = NoOpToFrontend
