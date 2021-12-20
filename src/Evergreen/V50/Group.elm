module Evergreen.V50.Group exposing (..)

import AssocList
import AssocSet
import Evergreen.V50.Description
import Evergreen.V50.Event
import Evergreen.V50.GroupName
import Evergreen.V50.Id
import Time


type EventId
    = EventId Int


type GroupVisibility
    = UnlistedGroup
    | PublicGroup


type Group
    = Group
        { ownerId : Evergreen.V50.Id.Id Evergreen.V50.Id.UserId
        , name : Evergreen.V50.GroupName.GroupName
        , description : Evergreen.V50.Description.Description
        , events : AssocList.Dict EventId Evergreen.V50.Event.Event
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
