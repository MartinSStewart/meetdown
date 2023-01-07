module Evergreen.V61.Event exposing (..)

import AssocSet
import Evergreen.V61.Address
import Evergreen.V61.Description
import Evergreen.V61.EventDuration
import Evergreen.V61.EventName
import Evergreen.V61.Id
import Evergreen.V61.Link
import Evergreen.V61.MaxAttendees
import Time


type EventType
    = MeetOnline (Maybe Evergreen.V61.Link.Link)
    | MeetInPerson (Maybe Evergreen.V61.Address.Address)
    | MeetOnlineAndInPerson (Maybe Evergreen.V61.Link.Link) (Maybe Evergreen.V61.Address.Address)


type CancellationStatus
    = EventCancelled
    | EventUncancelled


type Event
    = Event
        { name : Evergreen.V61.EventName.EventName
        , description : Evergreen.V61.Description.Description
        , eventType : EventType
        , attendees : AssocSet.Set (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId)
        , startTime : Time.Posix
        , duration : Evergreen.V61.EventDuration.EventDuration
        , cancellationStatus : Maybe ( CancellationStatus, Time.Posix )
        , createdAt : Time.Posix
        , maxAttendees : Evergreen.V61.MaxAttendees.MaxAttendees
        }
