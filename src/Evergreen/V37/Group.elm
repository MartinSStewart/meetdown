module Evergreen.V37.Group exposing (..)

import AssocList
import AssocSet
import Evergreen.V37.Description
import Evergreen.V37.Event
import Evergreen.V37.GroupName
import Evergreen.V37.Id
import Time


type EventId
    = EventId Int


type GroupVisibility
    = UnlistedGroup
    | PublicGroup


type Group
    = Group
        { ownerId : Evergreen.V37.Id.Id Evergreen.V37.Id.UserId
        , name : Evergreen.V37.GroupName.GroupName
        , description : Evergreen.V37.Description.Description
        , events : AssocList.Dict EventId Evergreen.V37.Event.Event
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
