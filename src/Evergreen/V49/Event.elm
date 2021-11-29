module Evergreen.V49.Event exposing (..)

import AssocSet
import Evergreen.V49.Address
import Evergreen.V49.Description
import Evergreen.V49.EventDuration
import Evergreen.V49.EventName
import Evergreen.V49.Id
import Evergreen.V49.Link
import Evergreen.V49.MaxAttendees
import Time


type EventType
    = MeetOnline (Maybe Evergreen.V49.Link.Link)
    | MeetInPerson (Maybe Evergreen.V49.Address.Address)


type CancellationStatus
    = EventCancelled
    | EventUncancelled


type Event
    = Event
        { name : Evergreen.V49.EventName.EventName
        , description : Evergreen.V49.Description.Description
        , eventType : EventType
        , attendees : AssocSet.Set (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId)
        , startTime : Time.Posix
        , duration : Evergreen.V49.EventDuration.EventDuration
        , cancellationStatus : Maybe ( CancellationStatus, Time.Posix )
        , createdAt : Time.Posix
        , maxAttendees : Evergreen.V49.MaxAttendees.MaxAttendees
        }
