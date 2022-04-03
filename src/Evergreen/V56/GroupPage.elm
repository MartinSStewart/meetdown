module Evergreen.V56.GroupPage exposing (..)

import AssocList
import AssocSet
import Evergreen.V56.Description
import Evergreen.V56.Event
import Evergreen.V56.EventDuration
import Evergreen.V56.EventName
import Evergreen.V56.Group
import Evergreen.V56.GroupName
import Evergreen.V56.MaxAttendees
import Evergreen.V56.Untrusted
import Time


type ToBackend
    = ChangeGroupNameRequest (Evergreen.V56.Untrusted.Untrusted Evergreen.V56.GroupName.GroupName)
    | ChangeGroupDescriptionRequest (Evergreen.V56.Untrusted.Untrusted Evergreen.V56.Description.Description)
    | ChangeGroupVisibilityRequest Evergreen.V56.Group.GroupVisibility
    | CreateEventRequest (Evergreen.V56.Untrusted.Untrusted Evergreen.V56.EventName.EventName) (Evergreen.V56.Untrusted.Untrusted Evergreen.V56.Description.Description) (Evergreen.V56.Untrusted.Untrusted Evergreen.V56.Event.EventType) Time.Posix (Evergreen.V56.Untrusted.Untrusted Evergreen.V56.EventDuration.EventDuration) (Evergreen.V56.Untrusted.Untrusted Evergreen.V56.MaxAttendees.MaxAttendees)
    | EditEventRequest Evergreen.V56.Group.EventId (Evergreen.V56.Untrusted.Untrusted Evergreen.V56.EventName.EventName) (Evergreen.V56.Untrusted.Untrusted Evergreen.V56.Description.Description) (Evergreen.V56.Untrusted.Untrusted Evergreen.V56.Event.EventType) Time.Posix (Evergreen.V56.Untrusted.Untrusted Evergreen.V56.EventDuration.EventDuration) (Evergreen.V56.Untrusted.Untrusted Evergreen.V56.MaxAttendees.MaxAttendees)
    | JoinEventRequest Evergreen.V56.Group.EventId
    | LeaveEventRequest Evergreen.V56.Group.EventId
    | ChangeEventCancellationStatusRequest Evergreen.V56.Group.EventId Evergreen.V56.Event.CancellationStatus
    | DeleteGroupAdminRequest
    | SubscribeRequest
    | UnsubscribeRequest


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
    { submitStatus : SubmitStatus Evergreen.V56.Group.EditEventError
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
    | EdittingEvent Evergreen.V56.Group.EventId EditEvent


type CreateEventError
    = EventStartsInThePast
    | EventOverlapsOtherEvents (AssocSet.Set Evergreen.V56.Group.EventId)
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
    | JoinFailure Evergreen.V56.Group.JoinEventError


type SubscribeStatus
    = NotPendingSubscribe
    | PendingSubscribe
    | PendingUnsubscribe


type alias Model =
    { name : Editable Evergreen.V56.GroupName.GroupName
    , description : Editable Evergreen.V56.Description.Description
    , eventOverlay : Maybe EventOverlay
    , newEvent : NewEvent
    , pendingJoinOrLeave : AssocList.Dict Evergreen.V56.Group.EventId EventJoinOrLeaveStatus
    , showAllFutureEvents : Bool
    , pendingEventCancelOrUncancel : AssocSet.Set Evergreen.V56.Group.EventId
    , pendingToggleVisibility : Bool
    , subscribePending : SubscribeStatus
    , showAttendees : AssocSet.Set Evergreen.V56.Group.EventId
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
    | PressedLeaveEvent Evergreen.V56.Group.EventId
    | PressedJoinEvent Evergreen.V56.Group.EventId
    | PressedEditEvent Evergreen.V56.Group.EventId
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
    | PressedSubscribe
    | PressedUnsubscribe
    | PressedShowAttendees Evergreen.V56.Group.EventId
    | PressedHideAttendees Evergreen.V56.Group.EventId
