module Evergreen.V37.Event exposing (..)

import AssocSet
import Evergreen.V37.Address
import Evergreen.V37.Description
import Evergreen.V37.EventDuration
import Evergreen.V37.EventName
import Evergreen.V37.Id
import Evergreen.V37.Link
import Evergreen.V37.MaxAttendees
import Time


type EventType
    = MeetOnline (Maybe Evergreen.V37.Link.Link)
    | MeetInPerson (Maybe Evergreen.V37.Address.Address)


type CancellationStatus
    = EventCancelled
    | EventUncancelled


type Event
    = Event
        { name : Evergreen.V37.EventName.EventName
        , description : Evergreen.V37.Description.Description
        , eventType : EventType
        , attendees : AssocSet.Set (Evergreen.V37.Id.Id Evergreen.V37.Id.UserId)
        , startTime : Time.Posix
        , duration : Evergreen.V37.EventDuration.EventDuration
        , cancellationStatus : Maybe ( CancellationStatus, Time.Posix )
        , createdAt : Time.Posix
        , maxAttendees : Evergreen.V37.MaxAttendees.MaxAttendees
        }
