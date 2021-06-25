module Evergreen.V27.Group exposing (..)

import AssocList
import AssocSet
import Evergreen.V27.Description
import Evergreen.V27.Event
import Evergreen.V27.GroupName
import Evergreen.V27.Id
import Time


type EventId
    = EventId Int


type GroupVisibility
    = UnlistedGroup
    | PublicGroup


type Group
    = Group
        { ownerId : Evergreen.V27.Id.Id Evergreen.V27.Id.UserId
        , name : Evergreen.V27.GroupName.GroupName
        , description : Evergreen.V27.Description.Description
        , events : AssocList.Dict EventId Evergreen.V27.Event.Event
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
