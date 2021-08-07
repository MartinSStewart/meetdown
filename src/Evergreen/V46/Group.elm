module Evergreen.V46.Group exposing (..)

import AssocList
import AssocSet
import Evergreen.V46.Description
import Evergreen.V46.Event
import Evergreen.V46.GroupName
import Evergreen.V46.Id
import Time


type EventId
    = EventId Int


type GroupVisibility
    = UnlistedGroup
    | PublicGroup


type Group
    = Group
        { ownerId : Evergreen.V46.Id.Id Evergreen.V46.Id.UserId
        , name : Evergreen.V46.GroupName.GroupName
        , description : Evergreen.V46.Description.Description
        , events : AssocList.Dict EventId Evergreen.V46.Event.Event
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
