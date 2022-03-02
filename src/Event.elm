module Event exposing
    ( CancellationStatus(..)
    , Event(..)
    , EventType(..)
    , addAttendee
    , attendees
    , cancellationStatus
    , description
    , duration
    , endTime
    , eventType
    , isCancelled
    , isOngoing
    , maxAttendees
    , name
    , newEvent
    , overlaps
    , removeAttendee
    , startTime
    , withCancellationStatus
    , withDescription
    , withDuration
    , withEventType
    , withMaxAttendees
    , withName
    , withStartTime
    )

import Address exposing (Address)
import AssocSet as Set exposing (Set)
import Description exposing (Description)
import Duration exposing (Duration)
import EventDuration exposing (EventDuration)
import EventName exposing (EventName)
import Id exposing (Id, UserId)
import Link exposing (Link)
import MaxAttendees exposing (MaxAttendees)
import Time


type Event
    = Event
        { name : EventName
        , description : Description
        , eventType : EventType
        , attendees : Set (Id UserId)
        , startTime : Time.Posix
        , duration : EventDuration
        , cancellationStatus : Maybe ( CancellationStatus, Time.Posix )
        , createdAt : Time.Posix
        , maxAttendees : MaxAttendees
        }


type CancellationStatus
    = EventCancelled
    | EventUncancelled


newEvent :
    Id UserId
    -> EventName
    -> Description
    -> EventType
    -> Time.Posix
    -> EventDuration
    -> Time.Posix
    -> MaxAttendees
    -> Event
newEvent groupOwnerId eventName description_ eventType_ startTime_ duration_ createdAt maxAttendees_ =
    { name = eventName
    , description = description_
    , eventType = eventType_
    , attendees = Set.singleton groupOwnerId
    , startTime = startTime_
    , duration = duration_
    , cancellationStatus = Nothing
    , createdAt = createdAt
    , maxAttendees = maxAttendees_
    }
        |> Event


addAttendee : Id UserId -> Event -> Result () Event
addAttendee userId (Event event) =
    let
        newSet =
            Set.insert userId event.attendees
    in
    if MaxAttendees.tooManyAttendees (Set.size newSet) event.maxAttendees then
        Err ()

    else
        Event { event | attendees = Set.insert userId event.attendees } |> Ok


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


maxAttendees : Event -> MaxAttendees
maxAttendees (Event event) =
    event.maxAttendees


cancellationStatus : Event -> Maybe ( CancellationStatus, Time.Posix )
cancellationStatus (Event event) =
    event.cancellationStatus


withCancellationStatus : Time.Posix -> CancellationStatus -> Event -> Event
withCancellationStatus time status (Event event) =
    Event { event | cancellationStatus = Just ( status, time ) }


isCancelled : Event -> Bool
isCancelled event =
    case cancellationStatus event of
        Just ( EventCancelled, _ ) ->
            True

        Just ( EventUncancelled, _ ) ->
            False

        Nothing ->
            False


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


withName : EventName -> Event -> Event
withName eventName (Event event) =
    Event { event | name = eventName }


withDescription : Description -> Event -> Event
withDescription description_ (Event event) =
    Event { event | description = description_ }


withEventType : EventType -> Event -> Event
withEventType eventType_ (Event event) =
    Event { event | eventType = eventType_ }


withDuration : EventDuration -> Event -> Event
withDuration eventDuration_ (Event event) =
    Event { event | duration = eventDuration_ }


withStartTime : Time.Posix -> Event -> Event
withStartTime startTime_ (Event event) =
    Event { event | startTime = startTime_ }


withMaxAttendees : MaxAttendees -> Event -> Event
withMaxAttendees newMax (Event event) =
    Event { event | maxAttendees = newMax }
