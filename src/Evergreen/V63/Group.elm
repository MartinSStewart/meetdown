module Evergreen.V63.Group exposing (..)

import AssocList
import AssocSet
import Evergreen.V63.Description
import Evergreen.V63.Event
import Evergreen.V63.GroupName
import Evergreen.V63.Id
import Time


type EventId
    = EventId Int


type GroupVisibility
    = UnlistedGroup
    | PublicGroup


type Group
    = Group
        { ownerId : Evergreen.V63.Id.Id Evergreen.V63.Id.UserId
        , name : Evergreen.V63.GroupName.GroupName
        , description : Evergreen.V63.Description.Description
        , events : AssocList.Dict EventId Evergreen.V63.Event.Event
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
