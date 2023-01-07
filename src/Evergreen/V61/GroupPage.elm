module Evergreen.V61.GroupPage exposing (..)

import AssocList
import AssocSet
import Evergreen.V61.Description
import Evergreen.V61.Event
import Evergreen.V61.EventDuration
import Evergreen.V61.EventName
import Evergreen.V61.Group
import Evergreen.V61.GroupName
import Evergreen.V61.MaxAttendees
import Evergreen.V61.Untrusted
import Time


type ToBackend
    = ChangeGroupNameRequest (Evergreen.V61.Untrusted.Untrusted Evergreen.V61.GroupName.GroupName)
    | ChangeGroupDescriptionRequest (Evergreen.V61.Untrusted.Untrusted Evergreen.V61.Description.Description)
    | ChangeGroupVisibilityRequest Evergreen.V61.Group.GroupVisibility
    | CreateEventRequest (Evergreen.V61.Untrusted.Untrusted Evergreen.V61.EventName.EventName) (Evergreen.V61.Untrusted.Untrusted Evergreen.V61.Description.Description) (Evergreen.V61.Untrusted.Untrusted Evergreen.V61.Event.EventType) Time.Posix (Evergreen.V61.Untrusted.Untrusted Evergreen.V61.EventDuration.EventDuration) (Evergreen.V61.Untrusted.Untrusted Evergreen.V61.MaxAttendees.MaxAttendees)
    | EditEventRequest Evergreen.V61.Group.EventId (Evergreen.V61.Untrusted.Untrusted Evergreen.V61.EventName.EventName) (Evergreen.V61.Untrusted.Untrusted Evergreen.V61.Description.Description) (Evergreen.V61.Untrusted.Untrusted Evergreen.V61.Event.EventType) Time.Posix (Evergreen.V61.Untrusted.Untrusted Evergreen.V61.EventDuration.EventDuration) (Evergreen.V61.Untrusted.Untrusted Evergreen.V61.MaxAttendees.MaxAttendees)
    | JoinEventRequest Evergreen.V61.Group.EventId
    | LeaveEventRequest Evergreen.V61.Group.EventId
    | ChangeEventCancellationStatusRequest Evergreen.V61.Group.EventId Evergreen.V61.Event.CancellationStatus
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
    { submitStatus : SubmitStatus Evergreen.V61.Group.EditEventError
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
    | EdittingEvent Evergreen.V61.Group.EventId EditEvent


type CreateEventError
    = EventStartsInThePast
    | EventOverlapsOtherEvents (AssocSet.Set Evergreen.V61.Group.EventId)
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
    | JoinFailure Evergreen.V61.Group.JoinEventError


type SubscribeStatus
    = NotPendingSubscribe
    | PendingSubscribe
    | PendingUnsubscribe


type alias Model =
    { name : Editable Evergreen.V61.GroupName.GroupName
    , description : Editable Evergreen.V61.Description.Description
    , eventOverlay : Maybe EventOverlay
    , newEvent : NewEvent
    , pendingJoinOrLeave : AssocList.Dict Evergreen.V61.Group.EventId EventJoinOrLeaveStatus
    , showAllFutureEvents : Bool
    , pendingEventCancelOrUncancel : AssocSet.Set Evergreen.V61.Group.EventId
    , pendingToggleVisibility : Bool
    , subscribePending : SubscribeStatus
    , showAttendees : AssocSet.Set Evergreen.V61.Group.EventId
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
    | PressedLeaveEvent Evergreen.V61.Group.EventId
    | PressedJoinEvent Evergreen.V61.Group.EventId
    | PressedEditEvent Evergreen.V61.Group.EventId
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
    | PressedShowAttendees Evergreen.V61.Group.EventId
    | PressedHideAttendees Evergreen.V61.Group.EventId
