module Evergreen.V56.Event exposing (..)

import AssocSet
import Evergreen.V56.Address
import Evergreen.V56.Description
import Evergreen.V56.EventDuration
import Evergreen.V56.EventName
import Evergreen.V56.Id
import Evergreen.V56.Link
import Evergreen.V56.MaxAttendees
import Time


type EventType
    = MeetOnline (Maybe Evergreen.V56.Link.Link)
    | MeetInPerson (Maybe Evergreen.V56.Address.Address)


type CancellationStatus
    = EventCancelled
    | EventUncancelled


type Event
    = Event
        { name : Evergreen.V56.EventName.EventName
        , description : Evergreen.V56.Description.Description
        , eventType : EventType
        , attendees : AssocSet.Set (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId)
        , startTime : Time.Posix
        , duration : Evergreen.V56.EventDuration.EventDuration
        , cancellationStatus : Maybe ( CancellationStatus, Time.Posix )
        , createdAt : Time.Posix
        , maxAttendees : Evergreen.V56.MaxAttendees.MaxAttendees
        }
