module Evergreen.V49.GroupPage exposing (..)

import AssocList
import AssocSet
import Evergreen.V49.Description
import Evergreen.V49.Event
import Evergreen.V49.EventDuration
import Evergreen.V49.EventName
import Evergreen.V49.Group
import Evergreen.V49.GroupName
import Evergreen.V49.MaxAttendees
import Evergreen.V49.Untrusted
import Time


type ToBackend
    = ChangeGroupNameRequest (Evergreen.V49.Untrusted.Untrusted Evergreen.V49.GroupName.GroupName)
    | ChangeGroupDescriptionRequest (Evergreen.V49.Untrusted.Untrusted Evergreen.V49.Description.Description)
    | ChangeGroupVisibilityRequest Evergreen.V49.Group.GroupVisibility
    | CreateEventRequest (Evergreen.V49.Untrusted.Untrusted Evergreen.V49.EventName.EventName) (Evergreen.V49.Untrusted.Untrusted Evergreen.V49.Description.Description) (Evergreen.V49.Untrusted.Untrusted Evergreen.V49.Event.EventType) Time.Posix (Evergreen.V49.Untrusted.Untrusted Evergreen.V49.EventDuration.EventDuration) (Evergreen.V49.Untrusted.Untrusted Evergreen.V49.MaxAttendees.MaxAttendees)
    | EditEventRequest Evergreen.V49.Group.EventId (Evergreen.V49.Untrusted.Untrusted Evergreen.V49.EventName.EventName) (Evergreen.V49.Untrusted.Untrusted Evergreen.V49.Description.Description) (Evergreen.V49.Untrusted.Untrusted Evergreen.V49.Event.EventType) Time.Posix (Evergreen.V49.Untrusted.Untrusted Evergreen.V49.EventDuration.EventDuration) (Evergreen.V49.Untrusted.Untrusted Evergreen.V49.MaxAttendees.MaxAttendees)
    | JoinEventRequest Evergreen.V49.Group.EventId
    | LeaveEventRequest Evergreen.V49.Group.EventId
    | ChangeEventCancellationStatusRequest Evergreen.V49.Group.EventId Evergreen.V49.Event.CancellationStatus
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
    { submitStatus : SubmitStatus Evergreen.V49.Group.EditEventError
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
    | EdittingEvent Evergreen.V49.Group.EventId EditEvent


type CreateEventError
    = EventStartsInThePast
    | EventOverlapsOtherEvents (AssocSet.Set Evergreen.V49.Group.EventId)
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
    | JoinFailure Evergreen.V49.Group.JoinEventError


type alias Model =
    { name : Editable Evergreen.V49.GroupName.GroupName
    , description : Editable Evergreen.V49.Description.Description
    , eventOverlay : Maybe EventOverlay
    , newEvent : NewEvent
    , pendingJoinOrLeave : AssocList.Dict Evergreen.V49.Group.EventId EventJoinOrLeaveStatus
    , showAllFutureEvents : Bool
    , pendingEventCancelOrUncancel : AssocSet.Set Evergreen.V49.Group.EventId
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
    | PressedLeaveEvent Evergreen.V49.Group.EventId
    | PressedJoinEvent Evergreen.V49.Group.EventId
    | PressedEditEvent Evergreen.V49.Group.EventId
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
