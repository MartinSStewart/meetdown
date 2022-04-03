module Evergreen.V56.Group exposing (..)

import AssocList
import AssocSet
import Evergreen.V56.Description
import Evergreen.V56.Event
import Evergreen.V56.GroupName
import Evergreen.V56.Id
import Time


type EventId
    = EventId Int


type GroupVisibility
    = UnlistedGroup
    | PublicGroup


type Group
    = Group
        { ownerId : Evergreen.V56.Id.Id Evergreen.V56.Id.UserId
        , name : Evergreen.V56.GroupName.GroupName
        , description : Evergreen.V56.Description.Description
        , events : AssocList.Dict EventId Evergreen.V56.Event.Event
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
