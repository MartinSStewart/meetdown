module Evergreen.V1.GroupPage exposing (..)

import Evergreen.V1.Description
import Evergreen.V1.GroupName


type Editable validated
    = Unchanged
    | Editting String
    | Submitting validated


type EventType
    = MeetOnline
    | MeetInPerson


type alias NewEvent =
    { pressedSubmit : Bool
    , isSubmitting : Bool
    , eventName : String
    , description : String
    , meetingType : Maybe EventType
    , meetOnlineLink : String
    , meetInPersonAddress : String
    , startDate : String
    , startTime : String
    , duration : String
    }


type alias Model =
    { name : Editable Evergreen.V1.GroupName.GroupName
    , description : Editable Evergreen.V1.Description.Description
    , addingNewEvent : Bool
    , newEvent : NewEvent
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
    | ChangedNewEvent NewEvent
    | PressedCancelNewEvent
    | PressedCreateNewEvent


type CreateEventError
    = EventStartsInThePast
    | EventOverlapsAnotherEvent
    | TooManyEvents
