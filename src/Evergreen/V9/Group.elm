module Evergreen.V9.Group exposing (..)

import AssocList
import AssocSet
import Evergreen.V9.Description
import Evergreen.V9.Event
import Evergreen.V9.GroupName
import Evergreen.V9.Id
import Time


type EventId
    = EventId Int


type GroupVisibility
    = UnlistedGroup
    | PublicGroup


type Group
    = Group
        { ownerId : Evergreen.V9.Id.Id Evergreen.V9.Id.UserId
        , name : Evergreen.V9.GroupName.GroupName
        , description : Evergreen.V9.Description.Description
        , events : AssocList.Dict EventId Evergreen.V9.Event.Event
        , visibility : GroupVisibility
        , eventCounter : Int
        , createdAt : Time.Posix
        }


type EditEventError
    = EditEventStartsInThePast
    | EditEventOverlapsOtherEvents (AssocSet.Set EventId)
    | CantEditPastEvent
    | CantChangeStartTimeOfOngoingEvent
    | EditEventNotFound


type EditCancellationStatusError
    = CancellationStatusCantBeAfterEventStart
    | CantChangeCancellationStatusOfOngoingEvent
    | CantChangeCancellationStatusOfPastEvent
    | EditEventNotFound_
