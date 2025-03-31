module Evergreen.V73.Event exposing (..)

import Evergreen.V73.Address
import Evergreen.V73.Description
import Evergreen.V73.EventDuration
import Evergreen.V73.EventName
import Evergreen.V73.Id
import Evergreen.V73.Link
import Evergreen.V73.MaxAttendees
import SeqSet
import Time


type EventType
    = MeetOnline (Maybe Evergreen.V73.Link.Link)
    | MeetInPerson (Maybe Evergreen.V73.Address.Address)
    | MeetOnlineAndInPerson (Maybe Evergreen.V73.Link.Link) (Maybe Evergreen.V73.Address.Address)


type CancellationStatus
    = EventCancelled
    | EventUncancelled


type Event
    = Event
        { name : Evergreen.V73.EventName.EventName
        , description : Evergreen.V73.Description.Description
        , eventType : EventType
        , attendees : SeqSet.SeqSet (Evergreen.V73.Id.Id Evergreen.V73.Id.UserId)
        , startTime : Time.Posix
        , duration : Evergreen.V73.EventDuration.EventDuration
        , cancellationStatus : Maybe ( CancellationStatus, Time.Posix )
        , createdAt : Time.Posix
        , maxAttendees : Evergreen.V73.MaxAttendees.MaxAttendees
        }
