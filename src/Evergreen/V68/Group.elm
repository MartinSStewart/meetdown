module Evergreen.V68.Group exposing (..)

import AssocList
import AssocSet
import Evergreen.V68.Description
import Evergreen.V68.Event
import Evergreen.V68.GroupName
import Evergreen.V68.Id
import Time


type EventId
    = EventId Int


type GroupVisibility
    = UnlistedGroup
    | PublicGroup


type Group
    = Group
        { ownerId : Evergreen.V68.Id.Id Evergreen.V68.Id.UserId
        , name : Evergreen.V68.GroupName.GroupName
        , description : Evergreen.V68.Description.Description
        , events : AssocList.Dict EventId Evergreen.V68.Event.Event
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
