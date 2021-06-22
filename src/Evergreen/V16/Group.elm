module Evergreen.V16.Group exposing (..)

import AssocList
import AssocSet
import Evergreen.V16.Description
import Evergreen.V16.Event
import Evergreen.V16.GroupName
import Evergreen.V16.Id
import Time


type EventId
    = EventId Int


type GroupVisibility
    = UnlistedGroup
    | PublicGroup


type Group
    = Group
        { ownerId : Evergreen.V16.Id.Id Evergreen.V16.Id.UserId
        , name : Evergreen.V16.GroupName.GroupName
        , description : Evergreen.V16.Description.Description
        , events : AssocList.Dict EventId Evergreen.V16.Event.Event
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
