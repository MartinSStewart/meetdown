module Evergreen.V27.Event exposing (..)

import AssocSet
import Evergreen.V27.Address
import Evergreen.V27.Description
import Evergreen.V27.EventDuration
import Evergreen.V27.EventName
import Evergreen.V27.Id
import Evergreen.V27.Link
import Evergreen.V27.MaxAttendees
import Time


type EventType
    = MeetOnline (Maybe Evergreen.V27.Link.Link)
    | MeetInPerson (Maybe Evergreen.V27.Address.Address)


type CancellationStatus
    = EventCancelled
    | EventUncancelled


type Event
    = Event
        { name : Evergreen.V27.EventName.EventName
        , description : Evergreen.V27.Description.Description
        , eventType : EventType
        , attendees : AssocSet.Set (Evergreen.V27.Id.Id Evergreen.V27.Id.UserId)
        , startTime : Time.Posix
        , duration : Evergreen.V27.EventDuration.EventDuration
        , cancellationStatus : Maybe ( CancellationStatus, Time.Posix )
        , createdAt : Time.Posix
        , maxAttendees : Evergreen.V27.MaxAttendees.MaxAttendees
        }
