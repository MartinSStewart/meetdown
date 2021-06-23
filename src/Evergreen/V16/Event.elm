module Evergreen.V16.Event exposing (..)

import AssocSet
import Evergreen.V16.Address
import Evergreen.V16.Description
import Evergreen.V16.EventDuration
import Evergreen.V16.EventName
import Evergreen.V16.Id
import Evergreen.V16.Link
import Evergreen.V16.MaxAttendees
import Time


type EventType
    = MeetOnline (Maybe Evergreen.V16.Link.Link)
    | MeetInPerson (Maybe Evergreen.V16.Address.Address)


type CancellationStatus
    = EventCancelled
    | EventUncancelled


type Event
    = Event
        { name : Evergreen.V16.EventName.EventName
        , description : Evergreen.V16.Description.Description
        , eventType : EventType
        , attendees : AssocSet.Set (Evergreen.V16.Id.Id Evergreen.V16.Id.UserId)
        , startTime : Time.Posix
        , duration : Evergreen.V16.EventDuration.EventDuration
        , cancellationStatus : Maybe ( CancellationStatus, Time.Posix )
        , createdAt : Time.Posix
        , maxAttendees : Evergreen.V16.MaxAttendees.MaxAttendees
        }
