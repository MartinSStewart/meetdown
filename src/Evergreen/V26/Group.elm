module Evergreen.V26.Group exposing (..)

import AssocList
import AssocSet
import Evergreen.V26.Description
import Evergreen.V26.Event
import Evergreen.V26.GroupName
import Evergreen.V26.Id
import Time


type EventId
    = EventId Int


type GroupVisibility
    = UnlistedGroup
    | PublicGroup


type Group
    = Group
        { ownerId : Evergreen.V26.Id.Id Evergreen.V26.Id.UserId
        , name : Evergreen.V26.GroupName.GroupName
        , description : Evergreen.V26.Description.Description
        , events : AssocList.Dict EventId Evergreen.V26.Event.Event
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
