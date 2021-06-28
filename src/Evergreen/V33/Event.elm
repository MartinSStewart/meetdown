module Evergreen.V33.Event exposing (..)

import AssocSet
import Evergreen.V33.Address
import Evergreen.V33.Description
import Evergreen.V33.EventDuration
import Evergreen.V33.EventName
import Evergreen.V33.Id
import Evergreen.V33.Link
import Evergreen.V33.MaxAttendees
import Time


type EventType
    = MeetOnline (Maybe Evergreen.V33.Link.Link)
    | MeetInPerson (Maybe Evergreen.V33.Address.Address)


type CancellationStatus
    = EventCancelled
    | EventUncancelled


type Event
    = Event
        { name : Evergreen.V33.EventName.EventName
        , description : Evergreen.V33.Description.Description
        , eventType : EventType
        , attendees : AssocSet.Set (Evergreen.V33.Id.Id Evergreen.V33.Id.UserId)
        , startTime : Time.Posix
        , duration : Evergreen.V33.EventDuration.EventDuration
        , cancellationStatus : Maybe ( CancellationStatus, Time.Posix )
        , createdAt : Time.Posix
        , maxAttendees : Evergreen.V33.MaxAttendees.MaxAttendees
        }
