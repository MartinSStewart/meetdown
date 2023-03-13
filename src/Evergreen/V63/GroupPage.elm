module Evergreen.V63.GroupPage exposing (..)

import AssocList
import AssocSet
import Evergreen.V63.Description
import Evergreen.V63.Event
import Evergreen.V63.EventDuration
import Evergreen.V63.EventName
import Evergreen.V63.Group
import Evergreen.V63.GroupName
import Evergreen.V63.MaxAttendees
import Evergreen.V63.Untrusted
import Time


type ToBackend
    = ChangeGroupNameRequest (Evergreen.V63.Untrusted.Untrusted Evergreen.V63.GroupName.GroupName)
    | ChangeGroupDescriptionRequest (Evergreen.V63.Untrusted.Untrusted Evergreen.V63.Description.Description)
    | ChangeGroupVisibilityRequest Evergreen.V63.Group.GroupVisibility
    | CreateEventRequest (Evergreen.V63.Untrusted.Untrusted Evergreen.V63.EventName.EventName) (Evergreen.V63.Untrusted.Untrusted Evergreen.V63.Description.Description) (Evergreen.V63.Untrusted.Untrusted Evergreen.V63.Event.EventType) Time.Posix (Evergreen.V63.Untrusted.Untrusted Evergreen.V63.EventDuration.EventDuration) (Evergreen.V63.Untrusted.Untrusted Evergreen.V63.MaxAttendees.MaxAttendees)
    | EditEventRequest Evergreen.V63.Group.EventId (Evergreen.V63.Untrusted.Untrusted Evergreen.V63.EventName.EventName) (Evergreen.V63.Untrusted.Untrusted Evergreen.V63.Description.Description) (Evergreen.V63.Untrusted.Untrusted Evergreen.V63.Event.EventType) Time.Posix (Evergreen.V63.Untrusted.Untrusted Evergreen.V63.EventDuration.EventDuration) (Evergreen.V63.Untrusted.Untrusted Evergreen.V63.MaxAttendees.MaxAttendees)
    | JoinEventRequest Evergreen.V63.Group.EventId
    | LeaveEventRequest Evergreen.V63.Group.EventId
    | ChangeEventCancellationStatusRequest Evergreen.V63.Group.EventId Evergreen.V63.Event.CancellationStatus
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
    { submitStatus : SubmitStatus Evergreen.V63.Group.EditEventError
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
    | EdittingEvent Evergreen.V63.Group.EventId EditEvent


type CreateEventError
    = EventStartsInThePast
    | EventOverlapsOtherEvents (AssocSet.Set Evergreen.V63.Group.EventId)
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
    | JoinFailure Evergreen.V63.Group.JoinEventError


type SubscribeStatus
    = NotPendingSubscribe
    | PendingSubscribe
    | PendingUnsubscribe


type alias Model =
    { name : Editable Evergreen.V63.GroupName.GroupName
    , description : Editable Evergreen.V63.Description.Description
    , eventOverlay : Maybe EventOverlay
    , newEvent : NewEvent
    , pendingJoinOrLeave : AssocList.Dict Evergreen.V63.Group.EventId EventJoinOrLeaveStatus
    , showAllFutureEvents : Bool
    , pendingEventCancelOrUncancel : AssocSet.Set Evergreen.V63.Group.EventId
    , pendingToggleVisibility : Bool
    , subscribePending : SubscribeStatus
    , showAttendees : AssocSet.Set Evergreen.V63.Group.EventId
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
    | PressedLeaveEvent Evergreen.V63.Group.EventId
    | PressedJoinEvent Evergreen.V63.Group.EventId
    | PressedEditEvent Evergreen.V63.Group.EventId
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
    | PressedShowAttendees Evergreen.V63.Group.EventId
    | PressedHideAttendees Evergreen.V63.Group.EventId
