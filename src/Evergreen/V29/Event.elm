module Evergreen.V29.Event exposing (..)

import AssocSet
import Evergreen.V29.Address
import Evergreen.V29.Description
import Evergreen.V29.EventDuration
import Evergreen.V29.EventName
import Evergreen.V29.Id
import Evergreen.V29.Link
import Evergreen.V29.MaxAttendees
import Time


type EventType
    = MeetOnline (Maybe Evergreen.V29.Link.Link)
    | MeetInPerson (Maybe Evergreen.V29.Address.Address)


type CancellationStatus
    = EventCancelled
    | EventUncancelled


type Event
    = Event
        { name : Evergreen.V29.EventName.EventName
        , description : Evergreen.V29.Description.Description
        , eventType : EventType
        , attendees : AssocSet.Set (Evergreen.V29.Id.Id Evergreen.V29.Id.UserId)
        , startTime : Time.Posix
        , duration : Evergreen.V29.EventDuration.EventDuration
        , cancellationStatus : Maybe ( CancellationStatus, Time.Posix )
        , createdAt : Time.Posix
        , maxAttendees : Evergreen.V29.MaxAttendees.MaxAttendees
        }
