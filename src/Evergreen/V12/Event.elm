module Evergreen.V12.Event exposing (..)

import AssocSet
import Evergreen.V12.Address
import Evergreen.V12.Description
import Evergreen.V12.EventDuration
import Evergreen.V12.EventName
import Evergreen.V12.Id
import Evergreen.V12.Link
import Evergreen.V12.MaxAttendees
import Time


type EventType
    = MeetOnline (Maybe Evergreen.V12.Link.Link)
    | MeetInPerson (Maybe Evergreen.V12.Address.Address)


type CancellationStatus
    = EventCancelled
    | EventUncancelled


type Event
    = Event
        { name : Evergreen.V12.EventName.EventName
        , description : Evergreen.V12.Description.Description
        , eventType : EventType
        , attendees : AssocSet.Set (Evergreen.V12.Id.Id Evergreen.V12.Id.UserId)
        , startTime : Time.Posix
        , duration : Evergreen.V12.EventDuration.EventDuration
        , cancellationStatus : Maybe ( CancellationStatus, Time.Posix )
        , createdAt : Time.Posix
        , maxAttendees : Evergreen.V12.MaxAttendees.MaxAttendees
        }
