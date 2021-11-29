module Evergreen.V49.Group exposing (..)

import AssocList
import AssocSet
import Evergreen.V49.Description
import Evergreen.V49.Event
import Evergreen.V49.GroupName
import Evergreen.V49.Id
import Time


type EventId
    = EventId Int


type GroupVisibility
    = UnlistedGroup
    | PublicGroup


type Group
    = Group
        { ownerId : Evergreen.V49.Id.Id Evergreen.V49.Id.UserId
        , name : Evergreen.V49.GroupName.GroupName
        , description : Evergreen.V49.Description.Description
        , events : AssocList.Dict EventId Evergreen.V49.Event.Event
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
