module Evergreen.V25.Group exposing (..)

import AssocList
import AssocSet
import Evergreen.V25.Description
import Evergreen.V25.Event
import Evergreen.V25.GroupName
import Evergreen.V25.Id
import Time


type EventId
    = EventId Int


type GroupVisibility
    = UnlistedGroup
    | PublicGroup


type Group
    = Group
        { ownerId : Evergreen.V25.Id.Id Evergreen.V25.Id.UserId
        , name : Evergreen.V25.GroupName.GroupName
        , description : Evergreen.V25.Description.Description
        , events : AssocList.Dict EventId Evergreen.V25.Event.Event
        , visibility : GroupVisibility
        , eventCounter : Int
        , createdAt : Time.Posix
        , pendingReview : Bool
        }


type EditEventError
    = EditEventStartsInThePast
    | EditEventOverlapsOtherEvents (AssocSet.Set EventId)
    | CantEditPastEvent
    | CantChangeStartTimeOfOngoingEvent
    | EditEventNotFound


type JoinEventError
    = NoSpotsLeftInEvent
    | EventNotFound


type EditCancellationStatusError
    = CancellationStatusCantBeAfterEventStart
    | CantChangeCancellationStatusOfOngoingEvent
    | CantChangeCancellationStatusOfPastEvent
    | EditEventNotFound_
