module Evergreen.V33.Group exposing (..)

import AssocList
import AssocSet
import Evergreen.V33.Description
import Evergreen.V33.Event
import Evergreen.V33.GroupName
import Evergreen.V33.Id
import Time


type EventId
    = EventId Int


type GroupVisibility
    = UnlistedGroup
    | PublicGroup


type Group
    = Group
        { ownerId : Evergreen.V33.Id.Id Evergreen.V33.Id.UserId
        , name : Evergreen.V33.GroupName.GroupName
        , description : Evergreen.V33.Description.Description
        , events : AssocList.Dict EventId Evergreen.V33.Event.Event
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
