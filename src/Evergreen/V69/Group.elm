module Evergreen.V69.Group exposing (..)

import AssocList
import AssocSet
import Evergreen.V69.Description
import Evergreen.V69.Event
import Evergreen.V69.GroupName
import Evergreen.V69.Id
import Time


type EventId
    = EventId Int


type GroupVisibility
    = UnlistedGroup
    | PublicGroup


type Group
    = Group
        { ownerId : Evergreen.V69.Id.Id Evergreen.V69.Id.UserId
        , name : Evergreen.V69.GroupName.GroupName
        , description : Evergreen.V69.Description.Description
        , events : AssocList.Dict EventId Evergreen.V69.Event.Event
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
