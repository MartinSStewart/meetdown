module Evergreen.V48.GroupPage exposing (..)

import AssocList
import AssocSet
import Evergreen.V48.Description
import Evergreen.V48.Event
import Evergreen.V48.EventDuration
import Evergreen.V48.EventName
import Evergreen.V48.Group
import Evergreen.V48.GroupName
import Evergreen.V48.MaxAttendees
import Evergreen.V48.Untrusted
import Time


type ToBackend
    = ChangeGroupNameRequest (Evergreen.V48.Untrusted.Untrusted Evergreen.V48.GroupName.GroupName)
    | ChangeGroupDescriptionRequest (Evergreen.V48.Untrusted.Untrusted Evergreen.V48.Description.Description)
    | ChangeGroupVisibilityRequest Evergreen.V48.Group.GroupVisibility
    | CreateEventRequest (Evergreen.V48.Untrusted.Untrusted Evergreen.V48.EventName.EventName) (Evergreen.V48.Untrusted.Untrusted Evergreen.V48.Description.Description) (Evergreen.V48.Untrusted.Untrusted Evergreen.V48.Event.EventType) Time.Posix (Evergreen.V48.Untrusted.Untrusted Evergreen.V48.EventDuration.EventDuration) (Evergreen.V48.Untrusted.Untrusted Evergreen.V48.MaxAttendees.MaxAttendees)
    | EditEventRequest Evergreen.V48.Group.EventId (Evergreen.V48.Untrusted.Untrusted Evergreen.V48.EventName.EventName) (Evergreen.V48.Untrusted.Untrusted Evergreen.V48.Description.Description) (Evergreen.V48.Untrusted.Untrusted Evergreen.V48.Event.EventType) Time.Posix (Evergreen.V48.Untrusted.Untrusted Evergreen.V48.EventDuration.EventDuration) (Evergreen.V48.Untrusted.Untrusted Evergreen.V48.MaxAttendees.MaxAttendees)
    | JoinEventRequest Evergreen.V48.Group.EventId
    | LeaveEventRequest Evergreen.V48.Group.EventId
    | ChangeEventCancellationStatusRequest Evergreen.V48.Group.EventId Evergreen.V48.Event.CancellationStatus
    | DeleteGroupAdminRequest


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
    { submitStatus : SubmitStatus Evergreen.V48.Group.EditEventError
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
    | EdittingEvent Evergreen.V48.Group.EventId EditEvent


type CreateEventError
    = EventStartsInThePast
    | EventOverlapsOtherEvents (AssocSet.Set Evergreen.V48.Group.EventId)
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
    | JoinFailure Evergreen.V48.Group.JoinEventError


type alias Model =
    { name : Editable Evergreen.V48.GroupName.GroupName
    , description : Editable Evergreen.V48.Description.Description
    , eventOverlay : Maybe EventOverlay
    , newEvent : NewEvent
    , pendingJoinOrLeave : AssocList.Dict Evergreen.V48.Group.EventId EventJoinOrLeaveStatus
    , showAllFutureEvents : Bool
    , pendingEventCancelOrUncancel : AssocSet.Set Evergreen.V48.Group.EventId
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
    | PressedLeaveEvent Evergreen.V48.Group.EventId
    | PressedJoinEvent Evergreen.V48.Group.EventId
    | PressedEditEvent Evergreen.V48.Group.EventId
    | ChangedEditEvent EditEvent
    | PressedCancelEvent
    | PressedRecancelEvent
    | PressedUncancelEvent
    | PressedSubmitEditEvent
    | PressedCancelEditEvent
    | PressedMakeGroupPublic
    | PressedMakeGroupUnlisted
    | PressedDeleteGroup
    | PressedCopyPreviousEvent
