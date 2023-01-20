module Evergreen.V62.Group exposing (..)

import AssocList
import AssocSet
import Evergreen.V62.Description
import Evergreen.V62.Event
import Evergreen.V62.GroupName
import Evergreen.V62.Id
import Time


type EventId
    = EventId Int


type GroupVisibility
    = UnlistedGroup
    | PublicGroup


type Group
    = Group
        { ownerId : Evergreen.V62.Id.Id Evergreen.V62.Id.UserId
        , name : Evergreen.V62.GroupName.GroupName
        , description : Evergreen.V62.Description.Description
        , events : AssocList.Dict EventId Evergreen.V62.Event.Event
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
