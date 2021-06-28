module Evergreen.V37.GroupPage exposing (..)

import AssocList
import AssocSet
import Evergreen.V37.Description
import Evergreen.V37.Group
import Evergreen.V37.GroupName


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
    { submitStatus : SubmitStatus Evergreen.V37.Group.EditEventError
    , eventName : String
    , description : String
    , meetingType : EventType
    , meetOnlineLink : String
    , meetInPersonAddress : String
    , startDate : String
    , startTime : String
    , duration : String
    , maxAttendees : String
    }


type EventOverlay
    = AddingNewEvent
    | EdittingEvent Evergreen.V37.Group.EventId EditEvent


type CreateEventError
    = EventStartsInThePast
    | EventOverlapsOtherEvents (AssocSet.Set Evergreen.V37.Group.EventId)
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
    , maxAttendees : String
    }


type EventJoinOrLeaveStatus
    = JoinOrLeavePending
    | LeaveFailure
    | JoinFailure Evergreen.V37.Group.JoinEventError


type alias Model =
    { name : Editable Evergreen.V37.GroupName.GroupName
    , description : Editable Evergreen.V37.Description.Description
    , eventOverlay : Maybe EventOverlay
    , newEvent : NewEvent
    , pendingJoinOrLeave : AssocList.Dict Evergreen.V37.Group.EventId EventJoinOrLeaveStatus
    , showAllFutureEvents : Bool
    , pendingEventCancelOrUncancel : AssocSet.Set Evergreen.V37.Group.EventId
    , pendingToggleVisibility : Bool
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
    | PressedLeaveEvent Evergreen.V37.Group.EventId
    | PressedJoinEvent Evergreen.V37.Group.EventId
    | PressedEditEvent Evergreen.V37.Group.EventId
    | ChangedEditEvent EditEvent
    | PressedCancelEvent
    | PressedRecancelEvent
    | PressedUncancelEvent
    | PressedSubmitEditEvent
    | PressedCancelEditEvent
    | PressedMakeGroupPublic
    | PressedMakeGroupUnlisted
    | PressedDeleteGroup
