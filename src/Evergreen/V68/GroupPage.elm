module Evergreen.V68.GroupPage exposing (..)

import AssocList
import AssocSet
import Evergreen.V68.Description
import Evergreen.V68.Event
import Evergreen.V68.EventDuration
import Evergreen.V68.EventName
import Evergreen.V68.Group
import Evergreen.V68.GroupName
import Evergreen.V68.MaxAttendees
import Evergreen.V68.Untrusted
import Time


type ToBackend
    = ChangeGroupNameRequest (Evergreen.V68.Untrusted.Untrusted Evergreen.V68.GroupName.GroupName)
    | ChangeGroupDescriptionRequest (Evergreen.V68.Untrusted.Untrusted Evergreen.V68.Description.Description)
    | ChangeGroupVisibilityRequest Evergreen.V68.Group.GroupVisibility
    | CreateEventRequest (Evergreen.V68.Untrusted.Untrusted Evergreen.V68.EventName.EventName) (Evergreen.V68.Untrusted.Untrusted Evergreen.V68.Description.Description) (Evergreen.V68.Untrusted.Untrusted Evergreen.V68.Event.EventType) Time.Posix (Evergreen.V68.Untrusted.Untrusted Evergreen.V68.EventDuration.EventDuration) (Evergreen.V68.Untrusted.Untrusted Evergreen.V68.MaxAttendees.MaxAttendees)
    | EditEventRequest Evergreen.V68.Group.EventId (Evergreen.V68.Untrusted.Untrusted Evergreen.V68.EventName.EventName) (Evergreen.V68.Untrusted.Untrusted Evergreen.V68.Description.Description) (Evergreen.V68.Untrusted.Untrusted Evergreen.V68.Event.EventType) Time.Posix (Evergreen.V68.Untrusted.Untrusted Evergreen.V68.EventDuration.EventDuration) (Evergreen.V68.Untrusted.Untrusted Evergreen.V68.MaxAttendees.MaxAttendees)
    | JoinEventRequest Evergreen.V68.Group.EventId
    | LeaveEventRequest Evergreen.V68.Group.EventId
    | ChangeEventCancellationStatusRequest Evergreen.V68.Group.EventId Evergreen.V68.Event.CancellationStatus
    | DeleteGroupAdminRequest
    | SubscribeRequest
    | UnsubscribeRequest


type Editable validated
    = Unchanged
    | Editing String
    | Submiting validated


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
    { submitStatus : SubmitStatus Evergreen.V68.Group.EditEventError
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
    | EdittingEvent Evergreen.V68.Group.EventId EditEvent


type CreateEventError
    = EventStartsInThePast
    | EventOverlapsOtherEvents (AssocSet.Set Evergreen.V68.Group.EventId)
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
    | JoinFailure Evergreen.V68.Group.JoinEventError


type SubscribeStatus
    = NotPendingSubscribe
    | PendingSubscribe
    | PendingUnsubscribe


type alias Model =
    { name : Editable Evergreen.V68.GroupName.GroupName
    , description : Editable Evergreen.V68.Description.Description
    , eventOverlay : Maybe EventOverlay
    , newEvent : NewEvent
    , pendingJoinOrLeave : AssocList.Dict Evergreen.V68.Group.EventId EventJoinOrLeaveStatus
    , showAllFutureEvents : Bool
    , pendingEventCancelOrUncancel : AssocSet.Set Evergreen.V68.Group.EventId
    , pendingToggleVisibility : Bool
    , subscribePending : SubscribeStatus
    , showAttendees : AssocSet.Set Evergreen.V68.Group.EventId
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
    | PressedLeaveEvent Evergreen.V68.Group.EventId
    | PressedJoinEvent Evergreen.V68.Group.EventId
    | PressedEditEvent Evergreen.V68.Group.EventId
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
    | PressedShowAttendees Evergreen.V68.Group.EventId
    | PressedHideAttendees Evergreen.V68.Group.EventId
