module Evergreen.V74.GroupPage exposing (..)

import Evergreen.V74.Description
import Evergreen.V74.Event
import Evergreen.V74.EventDuration
import Evergreen.V74.EventName
import Evergreen.V74.Group
import Evergreen.V74.GroupName
import Evergreen.V74.MaxAttendees
import Evergreen.V74.Untrusted
import SeqDict
import SeqSet
import Time


type ToBackend
    = ChangeGroupNameRequest (Evergreen.V74.Untrusted.Untrusted Evergreen.V74.GroupName.GroupName)
    | ChangeGroupDescriptionRequest (Evergreen.V74.Untrusted.Untrusted Evergreen.V74.Description.Description)
    | ChangeGroupVisibilityRequest Evergreen.V74.Group.GroupVisibility
    | CreateEventRequest (Evergreen.V74.Untrusted.Untrusted Evergreen.V74.EventName.EventName) (Evergreen.V74.Untrusted.Untrusted Evergreen.V74.Description.Description) (Evergreen.V74.Untrusted.Untrusted Evergreen.V74.Event.EventType) Time.Posix (Evergreen.V74.Untrusted.Untrusted Evergreen.V74.EventDuration.EventDuration) (Evergreen.V74.Untrusted.Untrusted Evergreen.V74.MaxAttendees.MaxAttendees)
    | EditEventRequest Evergreen.V74.Group.EventId (Evergreen.V74.Untrusted.Untrusted Evergreen.V74.EventName.EventName) (Evergreen.V74.Untrusted.Untrusted Evergreen.V74.Description.Description) (Evergreen.V74.Untrusted.Untrusted Evergreen.V74.Event.EventType) Time.Posix (Evergreen.V74.Untrusted.Untrusted Evergreen.V74.EventDuration.EventDuration) (Evergreen.V74.Untrusted.Untrusted Evergreen.V74.MaxAttendees.MaxAttendees)
    | JoinEventRequest Evergreen.V74.Group.EventId
    | LeaveEventRequest Evergreen.V74.Group.EventId
    | ChangeEventCancellationStatusRequest Evergreen.V74.Group.EventId Evergreen.V74.Event.CancellationStatus
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
    { submitStatus : SubmitStatus Evergreen.V74.Group.EditEventError
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
    | EdittingEvent Evergreen.V74.Group.EventId EditEvent


type CreateEventError
    = EventStartsInThePast
    | EventOverlapsOtherEvents (SeqSet.SeqSet Evergreen.V74.Group.EventId)
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
    | JoinFailure Evergreen.V74.Group.JoinEventError


type SubscribeStatus
    = NotPendingSubscribe
    | PendingSubscribe
    | PendingUnsubscribe


type alias Model =
    { name : Editable Evergreen.V74.GroupName.GroupName
    , description : Editable Evergreen.V74.Description.Description
    , eventOverlay : Maybe EventOverlay
    , newEvent : NewEvent
    , pendingJoinOrLeave : SeqDict.SeqDict Evergreen.V74.Group.EventId EventJoinOrLeaveStatus
    , showAllFutureEvents : Bool
    , pendingEventCancelOrUncancel : SeqSet.SeqSet Evergreen.V74.Group.EventId
    , pendingToggleVisibility : Bool
    , subscribePending : SubscribeStatus
    , showAttendees : SeqSet.SeqSet Evergreen.V74.Group.EventId
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
    | PressedLeaveEvent Evergreen.V74.Group.EventId
    | PressedJoinEvent Evergreen.V74.Group.EventId
    | PressedEditEvent Evergreen.V74.Group.EventId
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
    | PressedShowAttendees Evergreen.V74.Group.EventId
    | PressedHideAttendees Evergreen.V74.Group.EventId
    | TypedDeleteGroup String
    | PressedConfirmDeleteGroup
