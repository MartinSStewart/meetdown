module Evergreen.V6.Event exposing (..)

import AssocSet
import Evergreen.V6.Address
import Evergreen.V6.Description
import Evergreen.V6.EventDuration
import Evergreen.V6.EventName
import Evergreen.V6.Id
import Evergreen.V6.Link
import Time


type EventType
    = MeetOnline (Maybe Evergreen.V6.Link.Link)
    | MeetInPerson (Maybe Evergreen.V6.Address.Address)


type Event
    = Event
        { name : Evergreen.V6.EventName.EventName
        , description : Evergreen.V6.Description.Description
        , eventType : EventType
        , attendees : AssocSet.Set (Evergreen.V6.Id.Id Evergreen.V6.Id.UserId)
        , startTime : Time.Posix
        , duration : Evergreen.V6.EventDuration.EventDuration
        , isCancelled : Bool
        }
