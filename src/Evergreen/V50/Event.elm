module Evergreen.V50.Event exposing (..)

import AssocSet
import Evergreen.V50.Address
import Evergreen.V50.Description
import Evergreen.V50.EventDuration
import Evergreen.V50.EventName
import Evergreen.V50.Id
import Evergreen.V50.Link
import Evergreen.V50.MaxAttendees
import Time


type EventType
    = MeetOnline (Maybe Evergreen.V50.Link.Link)
    | MeetInPerson (Maybe Evergreen.V50.Address.Address)


type CancellationStatus
    = EventCancelled
    | EventUncancelled


type Event
    = Event
        { name : Evergreen.V50.EventName.EventName
        , description : Evergreen.V50.Description.Description
        , eventType : EventType
        , attendees : AssocSet.Set (Evergreen.V50.Id.Id Evergreen.V50.Id.UserId)
        , startTime : Time.Posix
        , duration : Evergreen.V50.EventDuration.EventDuration
        , cancellationStatus : Maybe ( CancellationStatus, Time.Posix )
        , createdAt : Time.Posix
        , maxAttendees : Evergreen.V50.MaxAttendees.MaxAttendees
        }
