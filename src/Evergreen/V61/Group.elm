module Evergreen.V61.Group exposing (..)

import AssocList
import AssocSet
import Evergreen.V61.Description
import Evergreen.V61.Event
import Evergreen.V61.GroupName
import Evergreen.V61.Id
import Time


type EventId
    = EventId Int


type GroupVisibility
    = UnlistedGroup
    | PublicGroup


type Group
    = Group
        { ownerId : Evergreen.V61.Id.Id Evergreen.V61.Id.UserId
        , name : Evergreen.V61.GroupName.GroupName
        , description : Evergreen.V61.Description.Description
        , events : AssocList.Dict EventId Evergreen.V61.Event.Event
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
