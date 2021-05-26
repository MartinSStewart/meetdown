module Event exposing (Event, EventType(..), attendees, description, duration, endTime, eventType, isCancelled, name, newEvent, startTime)

import Address exposing (Address)
import AssocSet as Set exposing (Set)
import Description exposing (Description)
import Duration exposing (Duration)
import EventDuration exposing (EventDuration)
import EventName exposing (EventName)
import Id exposing (Id, UserId)
import Quantity
import Time
import Url exposing (Url)


type Event
    = Event
        { name : EventName
        , description : Description
        , eventType : EventType
        , attendees : Set (Id UserId)
        , startTime : Time.Posix
        , duration : EventDuration
        , isCancelled : Bool
        }


newEvent : EventName -> Description -> EventType -> Time.Posix -> EventDuration -> Event
newEvent eventName description_ eventType_ startTime_ duration_ =
    { name = eventName
    , description = description_
    , eventType = eventType_
    , attendees = Set.empty
    , startTime = startTime_
    , duration = duration_
    , isCancelled = False
    }
        |> Event


type EventType
    = MeetOnline Url
    | MeetInPerson Address


name : Event -> EventName
name (Event event) =
    event.name


description : Event -> Description
description (Event event) =
    event.description


eventType : Event -> EventType
eventType (Event event) =
    event.eventType


attendees : Event -> Set (Id UserId)
attendees (Event event) =
    event.attendees


startTime : Event -> Time.Posix
startTime (Event event) =
    event.startTime


duration : Event -> EventDuration
duration (Event event) =
    event.duration


isCancelled : Event -> Bool
isCancelled (Event event) =
    event.isCancelled


endTime : Event -> Time.Posix
endTime (Event event) =
    Duration.addTo event.startTime (EventDuration.toDuration event.duration)
