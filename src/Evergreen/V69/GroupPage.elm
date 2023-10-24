module Evergreen.V69.GroupPage exposing (..)

import AssocList
import AssocSet
import Evergreen.V69.Description
import Evergreen.V69.Event
import Evergreen.V69.EventDuration
import Evergreen.V69.EventName
import Evergreen.V69.Group
import Evergreen.V69.GroupName
import Evergreen.V69.MaxAttendees
import Evergreen.V69.Untrusted
import Time


type ToBackend
    = ChangeGroupNameRequest (Evergreen.V69.Untrusted.Untrusted Evergreen.V69.GroupName.GroupName)
    | ChangeGroupDescriptionRequest (Evergreen.V69.Untrusted.Untrusted Evergreen.V69.Description.Description)
    | ChangeGroupVisibilityRequest Evergreen.V69.Group.GroupVisibility
    | CreateEventRequest (Evergreen.V69.Untrusted.Untrusted Evergreen.V69.EventName.EventName) (Evergreen.V69.Untrusted.Untrusted Evergreen.V69.Description.Description) (Evergreen.V69.Untrusted.Untrusted Evergreen.V69.Event.EventType) Time.Posix (Evergreen.V69.Untrusted.Untrusted Evergreen.V69.EventDuration.EventDuration) (Evergreen.V69.Untrusted.Untrusted Evergreen.V69.MaxAttendees.MaxAttendees)
    | EditEventRequest Evergreen.V69.Group.EventId (Evergreen.V69.Untrusted.Untrusted Evergreen.V69.EventName.EventName) (Evergreen.V69.Untrusted.Untrusted Evergreen.V69.Description.Description) (Evergreen.V69.Untrusted.Untrusted Evergreen.V69.Event.EventType) Time.Posix (Evergreen.V69.Untrusted.Untrusted Evergreen.V69.EventDuration.EventDuration) (Evergreen.V69.Untrusted.Untrusted Evergreen.V69.MaxAttendees.MaxAttendees)
    | JoinEventRequest Evergreen.V69.Group.EventId
    | LeaveEventRequest Evergreen.V69.Group.EventId
    | ChangeEventCancellationStatusRequest Evergreen.V69.Group.EventId Evergreen.V69.Event.CancellationStatus
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
    { submitStatus : SubmitStatus Evergreen.V69.Group.EditEventError
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
    | EdittingEvent Evergreen.V69.Group.EventId EditEvent


type CreateEventError
    = EventStartsInThePast
    | EventOverlapsOtherEvents (AssocSet.Set Evergreen.V69.Group.EventId)
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
    | JoinFailure Evergreen.V69.Group.JoinEventError


type SubscribeStatus
    = NotPendingSubscribe
    | PendingSubscribe
    | PendingUnsubscribe


type alias Model =
    { name : Editable Evergreen.V69.GroupName.GroupName
    , description : Editable Evergreen.V69.Description.Description
    , eventOverlay : Maybe EventOverlay
    , newEvent : NewEvent
    , pendingJoinOrLeave : AssocList.Dict Evergreen.V69.Group.EventId EventJoinOrLeaveStatus
    , showAllFutureEvents : Bool
    , pendingEventCancelOrUncancel : AssocSet.Set Evergreen.V69.Group.EventId
    , pendingToggleVisibility : Bool
    , subscribePending : SubscribeStatus
    , showAttendees : AssocSet.Set Evergreen.V69.Group.EventId
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
    | PressedLeaveEvent Evergreen.V69.Group.EventId
    | PressedJoinEvent Evergreen.V69.Group.EventId
    | PressedEditEvent Evergreen.V69.Group.EventId
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
    | PressedShowAttendees Evergreen.V69.Group.EventId
    | PressedHideAttendees Evergreen.V69.Group.EventId
    | TypedDeleteGroup String
    | PressedConfirmDeleteGroup
