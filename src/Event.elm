module Event exposing (Event)

import AssocSet exposing (Set)
import Description exposing (Description)
import Id exposing (Id, UserId)
import Time


type alias Event =
    { attendees : Set (Id UserId)
    , startTime : Time.Posix
    , endTime : Time.Posix
    , isCancelled : Bool
    , description : Description
    }
