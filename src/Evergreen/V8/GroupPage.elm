module Evergreen.V8.GroupPage exposing (..)

import AssocList
import AssocSet
import Evergreen.V8.Description
import Evergreen.V8.Group
import Evergreen.V8.GroupName


type Editable validated
    = Unchanged
    | Editting String
    | Submitting validated


type SubmitStatus error
    = NotSubmitted
        { pressedSubmit : Bool
        }
    | IsSubmitting
    | Failed error


type EventType
    = MeetOnline
    | MeetInPerson


type alias EditEvent =
    { submitStatus : SubmitStatus Evergreen.V8.Group.EditEventError
    , eventName : String
    , description : String
    , meetingType : EventType
    , meetOnlineLink : String
    , meetInPersonAddress : String
    , startDate : String
    , startTime : String
    , duration : String
    }


type EventOverlay
    = AddingNewEvent
    | EdittingEvent Evergreen.V8.Group.EventId EditEvent


type CreateEventError
    = EventStartsInThePast
    | EventOverlapsOtherEvents (AssocSet.Set Evergreen.V8.Group.EventId)
    | TooManyEvents


type alias NewEvent =
    { submitStatus : SubmitStatus CreateEventError
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
    { name : Editable Evergreen.V8.GroupName.GroupName
    , description : Editable Evergreen.V8.Description.Description
    , eventOverlay : Maybe EventOverlay
    , newEvent : NewEvent
    , pendingJoinOrLeave : AssocList.Dict Evergreen.V8.Group.EventId EventJoinOrLeaveStatus
    , showAllFutureEvents : Bool
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
    | PressedShowAllFutureEvents
    | PressedShowFirstFutureEvents
    | ChangedNewEvent NewEvent
    | PressedCancelNewEvent
    | PressedCreateNewEvent
    | PressedLeaveEvent Evergreen.V8.Group.EventId
    | PressedJoinEvent Evergreen.V8.Group.EventId
    | PressedEditEvent Evergreen.V8.Group.EventId
    | ChangedEditEvent EditEvent
    | PressedSubmitEditEvent
    | PressedCancelEditEvent
