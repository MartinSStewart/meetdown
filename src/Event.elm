module Event exposing (Event, EventType(..), endTime, newEvent)

import AssocSet as Set exposing (Set)
import Description exposing (Description)
import Duration exposing (Duration)
import EventName exposing (EventName)
import Id exposing (Id, UserId)
import Time
import Url exposing (Url)


type alias Event =
    { name : EventName
    , description : Description
    , eventType : EventType
    , attendees : Set (Id UserId)
    , startTime : Time.Posix
    , duration : Duration
    , isCancelled : Bool
    }


newEvent : EventName -> Description -> EventType -> Time.Posix -> Duration -> Event
newEvent eventName description eventType startTime duration =
    { name = eventName
    , description = description
    , eventType = eventType
    , attendees = Set.empty
    , startTime = startTime
    , duration = duration
    , isCancelled = False
    }


type EventType
    = MeetOnline Url
    | MeetInPerson String


endTime : Event -> Time.Posix
endTime event =
    Duration.addTo event.startTime event.duration
