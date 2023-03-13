module Evergreen.V63.Event exposing (..)

import AssocSet
import Evergreen.V63.Address
import Evergreen.V63.Description
import Evergreen.V63.EventDuration
import Evergreen.V63.EventName
import Evergreen.V63.Id
import Evergreen.V63.Link
import Evergreen.V63.MaxAttendees
import Time


type EventType
    = MeetOnline (Maybe Evergreen.V63.Link.Link)
    | MeetInPerson (Maybe Evergreen.V63.Address.Address)
    | MeetOnlineAndInPerson (Maybe Evergreen.V63.Link.Link) (Maybe Evergreen.V63.Address.Address)


type CancellationStatus
    = EventCancelled
    | EventUncancelled


type Event
    = Event
        { name : Evergreen.V63.EventName.EventName
        , description : Evergreen.V63.Description.Description
        , eventType : EventType
        , attendees : AssocSet.Set (Evergreen.V63.Id.Id Evergreen.V63.Id.UserId)
        , startTime : Time.Posix
        , duration : Evergreen.V63.EventDuration.EventDuration
        , cancellationStatus : Maybe ( CancellationStatus, Time.Posix )
        , createdAt : Time.Posix
        , maxAttendees : Evergreen.V63.MaxAttendees.MaxAttendees
        }
