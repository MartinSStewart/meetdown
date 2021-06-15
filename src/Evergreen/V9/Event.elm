module Evergreen.V9.Event exposing (..)

import AssocSet
import Evergreen.V9.Address
import Evergreen.V9.Description
import Evergreen.V9.EventDuration
import Evergreen.V9.EventName
import Evergreen.V9.Id
import Evergreen.V9.Link
import Time


type EventType
    = MeetOnline (Maybe Evergreen.V9.Link.Link)
    | MeetInPerson (Maybe Evergreen.V9.Address.Address)


type CancellationStatus
    = EventCancelled
    | EventUncancelled


type Event
    = Event
        { name : Evergreen.V9.EventName.EventName
        , description : Evergreen.V9.Description.Description
        , eventType : EventType
        , attendees : AssocSet.Set (Evergreen.V9.Id.Id Evergreen.V9.Id.UserId)
        , startTime : Time.Posix
        , duration : Evergreen.V9.EventDuration.EventDuration
        , cancellationStatus : Maybe ( CancellationStatus, Time.Posix )
        , createdAt : Time.Posix
        }
