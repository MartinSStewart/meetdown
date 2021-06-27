module Evergreen.V29.Group exposing (..)

import AssocList
import AssocSet
import Evergreen.V29.Description
import Evergreen.V29.Event
import Evergreen.V29.GroupName
import Evergreen.V29.Id
import Time


type EventId
    = EventId Int


type GroupVisibility
    = UnlistedGroup
    | PublicGroup


type Group
    = Group
        { ownerId : Evergreen.V29.Id.Id Evergreen.V29.Id.UserId
        , name : Evergreen.V29.GroupName.GroupName
        , description : Evergreen.V29.Description.Description
        , events : AssocList.Dict EventId Evergreen.V29.Event.Event
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
