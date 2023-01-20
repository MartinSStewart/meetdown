module Evergreen.V62.Event exposing (..)

import AssocSet
import Evergreen.V62.Address
import Evergreen.V62.Description
import Evergreen.V62.EventDuration
import Evergreen.V62.EventName
import Evergreen.V62.Id
import Evergreen.V62.Link
import Evergreen.V62.MaxAttendees
import Time


type EventType
    = MeetOnline (Maybe Evergreen.V62.Link.Link)
    | MeetInPerson (Maybe Evergreen.V62.Address.Address)
    | MeetOnlineAndInPerson (Maybe Evergreen.V62.Link.Link) (Maybe Evergreen.V62.Address.Address)


type CancellationStatus
    = EventCancelled
    | EventUncancelled


type Event
    = Event
        { name : Evergreen.V62.EventName.EventName
        , description : Evergreen.V62.Description.Description
        , eventType : EventType
        , attendees : AssocSet.Set (Evergreen.V62.Id.Id Evergreen.V62.Id.UserId)
        , startTime : Time.Posix
        , duration : Evergreen.V62.EventDuration.EventDuration
        , cancellationStatus : Maybe ( CancellationStatus, Time.Posix )
        , createdAt : Time.Posix
        , maxAttendees : Evergreen.V62.MaxAttendees.MaxAttendees
        }
