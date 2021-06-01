module Evergreen.V1.Event exposing (..)

import AssocSet
import Evergreen.V1.Address
import Evergreen.V1.Description
import Evergreen.V1.EventDuration
import Evergreen.V1.EventName
import Evergreen.V1.Id
import Evergreen.V1.Link
import Time


type EventType
    = MeetOnline (Maybe Evergreen.V1.Link.Link)
    | MeetInPerson (Maybe Evergreen.V1.Address.Address)


type Event
    = Event
        { name : Evergreen.V1.EventName.EventName
        , description : Evergreen.V1.Description.Description
        , eventType : EventType
        , attendees : AssocSet.Set (Evergreen.V1.Id.Id Evergreen.V1.Id.UserId)
        , startTime : Time.Posix
        , duration : Evergreen.V1.EventDuration.EventDuration
        , isCancelled : Bool
        }
