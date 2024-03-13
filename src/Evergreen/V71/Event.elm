module Evergreen.V71.Event exposing (..)

import AssocSet
import Evergreen.V71.Address
import Evergreen.V71.Description
import Evergreen.V71.EventDuration
import Evergreen.V71.EventName
import Evergreen.V71.Id
import Evergreen.V71.Link
import Evergreen.V71.MaxAttendees
import Time


type EventType
    = MeetOnline (Maybe Evergreen.V71.Link.Link)
    | MeetInPerson (Maybe Evergreen.V71.Address.Address)
    | MeetOnlineAndInPerson (Maybe Evergreen.V71.Link.Link) (Maybe Evergreen.V71.Address.Address)


type CancellationStatus
    = EventCancelled
    | EventUncancelled


type Event
    = Event
        { name : Evergreen.V71.EventName.EventName
        , description : Evergreen.V71.Description.Description
        , eventType : EventType
        , attendees : AssocSet.Set (Evergreen.V71.Id.Id Evergreen.V71.Id.UserId)
        , startTime : Time.Posix
        , duration : Evergreen.V71.EventDuration.EventDuration
        , cancellationStatus : Maybe ( CancellationStatus, Time.Posix )
        , createdAt : Time.Posix
        , maxAttendees : Evergreen.V71.MaxAttendees.MaxAttendees
        }
