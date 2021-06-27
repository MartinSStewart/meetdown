module Evergreen.V30.Event exposing (..)

import AssocSet
import Evergreen.V30.Address
import Evergreen.V30.Description
import Evergreen.V30.EventDuration
import Evergreen.V30.EventName
import Evergreen.V30.Id
import Evergreen.V30.Link
import Evergreen.V30.MaxAttendees
import Time


type EventType
    = MeetOnline (Maybe Evergreen.V30.Link.Link)
    | MeetInPerson (Maybe Evergreen.V30.Address.Address)


type CancellationStatus
    = EventCancelled
    | EventUncancelled


type Event
    = Event
        { name : Evergreen.V30.EventName.EventName
        , description : Evergreen.V30.Description.Description
        , eventType : EventType
        , attendees : AssocSet.Set (Evergreen.V30.Id.Id Evergreen.V30.Id.UserId)
        , startTime : Time.Posix
        , duration : Evergreen.V30.EventDuration.EventDuration
        , cancellationStatus : Maybe ( CancellationStatus, Time.Posix )
        , createdAt : Time.Posix
        , maxAttendees : Evergreen.V30.MaxAttendees.MaxAttendees
        }
