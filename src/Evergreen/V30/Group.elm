module Evergreen.V30.Group exposing (..)

import AssocList
import AssocSet
import Evergreen.V30.Description
import Evergreen.V30.Event
import Evergreen.V30.GroupName
import Evergreen.V30.Id
import Time


type EventId
    = EventId Int


type GroupVisibility
    = UnlistedGroup
    | PublicGroup


type Group
    = Group
        { ownerId : Evergreen.V30.Id.Id Evergreen.V30.Id.UserId
        , name : Evergreen.V30.GroupName.GroupName
        , description : Evergreen.V30.Description.Description
        , events : AssocList.Dict EventId Evergreen.V30.Event.Event
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
