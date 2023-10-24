module Evergreen.V69.Event exposing (..)

import AssocSet
import Evergreen.V69.Address
import Evergreen.V69.Description
import Evergreen.V69.EventDuration
import Evergreen.V69.EventName
import Evergreen.V69.Id
import Evergreen.V69.Link
import Evergreen.V69.MaxAttendees
import Time


type EventType
    = MeetOnline (Maybe Evergreen.V69.Link.Link)
    | MeetInPerson (Maybe Evergreen.V69.Address.Address)
    | MeetOnlineAndInPerson (Maybe Evergreen.V69.Link.Link) (Maybe Evergreen.V69.Address.Address)


type CancellationStatus
    = EventCancelled
    | EventUncancelled


type Event
    = Event
        { name : Evergreen.V69.EventName.EventName
        , description : Evergreen.V69.Description.Description
        , eventType : EventType
        , attendees : AssocSet.Set (Evergreen.V69.Id.Id Evergreen.V69.Id.UserId)
        , startTime : Time.Posix
        , duration : Evergreen.V69.EventDuration.EventDuration
        , cancellationStatus : Maybe ( CancellationStatus, Time.Posix )
        , createdAt : Time.Posix
        , maxAttendees : Evergreen.V69.MaxAttendees.MaxAttendees
        }
