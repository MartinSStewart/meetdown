module Evergreen.V6.GroupPage exposing (..)

import AssocList
import AssocSet
import Evergreen.V6.Description
import Evergreen.V6.Group
import Evergreen.V6.GroupName


type Editable validated
    = Unchanged
    | Editting String
    | Submitting validated


type EventType
    = MeetOnline
    | MeetInPerson


type alias NewEvent =
    { pressedSubmit : Bool
    , isSubmitting : Bool
    , eventName : String
    , description : String
    , meetingType : Maybe EventType
    , meetOnlineLink : String
    , meetInPersonAddress : String
    , startDate : String
    , startTime : String
    , duration : String
    }


type EventJoinOrLeaveStatus
    = JoinOrLeavePending
    | JoinOrLeaveFailure


type alias Model =
    { name : Editable Evergreen.V6.GroupName.GroupName
    , description : Editable Evergreen.V6.Description.Description
    , addingNewEvent : Bool
    , newEvent : NewEvent
    , pendingJoinOrLeave : AssocList.Dict Evergreen.V6.Group.EventId EventJoinOrLeaveStatus
    }


type Msg
    = PressedEditDescription
    | PressedSaveDescription
    | PressedResetDescription
    | TypedDescription String
    | PressedEditName
    | PressedSaveName
    | PressedResetName
    | TypedName String
    | PressedAddEvent
    | ChangedNewEvent NewEvent
    | PressedCancelNewEvent
    | PressedCreateNewEvent
    | PressedLeaveEvent Evergreen.V6.Group.EventId
    | PressedJoinEvent Evergreen.V6.Group.EventId


type CreateEventError
    = EventStartsInThePast
    | EventOverlapsOtherEvents (AssocSet.Set Evergreen.V6.Group.EventId)
    | TooManyEvents
