module Event exposing (Event, EventType(..), addAttendee, attendees, cancel, description, duration, endTime, eventType, isCancelled, isOngoing, name, newEvent, overlaps, removeAttendee, startTime)

import Address exposing (Address)
import AssocSet as Set exposing (Set)
import Description exposing (Description)
import Duration exposing (Duration)
import EventDuration exposing (EventDuration)
import EventName exposing (EventName)
import Id exposing (Id, UserId)
import Link exposing (Link)
import Time


type Event
    = Event
        { name : EventName
        , description : Description
        , eventType : EventType
        , attendees : Set (Id UserId)
        , startTime : Time.Posix
        , duration : EventDuration
        , isCancelled : Maybe Time.Posix
        , createdAt : Time.Posix
        }


newEvent : EventName -> Description -> EventType -> Time.Posix -> EventDuration -> Time.Posix -> Event
newEvent eventName description_ eventType_ startTime_ duration_ createdAt =
    { name = eventName
    , description = description_
    , eventType = eventType_
    , attendees = Set.empty
    , startTime = startTime_
    , duration = duration_
    , isCancelled = Nothing
    , createdAt = createdAt
    }
        |> Event


addAttendee : Id UserId -> Event -> Event
addAttendee userId (Event event) =
    Event { event | attendees = Set.insert userId event.attendees }


removeAttendee : Id UserId -> Event -> Event
removeAttendee userId (Event event) =
    Event { event | attendees = Set.remove userId event.attendees }


type EventType
    = MeetOnline (Maybe Link)
    | MeetInPerson (Maybe Address)


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
    event.isCancelled /= Nothing


cancel : Time.Posix -> Event -> Event
cancel currentTime (Event event) =
    Event { event | isCancelled = Just currentTime }


endTime : Event -> Time.Posix
endTime (Event event) =
    Duration.addTo event.startTime (EventDuration.toDuration event.duration)


overlaps : Event -> Event -> Bool
overlaps eventA eventB =
    let
        startA =
            startTime eventA |> Time.posixToMillis

        endA =
            startTime eventA |> Time.posixToMillis

        startB =
            startTime eventB |> Time.posixToMillis

        endB =
            startTime eventB |> Time.posixToMillis
    in
    endA < startB || endB < startA |> not


isOngoing : Time.Posix -> Event -> Bool
isOngoing currentTime event =
    let
        start =
            startTime event |> Time.posixToMillis

        end =
            endTime event |> Time.posixToMillis

        time =
            Time.posixToMillis currentTime
    in
    start <= time && time < end
