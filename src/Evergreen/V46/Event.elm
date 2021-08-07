module Evergreen.V46.Event exposing (..)

import AssocSet
import Evergreen.V46.Address
import Evergreen.V46.Description
import Evergreen.V46.EventDuration
import Evergreen.V46.EventName
import Evergreen.V46.Id
import Evergreen.V46.Link
import Evergreen.V46.MaxAttendees
import Time


type EventType
    = MeetOnline (Maybe Evergreen.V46.Link.Link)
    | MeetInPerson (Maybe Evergreen.V46.Address.Address)


type CancellationStatus
    = EventCancelled
    | EventUncancelled


type Event
    = Event
        { name : Evergreen.V46.EventName.EventName
        , description : Evergreen.V46.Description.Description
        , eventType : EventType
        , attendees : AssocSet.Set (Evergreen.V46.Id.Id Evergreen.V46.Id.UserId)
        , startTime : Time.Posix
        , duration : Evergreen.V46.EventDuration.EventDuration
        , cancellationStatus : Maybe ( CancellationStatus, Time.Posix )
        , createdAt : Time.Posix
        , maxAttendees : Evergreen.V46.MaxAttendees.MaxAttendees
        }
