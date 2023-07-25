module Evergreen.V68.Event exposing (..)

import AssocSet
import Evergreen.V68.Address
import Evergreen.V68.Description
import Evergreen.V68.EventDuration
import Evergreen.V68.EventName
import Evergreen.V68.Id
import Evergreen.V68.Link
import Evergreen.V68.MaxAttendees
import Time


type EventType
    = MeetOnline (Maybe Evergreen.V68.Link.Link)
    | MeetInPerson (Maybe Evergreen.V68.Address.Address)
    | MeetOnlineAndInPerson (Maybe Evergreen.V68.Link.Link) (Maybe Evergreen.V68.Address.Address)


type CancellationStatus
    = EventCancelled
    | EventUncancelled


type Event
    = Event
        { name : Evergreen.V68.EventName.EventName
        , description : Evergreen.V68.Description.Description
        , eventType : EventType
        , attendees : AssocSet.Set (Evergreen.V68.Id.Id Evergreen.V68.Id.UserId)
        , startTime : Time.Posix
        , duration : Evergreen.V68.EventDuration.EventDuration
        , cancellationStatus : Maybe ( CancellationStatus, Time.Posix )
        , createdAt : Time.Posix
        , maxAttendees : Evergreen.V68.MaxAttendees.MaxAttendees
        }
