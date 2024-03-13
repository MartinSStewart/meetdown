module Evergreen.V71.Group exposing (..)

import AssocList
import AssocSet
import Evergreen.V71.Description
import Evergreen.V71.Event
import Evergreen.V71.GroupName
import Evergreen.V71.Id
import Time


type EventId
    = EventId Int


type GroupVisibility
    = UnlistedGroup
    | PublicGroup


type Group
    = Group
        { ownerId : Evergreen.V71.Id.Id Evergreen.V71.Id.UserId
        , name : Evergreen.V71.GroupName.GroupName
        , description : Evergreen.V71.Description.Description
        , events : AssocList.Dict EventId Evergreen.V71.Event.Event
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
