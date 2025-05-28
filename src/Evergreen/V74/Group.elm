module Evergreen.V74.Group exposing (..)

import Evergreen.V74.Description
import Evergreen.V74.Event
import Evergreen.V74.GroupName
import Evergreen.V74.Id
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
        { ownerId : Evergreen.V74.Id.Id Evergreen.V74.Id.UserId
        , name : Evergreen.V74.GroupName.GroupName
        , description : Evergreen.V74.Description.Description
        , events : SeqDict.SeqDict EventId Evergreen.V74.Event.Event
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
