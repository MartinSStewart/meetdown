module Evergreen.V13.Event exposing (..)

import AssocSet
import Evergreen.V13.Address
import Evergreen.V13.Description
import Evergreen.V13.EventDuration
import Evergreen.V13.EventName
import Evergreen.V13.Id
import Evergreen.V13.Link
import Evergreen.V13.MaxAttendees
import Time


type EventType
    = MeetOnline (Maybe Evergreen.V13.Link.Link)
    | MeetInPerson (Maybe Evergreen.V13.Address.Address)


type CancellationStatus
    = EventCancelled
    | EventUncancelled


type Event
    = Event
        { name : Evergreen.V13.EventName.EventName
        , description : Evergreen.V13.Description.Description
        , eventType : EventType
        , attendees : AssocSet.Set (Evergreen.V13.Id.Id Evergreen.V13.Id.UserId)
        , startTime : Time.Posix
        , duration : Evergreen.V13.EventDuration.EventDuration
        , cancellationStatus : Maybe ( CancellationStatus, Time.Posix )
        , createdAt : Time.Posix
        , maxAttendees : Evergreen.V13.MaxAttendees.MaxAttendees
        }
