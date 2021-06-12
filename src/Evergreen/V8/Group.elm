module Evergreen.V8.Group exposing (..)

import AssocList
import AssocSet
import Evergreen.V8.Description
import Evergreen.V8.Event
import Evergreen.V8.GroupName
import Evergreen.V8.Id
import Time


type GroupVisibility
    = UnlistedGroup
    | PublicGroup


type EventId
    = EventId Int


type Group
    = Group
        { ownerId : Evergreen.V8.Id.Id Evergreen.V8.Id.UserId
        , name : Evergreen.V8.GroupName.GroupName
        , description : Evergreen.V8.Description.Description
        , events : AssocList.Dict EventId Evergreen.V8.Event.Event
        , visibility : GroupVisibility
        , eventCounter : Int
        , createdAt : Time.Posix
        }


type EditEventError
    = EditEventStartsInThePast
    | EditEventOverlapsOtherEvents (AssocSet.Set EventId)
    | CantEditPastEvent
    | CantChangeStartTimeOfOngoingEvent
    | EditEventNotFound
