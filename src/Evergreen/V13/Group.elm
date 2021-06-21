module Evergreen.V13.Group exposing (..)

import AssocList
import AssocSet
import Evergreen.V13.Description
import Evergreen.V13.Event
import Evergreen.V13.GroupName
import Evergreen.V13.Id
import Time


type EventId
    = EventId Int


type GroupVisibility
    = UnlistedGroup
    | PublicGroup


type Group
    = Group
        { ownerId : Evergreen.V13.Id.Id Evergreen.V13.Id.UserId
        , name : Evergreen.V13.GroupName.GroupName
        , description : Evergreen.V13.Description.Description
        , events : AssocList.Dict EventId Evergreen.V13.Event.Event
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
