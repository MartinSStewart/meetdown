module Evergreen.V9.GroupPage exposing (..)

import AssocList
import AssocSet
import Evergreen.V9.Description
import Evergreen.V9.Group
import Evergreen.V9.GroupName


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
    { submitStatus : SubmitStatus Evergreen.V9.Group.EditEventError
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
    | EdittingEvent Evergreen.V9.Group.EventId EditEvent


type CreateEventError
    = EventStartsInThePast
    | EventOverlapsOtherEvents (AssocSet.Set Evergreen.V9.Group.EventId)
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
    { name : Editable Evergreen.V9.GroupName.GroupName
    , description : Editable Evergreen.V9.Description.Description
    , eventOverlay : Maybe EventOverlay
    , newEvent : NewEvent
    , pendingJoinOrLeave : AssocList.Dict Evergreen.V9.Group.EventId EventJoinOrLeaveStatus
    , showAllFutureEvents : Bool
    , pendingEventCancelOrUncancel : AssocSet.Set Evergreen.V9.Group.EventId
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
    | PressedLeaveEvent Evergreen.V9.Group.EventId
    | PressedJoinEvent Evergreen.V9.Group.EventId
    | PressedEditEvent Evergreen.V9.Group.EventId
    | ChangedEditEvent EditEvent
    | PressedCancelEvent Evergreen.V9.Group.EventId
    | PressedRecancelEvent Evergreen.V9.Group.EventId
    | PressedUncancelEvent Evergreen.V9.Group.EventId
    | PressedSubmitEditEvent
    | PressedCancelEditEvent
