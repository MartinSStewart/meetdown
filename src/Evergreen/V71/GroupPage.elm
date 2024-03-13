module Evergreen.V71.GroupPage exposing (..)

import AssocList
import AssocSet
import Evergreen.V71.Description
import Evergreen.V71.Event
import Evergreen.V71.EventDuration
import Evergreen.V71.EventName
import Evergreen.V71.Group
import Evergreen.V71.GroupName
import Evergreen.V71.MaxAttendees
import Evergreen.V71.Untrusted
import Time


type ToBackend
    = ChangeGroupNameRequest (Evergreen.V71.Untrusted.Untrusted Evergreen.V71.GroupName.GroupName)
    | ChangeGroupDescriptionRequest (Evergreen.V71.Untrusted.Untrusted Evergreen.V71.Description.Description)
    | ChangeGroupVisibilityRequest Evergreen.V71.Group.GroupVisibility
    | CreateEventRequest (Evergreen.V71.Untrusted.Untrusted Evergreen.V71.EventName.EventName) (Evergreen.V71.Untrusted.Untrusted Evergreen.V71.Description.Description) (Evergreen.V71.Untrusted.Untrusted Evergreen.V71.Event.EventType) Time.Posix (Evergreen.V71.Untrusted.Untrusted Evergreen.V71.EventDuration.EventDuration) (Evergreen.V71.Untrusted.Untrusted Evergreen.V71.MaxAttendees.MaxAttendees)
    | EditEventRequest Evergreen.V71.Group.EventId (Evergreen.V71.Untrusted.Untrusted Evergreen.V71.EventName.EventName) (Evergreen.V71.Untrusted.Untrusted Evergreen.V71.Description.Description) (Evergreen.V71.Untrusted.Untrusted Evergreen.V71.Event.EventType) Time.Posix (Evergreen.V71.Untrusted.Untrusted Evergreen.V71.EventDuration.EventDuration) (Evergreen.V71.Untrusted.Untrusted Evergreen.V71.MaxAttendees.MaxAttendees)
    | JoinEventRequest Evergreen.V71.Group.EventId
    | LeaveEventRequest Evergreen.V71.Group.EventId
    | ChangeEventCancellationStatusRequest Evergreen.V71.Group.EventId Evergreen.V71.Event.CancellationStatus
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
    { submitStatus : SubmitStatus Evergreen.V71.Group.EditEventError
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
    | EdittingEvent Evergreen.V71.Group.EventId EditEvent


type CreateEventError
    = EventStartsInThePast
    | EventOverlapsOtherEvents (AssocSet.Set Evergreen.V71.Group.EventId)
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
    | JoinFailure Evergreen.V71.Group.JoinEventError


type SubscribeStatus
    = NotPendingSubscribe
    | PendingSubscribe
    | PendingUnsubscribe


type alias Model =
    { name : Editable Evergreen.V71.GroupName.GroupName
    , description : Editable Evergreen.V71.Description.Description
    , eventOverlay : Maybe EventOverlay
    , newEvent : NewEvent
    , pendingJoinOrLeave : AssocList.Dict Evergreen.V71.Group.EventId EventJoinOrLeaveStatus
    , showAllFutureEvents : Bool
    , pendingEventCancelOrUncancel : AssocSet.Set Evergreen.V71.Group.EventId
    , pendingToggleVisibility : Bool
    , subscribePending : SubscribeStatus
    , showAttendees : AssocSet.Set Evergreen.V71.Group.EventId
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
    | PressedLeaveEvent Evergreen.V71.Group.EventId
    | PressedJoinEvent Evergreen.V71.Group.EventId
    | PressedEditEvent Evergreen.V71.Group.EventId
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
    | PressedShowAttendees Evergreen.V71.Group.EventId
    | PressedHideAttendees Evergreen.V71.Group.EventId
    | TypedDeleteGroup String
    | PressedConfirmDeleteGroup
