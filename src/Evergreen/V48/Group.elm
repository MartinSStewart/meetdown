module Evergreen.V48.Group exposing (..)

import AssocList
import AssocSet
import Evergreen.V48.Description
import Evergreen.V48.Event
import Evergreen.V48.GroupName
import Evergreen.V48.Id
import Time


type EventId
    = EventId Int


type GroupVisibility
    = UnlistedGroup
    | PublicGroup


type Group
    = Group
        { ownerId : Evergreen.V48.Id.Id Evergreen.V48.Id.UserId
        , name : Evergreen.V48.GroupName.GroupName
        , description : Evergreen.V48.Description.Description
        , events : AssocList.Dict EventId Evergreen.V48.Event.Event
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
