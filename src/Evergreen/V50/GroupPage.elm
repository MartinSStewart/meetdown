module Evergreen.V50.GroupPage exposing (..)

import AssocList
import AssocSet
import Evergreen.V50.Description
import Evergreen.V50.Event
import Evergreen.V50.EventDuration
import Evergreen.V50.EventName
import Evergreen.V50.Group
import Evergreen.V50.GroupName
import Evergreen.V50.MaxAttendees
import Evergreen.V50.Untrusted
import Time


type ToBackend
    = ChangeGroupNameRequest (Evergreen.V50.Untrusted.Untrusted Evergreen.V50.GroupName.GroupName)
    | ChangeGroupDescriptionRequest (Evergreen.V50.Untrusted.Untrusted Evergreen.V50.Description.Description)
    | ChangeGroupVisibilityRequest Evergreen.V50.Group.GroupVisibility
    | CreateEventRequest (Evergreen.V50.Untrusted.Untrusted Evergreen.V50.EventName.EventName) (Evergreen.V50.Untrusted.Untrusted Evergreen.V50.Description.Description) (Evergreen.V50.Untrusted.Untrusted Evergreen.V50.Event.EventType) Time.Posix (Evergreen.V50.Untrusted.Untrusted Evergreen.V50.EventDuration.EventDuration) (Evergreen.V50.Untrusted.Untrusted Evergreen.V50.MaxAttendees.MaxAttendees)
    | EditEventRequest Evergreen.V50.Group.EventId (Evergreen.V50.Untrusted.Untrusted Evergreen.V50.EventName.EventName) (Evergreen.V50.Untrusted.Untrusted Evergreen.V50.Description.Description) (Evergreen.V50.Untrusted.Untrusted Evergreen.V50.Event.EventType) Time.Posix (Evergreen.V50.Untrusted.Untrusted Evergreen.V50.EventDuration.EventDuration) (Evergreen.V50.Untrusted.Untrusted Evergreen.V50.MaxAttendees.MaxAttendees)
    | JoinEventRequest Evergreen.V50.Group.EventId
    | LeaveEventRequest Evergreen.V50.Group.EventId
    | ChangeEventCancellationStatusRequest Evergreen.V50.Group.EventId Evergreen.V50.Event.CancellationStatus
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
    { submitStatus : SubmitStatus Evergreen.V50.Group.EditEventError
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
    | EdittingEvent Evergreen.V50.Group.EventId EditEvent


type CreateEventError
    = EventStartsInThePast
    | EventOverlapsOtherEvents (AssocSet.Set Evergreen.V50.Group.EventId)
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
    | JoinFailure Evergreen.V50.Group.JoinEventError


type SubscribeStatus
    = NotPendingSubscribe
    | PendingSubscribe
    | PendingUnsubscribe


type alias Model =
    { name : Editable Evergreen.V50.GroupName.GroupName
    , description : Editable Evergreen.V50.Description.Description
    , eventOverlay : Maybe EventOverlay
    , newEvent : NewEvent
    , pendingJoinOrLeave : AssocList.Dict Evergreen.V50.Group.EventId EventJoinOrLeaveStatus
    , showAllFutureEvents : Bool
    , pendingEventCancelOrUncancel : AssocSet.Set Evergreen.V50.Group.EventId
    , pendingToggleVisibility : Bool
    , subscribePending : SubscribeStatus
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
    | PressedLeaveEvent Evergreen.V50.Group.EventId
    | PressedJoinEvent Evergreen.V50.Group.EventId
    | PressedEditEvent Evergreen.V50.Group.EventId
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
