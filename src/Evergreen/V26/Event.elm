module Evergreen.V26.Event exposing (..)

import AssocSet
import Evergreen.V26.Address
import Evergreen.V26.Description
import Evergreen.V26.EventDuration
import Evergreen.V26.EventName
import Evergreen.V26.Id
import Evergreen.V26.Link
import Evergreen.V26.MaxAttendees
import Time


type EventType
    = MeetOnline (Maybe Evergreen.V26.Link.Link)
    | MeetInPerson (Maybe Evergreen.V26.Address.Address)


type CancellationStatus
    = EventCancelled
    | EventUncancelled


type Event
    = Event
        { name : Evergreen.V26.EventName.EventName
        , description : Evergreen.V26.Description.Description
        , eventType : EventType
        , attendees : AssocSet.Set (Evergreen.V26.Id.Id Evergreen.V26.Id.UserId)
        , startTime : Time.Posix
        , duration : Evergreen.V26.EventDuration.EventDuration
        , cancellationStatus : Maybe ( CancellationStatus, Time.Posix )
        , createdAt : Time.Posix
        , maxAttendees : Evergreen.V26.MaxAttendees.MaxAttendees
        }
