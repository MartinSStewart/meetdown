module Evergreen.V62.GroupPage exposing (..)

import AssocList
import AssocSet
import Evergreen.V62.Description
import Evergreen.V62.Event
import Evergreen.V62.EventDuration
import Evergreen.V62.EventName
import Evergreen.V62.Group
import Evergreen.V62.GroupName
import Evergreen.V62.MaxAttendees
import Evergreen.V62.Untrusted
import Time


type ToBackend
    = ChangeGroupNameRequest (Evergreen.V62.Untrusted.Untrusted Evergreen.V62.GroupName.GroupName)
    | ChangeGroupDescriptionRequest (Evergreen.V62.Untrusted.Untrusted Evergreen.V62.Description.Description)
    | ChangeGroupVisibilityRequest Evergreen.V62.Group.GroupVisibility
    | CreateEventRequest (Evergreen.V62.Untrusted.Untrusted Evergreen.V62.EventName.EventName) (Evergreen.V62.Untrusted.Untrusted Evergreen.V62.Description.Description) (Evergreen.V62.Untrusted.Untrusted Evergreen.V62.Event.EventType) Time.Posix (Evergreen.V62.Untrusted.Untrusted Evergreen.V62.EventDuration.EventDuration) (Evergreen.V62.Untrusted.Untrusted Evergreen.V62.MaxAttendees.MaxAttendees)
    | EditEventRequest Evergreen.V62.Group.EventId (Evergreen.V62.Untrusted.Untrusted Evergreen.V62.EventName.EventName) (Evergreen.V62.Untrusted.Untrusted Evergreen.V62.Description.Description) (Evergreen.V62.Untrusted.Untrusted Evergreen.V62.Event.EventType) Time.Posix (Evergreen.V62.Untrusted.Untrusted Evergreen.V62.EventDuration.EventDuration) (Evergreen.V62.Untrusted.Untrusted Evergreen.V62.MaxAttendees.MaxAttendees)
    | JoinEventRequest Evergreen.V62.Group.EventId
    | LeaveEventRequest Evergreen.V62.Group.EventId
    | ChangeEventCancellationStatusRequest Evergreen.V62.Group.EventId Evergreen.V62.Event.CancellationStatus
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
    | MeetOnlineAndInPerson


type alias EditEvent =
    { submitStatus : SubmitStatus Evergreen.V62.Group.EditEventError
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
    | EdittingEvent Evergreen.V62.Group.EventId EditEvent


type CreateEventError
    = EventStartsInThePast
    | EventOverlapsOtherEvents (AssocSet.Set Evergreen.V62.Group.EventId)
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
    | JoinFailure Evergreen.V62.Group.JoinEventError


type SubscribeStatus
    = NotPendingSubscribe
    | PendingSubscribe
    | PendingUnsubscribe


type alias Model =
    { name : Editable Evergreen.V62.GroupName.GroupName
    , description : Editable Evergreen.V62.Description.Description
    , eventOverlay : Maybe EventOverlay
    , newEvent : NewEvent
    , pendingJoinOrLeave : AssocList.Dict Evergreen.V62.Group.EventId EventJoinOrLeaveStatus
    , showAllFutureEvents : Bool
    , pendingEventCancelOrUncancel : AssocSet.Set Evergreen.V62.Group.EventId
    , pendingToggleVisibility : Bool
    , subscribePending : SubscribeStatus
    , showAttendees : AssocSet.Set Evergreen.V62.Group.EventId
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
    | PressedLeaveEvent Evergreen.V62.Group.EventId
    | PressedJoinEvent Evergreen.V62.Group.EventId
    | PressedEditEvent Evergreen.V62.Group.EventId
    | ChangedEditEvent EditEvent
    | PressedCancelEvent
    | PressedUncancelEvent
    | PressedSubmitEditEvent
    | PressedCancelEditEvent
    | PressedMakeGroupPublic
    | PressedMakeGroupUnlisted
    | PressedDeleteGroup
    | PressedCopyPreviousEvent
    | PressedSubscribe
    | PressedUnsubscribe
    | PressedShowAttendees Evergreen.V62.Group.EventId
    | PressedHideAttendees Evergreen.V62.Group.EventId
