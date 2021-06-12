module Evergreen.V8.Event exposing (..)

import AssocSet
import Evergreen.V8.Address
import Evergreen.V8.Description
import Evergreen.V8.EventDuration
import Evergreen.V8.EventName
import Evergreen.V8.Id
import Evergreen.V8.Link
import Time


type EventType
    = MeetOnline (Maybe Evergreen.V8.Link.Link)
    | MeetInPerson (Maybe Evergreen.V8.Address.Address)


type Event
    = Event
        { name : Evergreen.V8.EventName.EventName
        , description : Evergreen.V8.Description.Description
        , eventType : EventType
        , attendees : AssocSet.Set (Evergreen.V8.Id.Id Evergreen.V8.Id.UserId)
        , startTime : Time.Posix
        , duration : Evergreen.V8.EventDuration.EventDuration
        , isCancelled : Maybe Time.Posix
        , createdAt : Time.Posix
        }
