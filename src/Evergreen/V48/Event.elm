module Evergreen.V48.Event exposing (..)

import AssocSet
import Evergreen.V48.Address
import Evergreen.V48.Description
import Evergreen.V48.EventDuration
import Evergreen.V48.EventName
import Evergreen.V48.Id
import Evergreen.V48.Link
import Evergreen.V48.MaxAttendees
import Time


type EventType
    = MeetOnline (Maybe Evergreen.V48.Link.Link)
    | MeetInPerson (Maybe Evergreen.V48.Address.Address)


type CancellationStatus
    = EventCancelled
    | EventUncancelled


type Event
    = Event
        { name : Evergreen.V48.EventName.EventName
        , description : Evergreen.V48.Description.Description
        , eventType : EventType
        , attendees : AssocSet.Set (Evergreen.V48.Id.Id Evergreen.V48.Id.UserId)
        , startTime : Time.Posix
        , duration : Evergreen.V48.EventDuration.EventDuration
        , cancellationStatus : Maybe ( CancellationStatus, Time.Posix )
        , createdAt : Time.Posix
        , maxAttendees : Evergreen.V48.MaxAttendees.MaxAttendees
        }
