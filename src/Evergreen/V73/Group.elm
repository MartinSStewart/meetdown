module Evergreen.V73.Group exposing (..)

import Evergreen.V73.Description
import Evergreen.V73.Event
import Evergreen.V73.GroupName
import Evergreen.V73.Id
import SeqDict
import SeqSet
import Time


type EventId
    = EventId Int


type GroupVisibility
    = UnlistedGroup
    | PublicGroup


type Group
    = Group
        { ownerId : Evergreen.V73.Id.Id Evergreen.V73.Id.UserId
        , name : Evergreen.V73.GroupName.GroupName
        , description : Evergreen.V73.Description.Description
        , events : SeqDict.SeqDict EventId Evergreen.V73.Event.Event
        , visibility : GroupVisibility
        , eventCounter : Int
        , createdAt : Time.Posix
        , pendingReview : Bool
        }


type EditEventError
    = EditEventStartsInThePast
    | EditEventOverlapsOtherEvents (SeqSet.SeqSet EventId)
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
