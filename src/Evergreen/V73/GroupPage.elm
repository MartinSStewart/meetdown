module Evergreen.V73.GroupPage exposing (..)

import Evergreen.V73.Description
import Evergreen.V73.Event
import Evergreen.V73.EventDuration
import Evergreen.V73.EventName
import Evergreen.V73.Group
import Evergreen.V73.GroupName
import Evergreen.V73.MaxAttendees
import Evergreen.V73.Untrusted
import SeqDict
import SeqSet
import Time


type ToBackend
    = ChangeGroupNameRequest (Evergreen.V73.Untrusted.Untrusted Evergreen.V73.GroupName.GroupName)
    | ChangeGroupDescriptionRequest (Evergreen.V73.Untrusted.Untrusted Evergreen.V73.Description.Description)
    | ChangeGroupVisibilityRequest Evergreen.V73.Group.GroupVisibility
    | CreateEventRequest (Evergreen.V73.Untrusted.Untrusted Evergreen.V73.EventName.EventName) (Evergreen.V73.Untrusted.Untrusted Evergreen.V73.Description.Description) (Evergreen.V73.Untrusted.Untrusted Evergreen.V73.Event.EventType) Time.Posix (Evergreen.V73.Untrusted.Untrusted Evergreen.V73.EventDuration.EventDuration) (Evergreen.V73.Untrusted.Untrusted Evergreen.V73.MaxAttendees.MaxAttendees)
    | EditEventRequest Evergreen.V73.Group.EventId (Evergreen.V73.Untrusted.Untrusted Evergreen.V73.EventName.EventName) (Evergreen.V73.Untrusted.Untrusted Evergreen.V73.Description.Description) (Evergreen.V73.Untrusted.Untrusted Evergreen.V73.Event.EventType) Time.Posix (Evergreen.V73.Untrusted.Untrusted Evergreen.V73.EventDuration.EventDuration) (Evergreen.V73.Untrusted.Untrusted Evergreen.V73.MaxAttendees.MaxAttendees)
    | JoinEventRequest Evergreen.V73.Group.EventId
    | LeaveEventRequest Evergreen.V73.Group.EventId
    | ChangeEventCancellationStatusRequest Evergreen.V73.Group.EventId Evergreen.V73.Event.CancellationStatus
    | DeleteGroupAdminRequest
    | SubscribeRequest
    | UnsubscribeRequest
    | DeleteGroupUserRequest


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
    { submitStatus : SubmitStatus Evergreen.V73.Group.EditEventError
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
    | EdittingEvent Evergreen.V73.Group.EventId EditEvent


type CreateEventError
    = EventStartsInThePast
    | EventOverlapsOtherEvents (SeqSet.SeqSet Evergreen.V73.Group.EventId)
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
    | JoinFailure Evergreen.V73.Group.JoinEventError


type SubscribeStatus
    = NotPendingSubscribe
    | PendingSubscribe
    | PendingUnsubscribe


type alias Model =
    { name : Editable Evergreen.V73.GroupName.GroupName
    , description : Editable Evergreen.V73.Description.Description
    , eventOverlay : Maybe EventOverlay
    , newEvent : NewEvent
    , pendingJoinOrLeave : SeqDict.SeqDict Evergreen.V73.Group.EventId EventJoinOrLeaveStatus
    , showAllFutureEvents : Bool
    , pendingEventCancelOrUncancel : SeqSet.SeqSet Evergreen.V73.Group.EventId
    , pendingToggleVisibility : Bool
    , subscribePending : SubscribeStatus
    , showAttendees : SeqSet.SeqSet Evergreen.V73.Group.EventId
    , showDeleteConfirm :
        Maybe
            { groupName : String
            , submitStatus : SubmitStatus ()
            }
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
    | PressedLeaveEvent Evergreen.V73.Group.EventId
    | PressedJoinEvent Evergreen.V73.Group.EventId
    | PressedEditEvent Evergreen.V73.Group.EventId
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
    | PressedShowAttendees Evergreen.V73.Group.EventId
    | PressedHideAttendees Evergreen.V73.Group.EventId
    | TypedDeleteGroup String
    | PressedConfirmDeleteGroup
