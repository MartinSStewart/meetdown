module Evergreen.V74.Event exposing (..)

import Evergreen.V74.Address
import Evergreen.V74.Description
import Evergreen.V74.EventDuration
import Evergreen.V74.EventName
import Evergreen.V74.Id
import Evergreen.V74.Link
import Evergreen.V74.MaxAttendees
import SeqSet
import Time


type EventType
    = MeetOnline (Maybe Evergreen.V74.Link.Link)
    | MeetInPerson (Maybe Evergreen.V74.Address.Address)
    | MeetOnlineAndInPerson (Maybe Evergreen.V74.Link.Link) (Maybe Evergreen.V74.Address.Address)


type CancellationStatus
    = EventCancelled
    | EventUncancelled


type Event
    = Event
        { name : Evergreen.V74.EventName.EventName
        , description : Evergreen.V74.Description.Description
        , eventType : EventType
        , attendees : SeqSet.SeqSet (Evergreen.V74.Id.Id Evergreen.V74.Id.UserId)
        , startTime : Time.Posix
        , duration : Evergreen.V74.EventDuration.EventDuration
        , cancellationStatus : Maybe ( CancellationStatus, Time.Posix )
        , createdAt : Time.Posix
        , maxAttendees : Evergreen.V74.MaxAttendees.MaxAttendees
        }
