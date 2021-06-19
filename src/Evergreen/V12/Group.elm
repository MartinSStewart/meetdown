module Evergreen.V12.Group exposing (..)

import AssocList
import AssocSet
import Evergreen.V12.Description
import Evergreen.V12.Event
import Evergreen.V12.GroupName
import Evergreen.V12.Id
import Time


type EventId
    = EventId Int


type GroupVisibility
    = UnlistedGroup
    | PublicGroup


type Group
    = Group
        { ownerId : Evergreen.V12.Id.Id Evergreen.V12.Id.UserId
        , name : Evergreen.V12.GroupName.GroupName
        , description : Evergreen.V12.Description.Description
        , events : AssocList.Dict EventId Evergreen.V12.Event.Event
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
