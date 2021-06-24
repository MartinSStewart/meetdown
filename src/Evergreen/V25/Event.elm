module Evergreen.V25.Event exposing (..)

import AssocSet
import Evergreen.V25.Address
import Evergreen.V25.Description
import Evergreen.V25.EventDuration
import Evergreen.V25.EventName
import Evergreen.V25.Id
import Evergreen.V25.Link
import Evergreen.V25.MaxAttendees
import Time


type EventType
    = MeetOnline (Maybe Evergreen.V25.Link.Link)
    | MeetInPerson (Maybe Evergreen.V25.Address.Address)


type CancellationStatus
    = EventCancelled
    | EventUncancelled


type Event
    = Event
        { name : Evergreen.V25.EventName.EventName
        , description : Evergreen.V25.Description.Description
        , eventType : EventType
        , attendees : AssocSet.Set (Evergreen.V25.Id.Id Evergreen.V25.Id.UserId)
        , startTime : Time.Posix
        , duration : Evergreen.V25.EventDuration.EventDuration
        , cancellationStatus : Maybe ( CancellationStatus, Time.Posix )
        , createdAt : Time.Posix
        , maxAttendees : Evergreen.V25.MaxAttendees.MaxAttendees
        }
