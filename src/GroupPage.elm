module GroupPage exposing (CreateEventError(..), EventType(..), Model, Msg, addedNewEvent, createEventCancelId, createEventStartDateId, createEventStartTimeId, createEventSubmitId, createNewEventId, editCancellationStatusResponse, editDescriptionId, editEventResponse, editGroupNameId, eventDescriptionInputId, eventDurationId, eventMeetingInPersonInputId, eventMeetingOnlineInputId, eventMeetingTypeId, eventNameInputId, init, joinEventButtonId, joinEventResponse, leaveEventButtonId, leaveEventResponse, resetDescriptionId, resetGroupNameId, saveDescriptionId, saveGroupNameId, savedDescription, savedName, update, view)

import Address exposing (Address, Error(..))
import AssocList as Dict exposing (Dict)
import AssocSet as Set exposing (Set)
import Colors exposing (..)
import Date
import Description exposing (Description)
import Duration exposing (Duration)
import Element exposing (Element)
import Element.Background
import Element.Border
import Element.Font
import Element.Input
import Element.Region
import Event exposing (Event, EventType)
import EventDuration exposing (EventDuration)
import EventName exposing (EventName)
import FrontendUser exposing (FrontendUser)
import Group exposing (EditEventError(..), EventId, Group, PastOngoingOrFuture(..))
import GroupName exposing (GroupName)
import Html.Attributes
import Id exposing (ButtonId(..), HtmlId, Id, UserId)
import Link exposing (Link)
import List.Extra as List
import List.Nonempty exposing (Nonempty(..))
import MaxAttendees exposing (Error(..))
import Name
import ProfileImage
import Quantity exposing (Quantity)
import Time
import Time.Extra as Time
import TimeExtra as Time
import Ui
import Untrusted exposing (Untrusted)


type alias Model =
    { name : Editable GroupName
    , description : Editable Description
    , eventOverlay : Maybe EventOverlay
    , newEvent : NewEvent
    , pendingJoinOrLeave : Dict EventId EventJoinOrLeaveStatus
    , showAllFutureEvents : Bool
    , pendingEventCancelOrUncancel : Set EventId
    }


type EventJoinOrLeaveStatus
    = JoinOrLeavePending
    | LeaveFailure
    | JoinFailure Group.JoinEventError


type Editable validated
    = Unchanged
    | Editting String
    | Submitting validated


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
    | PressedLeaveEvent EventId
    | PressedJoinEvent EventId
    | PressedEditEvent EventId
    | ChangedEditEvent EditEvent
    | PressedCancelEvent
    | PressedRecancelEvent
    | PressedUncancelEvent
    | PressedSubmitEditEvent
    | PressedCancelEditEvent


type alias Effects cmd =
    { none : cmd
    , changeName : Untrusted GroupName -> cmd
    , changeDescription : Untrusted Description -> cmd
    , createEvent :
        Untrusted EventName
        -> Untrusted Description
        -> Untrusted Event.EventType
        -> Time.Posix
        -> Untrusted EventDuration
        -> Untrusted MaxAttendees.MaxAttendees
        -> cmd
    , editEvent :
        EventId
        -> Untrusted EventName
        -> Untrusted Description
        -> Untrusted Event.EventType
        -> Time.Posix
        -> Untrusted EventDuration
        -> Untrusted MaxAttendees.MaxAttendees
        -> cmd
    , joinEvent : EventId -> cmd
    , leaveEvent : EventId -> cmd
    , changeCancellationStatus : EventId -> Event.CancellationStatus -> cmd
    }


type SubmitStatus error
    = NotSubmitted { pressedSubmit : Bool }
    | IsSubmitting
    | Failed error


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


type alias EditEvent =
    { submitStatus : SubmitStatus EditEventError
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


init : Model
init =
    { name = Unchanged
    , description = Unchanged
    , eventOverlay = Nothing
    , newEvent = initNewEvent
    , pendingJoinOrLeave = Dict.empty
    , showAllFutureEvents = False
    , pendingEventCancelOrUncancel = Set.empty
    }


type EventOverlay
    = AddingNewEvent
    | EdittingEvent EventId EditEvent


initNewEvent : NewEvent
initNewEvent =
    { submitStatus = NotSubmitted { pressedSubmit = False }
    , eventName = ""
    , description = ""
    , meetingType = Nothing
    , meetOnlineLink = ""
    , meetInPersonAddress = ""
    , startDate = ""
    , startTime = ""
    , duration = ""
    , maxAttendees = ""
    }


savedName : Model -> Model
savedName model =
    case model.name of
        Submitting _ ->
            { model | name = Unchanged }

        _ ->
            model


savedDescription : Model -> Model
savedDescription model =
    case model.description of
        Submitting _ ->
            { model | description = Unchanged }

        _ ->
            model


type CreateEventError
    = EventStartsInThePast
    | EventOverlapsOtherEvents (Set EventId)
    | TooManyEvents


addedNewEvent : Result CreateEventError Event -> Model -> Model
addedNewEvent result model =
    case model.eventOverlay of
        Just AddingNewEvent ->
            case result of
                Ok _ ->
                    { model | eventOverlay = Nothing, newEvent = initNewEvent }

                Err error ->
                    let
                        newEvent =
                            model.newEvent
                    in
                    { model
                        | eventOverlay = Just AddingNewEvent
                        , newEvent = { newEvent | submitStatus = Failed error }
                    }

        _ ->
            model


editEventResponse : Result EditEventError Event -> Model -> Model
editEventResponse result model =
    case model.eventOverlay of
        Just (EdittingEvent eventId editting) ->
            case result of
                Ok _ ->
                    { model | eventOverlay = Nothing, newEvent = initNewEvent }

                Err error ->
                    { model
                        | eventOverlay =
                            EdittingEvent eventId { editting | submitStatus = Failed error } |> Just
                    }

        _ ->
            model


editCancellationStatusResponse : EventId -> Result Group.EditCancellationStatusError Event.CancellationStatus -> Model -> Model
editCancellationStatusResponse eventId _ model =
    { model | pendingEventCancelOrUncancel = Set.remove eventId model.pendingEventCancelOrUncancel }


update :
    Effects cmd
    -> { a | time : Time.Posix, timezone : Time.Zone }
    -> Group
    -> Maybe (Id UserId)
    -> Msg
    -> Model
    -> ( Model, cmd, { joinEvent : Maybe EventId } )
update effects config group maybeUserId msg model =
    let
        isOwner =
            Just (Group.ownerId group) == maybeUserId
    in
    case msg of
        PressedEditName ->
            if isOwner then
                ( { model | name = Group.name group |> GroupName.toString |> Editting }
                , effects.none
                , { joinEvent = Nothing }
                )

            else
                ( model, effects.none, { joinEvent = Nothing } )

        PressedSaveName ->
            if isOwner then
                case model.name of
                    Unchanged ->
                        ( model, effects.none, { joinEvent = Nothing } )

                    Editting nameText ->
                        case GroupName.fromString nameText of
                            Ok name ->
                                ( { model | name = Submitting name }
                                , Untrusted.untrust name |> effects.changeName
                                , { joinEvent = Nothing }
                                )

                            Err _ ->
                                ( model, effects.none, { joinEvent = Nothing } )

                    Submitting _ ->
                        ( model, effects.none, { joinEvent = Nothing } )

            else
                ( model, effects.none, { joinEvent = Nothing } )

        PressedResetName ->
            if isOwner then
                ( { model | name = Unchanged }, effects.none, { joinEvent = Nothing } )

            else
                ( model, effects.none, { joinEvent = Nothing } )

        TypedName name ->
            if isOwner then
                case model.name of
                    Editting _ ->
                        ( { model | name = Editting name }, effects.none, { joinEvent = Nothing } )

                    _ ->
                        ( model, effects.none, { joinEvent = Nothing } )

            else
                ( model, effects.none, { joinEvent = Nothing } )

        PressedEditDescription ->
            if isOwner then
                ( { model | description = Group.description group |> Description.toString |> Editting }
                , effects.none
                , { joinEvent = Nothing }
                )

            else
                ( model, effects.none, { joinEvent = Nothing } )

        PressedSaveDescription ->
            if isOwner then
                case model.description of
                    Unchanged ->
                        ( model, effects.none, { joinEvent = Nothing } )

                    Editting descriptionText ->
                        case Description.fromString descriptionText of
                            Ok description ->
                                ( { model | description = Submitting description }
                                , Untrusted.untrust description |> effects.changeDescription
                                , { joinEvent = Nothing }
                                )

                            Err _ ->
                                ( model, effects.none, { joinEvent = Nothing } )

                    Submitting _ ->
                        ( model, effects.none, { joinEvent = Nothing } )

            else
                ( model, effects.none, { joinEvent = Nothing } )

        PressedResetDescription ->
            if isOwner then
                ( { model | description = Unchanged }, effects.none, { joinEvent = Nothing } )

            else
                ( model, effects.none, { joinEvent = Nothing } )

        TypedDescription description ->
            if isOwner then
                case model.description of
                    Editting _ ->
                        ( { model | description = Editting description }, effects.none, { joinEvent = Nothing } )

                    _ ->
                        ( model, effects.none, { joinEvent = Nothing } )

            else
                ( model, effects.none, { joinEvent = Nothing } )

        PressedAddEvent ->
            if isOwner && model.eventOverlay == Nothing then
                ( { model | eventOverlay = Just AddingNewEvent }, effects.none, { joinEvent = Nothing } )

            else
                ( model, effects.none, { joinEvent = Nothing } )

        PressedShowAllFutureEvents ->
            ( { model | showAllFutureEvents = True }, effects.none, { joinEvent = Nothing } )

        PressedShowFirstFutureEvents ->
            ( { model | showAllFutureEvents = False }, effects.none, { joinEvent = Nothing } )

        ChangedNewEvent newEvent ->
            if isOwner then
                ( { model | newEvent = newEvent }, effects.none, { joinEvent = Nothing } )

            else
                ( model, effects.none, { joinEvent = Nothing } )

        PressedCancelNewEvent ->
            if isOwner then
                case model.eventOverlay of
                    Just AddingNewEvent ->
                        ( { model | eventOverlay = Nothing }, effects.none, { joinEvent = Nothing } )

                    _ ->
                        ( model, effects.none, { joinEvent = Nothing } )

            else
                ( model, effects.none, { joinEvent = Nothing } )

        PressedCreateNewEvent ->
            let
                newEvent =
                    model.newEvent

                maybeEventType : Maybe Event.EventType
                maybeEventType =
                    case newEvent.meetingType of
                        Just MeetOnline ->
                            validateLink newEvent.meetOnlineLink
                                |> Result.toMaybe
                                |> Maybe.map Event.MeetOnline

                        Just MeetInPerson ->
                            validateAddress newEvent.meetInPersonAddress
                                |> Result.toMaybe
                                |> Maybe.map Event.MeetInPerson

                        Nothing ->
                            Nothing

                maybeStartTime =
                    validateDateTime config.time config.timezone newEvent.startDate newEvent.startTime
                        |> Result.toMaybe
            in
            if isOwner then
                Maybe.map5
                    (\name description eventType startTime ( duration, maxAttendees ) ->
                        ( { model | newEvent = { newEvent | submitStatus = IsSubmitting } }
                        , effects.createEvent
                            (Untrusted.untrust name)
                            (Untrusted.untrust description)
                            (Untrusted.untrust eventType)
                            startTime
                            (Untrusted.untrust duration)
                            (Untrusted.untrust maxAttendees)
                        , { joinEvent = Nothing }
                        )
                    )
                    (EventName.fromString newEvent.eventName |> Result.toMaybe)
                    (Description.fromString newEvent.description |> Result.toMaybe)
                    maybeEventType
                    maybeStartTime
                    (Maybe.map2 Tuple.pair
                        (validateDuration newEvent.duration |> Result.toMaybe)
                        (validateMaxAttendees newEvent.maxAttendees |> Result.toMaybe)
                    )
                    |> Maybe.withDefault
                        ( { model | newEvent = pressSubmit model.newEvent }
                        , effects.none
                        , { joinEvent = Nothing }
                        )

            else
                ( model, effects.none, { joinEvent = Nothing } )

        PressedLeaveEvent eventId ->
            case Dict.get eventId model.pendingJoinOrLeave of
                Just JoinOrLeavePending ->
                    ( model, effects.none, { joinEvent = Nothing } )

                _ ->
                    ( { model | pendingJoinOrLeave = Dict.insert eventId JoinOrLeavePending model.pendingJoinOrLeave }
                    , effects.leaveEvent eventId
                    , { joinEvent = Nothing }
                    )

        PressedJoinEvent eventId ->
            case maybeUserId of
                Just _ ->
                    case Dict.get eventId model.pendingJoinOrLeave of
                        Just JoinOrLeavePending ->
                            ( model, effects.none, { joinEvent = Nothing } )

                        _ ->
                            ( { model | pendingJoinOrLeave = Dict.insert eventId JoinOrLeavePending model.pendingJoinOrLeave }
                            , effects.joinEvent eventId
                            , { joinEvent = Nothing }
                            )

                Nothing ->
                    ( model, effects.none, { joinEvent = Just eventId } )

        PressedEditEvent eventId ->
            if isOwner && model.eventOverlay == Nothing then
                case Group.getEvent config.time eventId group of
                    Just ( _, IsPastEvent ) ->
                        ( model, effects.none, { joinEvent = Nothing } )

                    Nothing ->
                        ( model, effects.none, { joinEvent = Nothing } )

                    Just ( event, _ ) ->
                        ( { model
                            | eventOverlay =
                                EdittingEvent
                                    eventId
                                    { submitStatus = NotSubmitted { pressedSubmit = False }
                                    , eventName = Event.name event |> EventName.toString
                                    , description = Event.description event |> Description.toString
                                    , meetingType =
                                        case Event.eventType event of
                                            Event.MeetOnline _ ->
                                                MeetOnline

                                            Event.MeetInPerson _ ->
                                                MeetInPerson
                                    , meetOnlineLink =
                                        case Event.eventType event of
                                            Event.MeetOnline (Just link) ->
                                                Link.toString link

                                            Event.MeetOnline Nothing ->
                                                ""

                                            Event.MeetInPerson _ ->
                                                ""
                                    , meetInPersonAddress =
                                        case Event.eventType event of
                                            Event.MeetOnline _ ->
                                                ""

                                            Event.MeetInPerson (Just address) ->
                                                Address.toString address

                                            Event.MeetInPerson Nothing ->
                                                ""
                                    , startDate = Event.startTime event |> Date.fromPosix config.timezone |> Ui.datestamp
                                    , startTime = Ui.timeToString config.timezone (Event.startTime event)
                                    , duration =
                                        Event.duration event
                                            |> EventDuration.toDuration
                                            |> Duration.inHours
                                            |> Time.removeTrailing0s
                                            |> String.left 4
                                    , maxAttendees =
                                        case Event.maxAttendees event |> MaxAttendees.toMaybe of
                                            Just value ->
                                                String.fromInt value

                                            Nothing ->
                                                ""
                                    }
                                    |> Just
                          }
                        , effects.none
                        , { joinEvent = Nothing }
                        )

            else
                ( model, effects.none, { joinEvent = Nothing } )

        ChangedEditEvent editEvent ->
            ( { model
                | eventOverlay =
                    case model.eventOverlay of
                        Just (EdittingEvent eventId _) ->
                            Just (EdittingEvent eventId editEvent)

                        _ ->
                            model.eventOverlay
              }
            , effects.none
            , { joinEvent = Nothing }
            )

        PressedSubmitEditEvent ->
            case model.eventOverlay of
                Just (EdittingEvent eventId editEvent) ->
                    case Group.getEvent config.time eventId group of
                        Just ( event, eventStatus ) ->
                            if editEvent.submitStatus == IsSubmitting then
                                ( model, effects.none, { joinEvent = Nothing } )

                            else if isOwner then
                                let
                                    maybeEventType : Maybe Event.EventType
                                    maybeEventType =
                                        case editEvent.meetingType of
                                            MeetOnline ->
                                                validateLink editEvent.meetOnlineLink
                                                    |> Result.toMaybe
                                                    |> Maybe.map Event.MeetOnline

                                            MeetInPerson ->
                                                validateAddress editEvent.meetInPersonAddress
                                                    |> Result.toMaybe
                                                    |> Maybe.map Event.MeetInPerson

                                    maybeStartTime =
                                        case eventStatus of
                                            IsFutureEvent ->
                                                validateDateTime config.time config.timezone editEvent.startDate editEvent.startTime
                                                    |> Result.toMaybe

                                            _ ->
                                                Event.startTime event |> Just
                                in
                                Maybe.map5
                                    (\name description eventType startTime ( duration, maxAttendees ) ->
                                        ( { model
                                            | eventOverlay =
                                                EdittingEvent eventId
                                                    { editEvent | submitStatus = IsSubmitting }
                                                    |> Just
                                          }
                                        , effects.editEvent
                                            eventId
                                            (Untrusted.untrust name)
                                            (Untrusted.untrust description)
                                            (Untrusted.untrust eventType)
                                            startTime
                                            (Untrusted.untrust duration)
                                            (Untrusted.untrust maxAttendees)
                                        , { joinEvent = Nothing }
                                        )
                                    )
                                    (EventName.fromString editEvent.eventName |> Result.toMaybe)
                                    (Description.fromString editEvent.description |> Result.toMaybe)
                                    maybeEventType
                                    maybeStartTime
                                    (Maybe.map2 Tuple.pair
                                        (validateDuration editEvent.duration |> Result.toMaybe)
                                        (validateMaxAttendees editEvent.maxAttendees |> Result.toMaybe)
                                    )
                                    |> Maybe.withDefault
                                        ( { model
                                            | eventOverlay = EdittingEvent eventId (pressSubmit editEvent) |> Just
                                          }
                                        , effects.none
                                        , { joinEvent = Nothing }
                                        )

                            else
                                ( model, effects.none, { joinEvent = Nothing } )

                        Nothing ->
                            ( model, effects.none, { joinEvent = Nothing } )

                _ ->
                    ( model, effects.none, { joinEvent = Nothing } )

        PressedCancelEditEvent ->
            case model.eventOverlay of
                Just (EdittingEvent _ _) ->
                    ( { model | eventOverlay = Nothing }, effects.none, { joinEvent = Nothing } )

                _ ->
                    ( model, effects.none, { joinEvent = Nothing } )

        PressedCancelEvent ->
            case model.eventOverlay of
                Just (EdittingEvent eventId _) ->
                    ( { model | pendingEventCancelOrUncancel = Set.insert eventId model.pendingEventCancelOrUncancel }
                    , effects.changeCancellationStatus eventId Event.EventCancelled
                    , { joinEvent = Nothing }
                    )

                _ ->
                    ( model, effects.none, { joinEvent = Nothing } )

        PressedUncancelEvent ->
            case model.eventOverlay of
                Just (EdittingEvent eventId _) ->
                    ( { model | pendingEventCancelOrUncancel = Set.insert eventId model.pendingEventCancelOrUncancel }
                    , effects.changeCancellationStatus eventId Event.EventUncancelled
                    , { joinEvent = Nothing }
                    )

                _ ->
                    ( model, effects.none, { joinEvent = Nothing } )

        PressedRecancelEvent ->
            case model.eventOverlay of
                Just (EdittingEvent eventId _) ->
                    ( { model | pendingEventCancelOrUncancel = Set.insert eventId model.pendingEventCancelOrUncancel }
                    , effects.changeCancellationStatus eventId Event.EventCancelled
                    , { joinEvent = Nothing }
                    )

                _ ->
                    ( model, effects.none, { joinEvent = Nothing } )


pressSubmit : { a | submitStatus : SubmitStatus b } -> { a | submitStatus : SubmitStatus b }
pressSubmit event =
    { event
        | submitStatus =
            case event.submitStatus of
                NotSubmitted notSubmitted ->
                    NotSubmitted { notSubmitted | pressedSubmit = True }

                IsSubmitting ->
                    IsSubmitting

                Failed failed ->
                    Failed failed
    }


validateMaxAttendees : String -> Result String MaxAttendees.MaxAttendees
validateMaxAttendees text =
    let
        trimmed =
            String.trim text
    in
    case ( trimmed, String.toInt trimmed ) of
        ( "", _ ) ->
            Ok MaxAttendees.noLimit

        ( _, Just value ) ->
            case MaxAttendees.maxAttendees value of
                Ok ok ->
                    Ok ok

                Err MaxAttendeesMustBe2OrGreater ->
                    Err "You need to allow at least 2 people to join the event"

        ( _, Nothing ) ->
            Err "Invalid value. Choose an integer like 5 or 30 or leave it blank"


joinEventResponse : EventId -> Result Group.JoinEventError () -> Model -> Model
joinEventResponse eventId result model =
    { model
        | pendingJoinOrLeave =
            case result of
                Ok () ->
                    Dict.remove eventId model.pendingJoinOrLeave

                Err error ->
                    Dict.insert eventId (JoinFailure error) model.pendingJoinOrLeave
    }


leaveEventResponse : EventId -> Result () () -> Model -> Model
leaveEventResponse eventId result model =
    { model
        | pendingJoinOrLeave =
            case result of
                Ok () ->
                    Dict.remove eventId model.pendingJoinOrLeave

                Err () ->
                    Dict.insert eventId LeaveFailure model.pendingJoinOrLeave
    }


view : Time.Posix -> Time.Zone -> FrontendUser -> Group -> Model -> Maybe (Id UserId) -> Element Msg
view currentTime timezone owner group model maybeUserId =
    Element.el
        Ui.pageContentAttributes
        (case model.eventOverlay of
            Just AddingNewEvent ->
                newEventView currentTime timezone model.newEvent

            Just (EdittingEvent eventId editEvent) ->
                case Group.getEvent currentTime eventId group of
                    Just ( event, eventStatus ) ->
                        editEventView currentTime timezone (Event.cancellationStatus event) eventStatus editEvent

                    Nothing ->
                        Element.text "This event doesn't exist"

            Nothing ->
                groupView currentTime timezone owner group model maybeUserId
        )


groupView : Time.Posix -> Time.Zone -> FrontendUser -> Group -> Model -> Maybe (Id UserId) -> Element Msg
groupView currentTime timezone owner group model maybeUserId =
    let
        { pastEvents, ongoingEvent, futureEvents } =
            Group.events currentTime group

        isOwner =
            case maybeUserId of
                Just userId ->
                    Group.ownerId group == userId

                Nothing ->
                    False
    in
    Element.column
        [ Element.spacing 8, Element.padding 8, Ui.contentWidth, Element.centerX ]
        [ Element.wrappedRow
            [ Element.width Element.fill, Element.spacing 8 ]
            [ Element.column [ Element.alignTop, Element.width Element.fill, Element.spacing 4 ]
                (case model.name of
                    Editting name ->
                        let
                            error : Maybe String
                            error =
                                case GroupName.fromString name of
                                    Ok _ ->
                                        Nothing

                                    Err GroupName.GroupNameTooShort ->
                                        "Name must be at least "
                                            ++ String.fromInt GroupName.minLength
                                            ++ " characters long."
                                            |> Just

                                    Err GroupName.GroupNameTooLong ->
                                        "Name is too long. Keep it under "
                                            ++ String.fromInt (GroupName.maxLength + 1)
                                            ++ " characters."
                                            |> Just
                        in
                        [ Element.el
                            [ Ui.titleFontSize, Ui.contentWidth ]
                            (groupNameTextInput TypedName name "Group name")
                        , Maybe.map Ui.error error |> Maybe.withDefault Element.none
                        , Element.row
                            [ Element.spacing 16, Element.paddingXY 8 0 ]
                            [ smallButton resetGroupNameId PressedResetName "Reset"
                            , smallSubmitButton saveGroupNameId False { onPress = PressedSaveName, label = "Save" }
                            ]
                        ]

                    Submitting name ->
                        [ Element.el
                            [ Ui.titleFontSize, Ui.contentWidth ]
                            (groupNameTextInput TypedName (GroupName.toString name) "Group name")
                        , Element.row
                            [ Element.spacing 16, Element.paddingXY 8 0 ]
                            [ smallButton resetGroupNameId PressedResetName "Reset"
                            , smallSubmitButton saveGroupNameId True { onPress = PressedSaveName, label = "Save" }
                            ]
                        ]

                    Unchanged ->
                        [ group
                            |> Group.name
                            |> GroupName.toString
                            |> Ui.title
                            |> Element.el [ Element.paddingXY 8 4 ]
                        , if isOwner then
                            Element.el [ Element.paddingXY 8 0 ] (smallButton editGroupNameId PressedEditName "Edit")

                          else
                            Element.none
                        ]
                )
            , Ui.section "Organizer"
                (Element.row
                    [ Element.spacing 16 ]
                    [ ProfileImage.smallImage owner.profileImage
                    , Element.text (Name.toString owner.name)
                    ]
                )
            ]
        , case model.description of
            Editting description ->
                let
                    error : Maybe String
                    error =
                        case Description.fromString description of
                            Ok _ ->
                                Nothing

                            Err error_ ->
                                Description.errorToString description error_ |> Just
                in
                section
                    (error /= Nothing)
                    "Description"
                    (Element.row
                        [ Element.spacing 8 ]
                        [ smallButton resetDescriptionId PressedResetDescription "Reset"
                        , smallSubmitButton saveDescriptionId False { onPress = PressedSaveDescription, label = "Save" }
                        ]
                    )
                    (Element.column
                        [ Element.spacing 8, Element.width Element.fill ]
                        [ multiline TypedDescription description "Group description"
                        , Maybe.map Ui.error error |> Maybe.withDefault Element.none
                        ]
                    )

            Submitting description ->
                section
                    False
                    "Description"
                    (Element.row [ Element.spacing 8 ]
                        [ smallButton resetDescriptionId PressedResetDescription "Reset"
                        , smallSubmitButton saveDescriptionId True { onPress = PressedSaveDescription, label = "Save" }
                        ]
                    )
                    (multiline TypedDescription (Description.toString description) "")

            Unchanged ->
                section
                    False
                    "Description"
                    (if isOwner then
                        -- Extra el prevents focus on both reset and save buttons
                        Element.el [] (smallButton editDescriptionId PressedEditDescription "Edit")

                     else
                        Element.none
                    )
                    (Description.toParagraph False (Group.description group))
        , case ongoingEvent of
            Just event ->
                section
                    False
                    "Ongoing event"
                    Element.none
                    (ongoingEventView currentTime timezone isOwner maybeUserId event)

            Nothing ->
                Element.none
        , section
            False
            "Future events"
            (let
                showAllButton =
                    if List.length futureEvents > 1 then
                        if model.showAllFutureEvents then
                            smallButton showFirstFutureEventsId PressedShowFirstFutureEvents "Show first"

                        else
                            smallButton showAllFutureEventsId PressedShowAllFutureEvents "Show all"

                    else
                        Element.none
             in
             if isOwner then
                Element.row
                    [ Element.spacing 16 ]
                    [ showAllButton
                    , smallButton createNewEventId PressedAddEvent "Add event"
                    ]

             else
                Element.el [] showAllButton
            )
            ((case futureEvents of
                [] ->
                    [ Element.paragraph
                        []
                        [ Element.text "No new events have been planned yet." ]
                    ]

                soonest :: rest ->
                    (if model.showAllFutureEvents then
                        soonest :: rest

                     else
                        [ soonest ]
                    )
                        |> List.map (futureEventView currentTime timezone isOwner maybeUserId model.pendingJoinOrLeave)
             )
                |> Element.column [ Element.width Element.fill, Element.spacing 8 ]
            )
        , case pastEvents of
            head :: rest ->
                section
                    False
                    "Past events"
                    Element.none
                    (List.map (Tuple.second >> pastEventView currentTime timezone maybeUserId) (head :: rest)
                        |> Element.column [ Element.width Element.fill, Element.spacing 8 ]
                    )

            [] ->
                Element.none
        , Ui.section "Info"
            (Element.paragraph
                [ Element.alignRight ]
                [ Element.text ("This group was created on " ++ dateToString (Just timezone) (Group.createdAt group)) ]
            )
        ]


showAllFutureEventsId =
    Id.buttonId "groupPageShowAllFutureEvents"


showFirstFutureEventsId =
    Id.buttonId "groupPageShowFirstFutureEvents"


resetGroupNameId =
    Id.buttonId "groupPageResetGroupName"


editGroupNameId =
    Id.buttonId "groupPageEditGroupName"


saveGroupNameId =
    Id.buttonId "groupPageSaveGroupName"


resetDescriptionId =
    Id.buttonId "groupPageResetDescription"


editDescriptionId =
    Id.buttonId "groupPageEditDescription"


saveDescriptionId =
    Id.buttonId "groupPageSaveDescription"


createEventCancelId =
    Id.buttonId "groupPageCreateEventCancel"


createEventSubmitId =
    Id.buttonId "groupPageCreateEventSubmit"


createNewEventId =
    Id.buttonId "groupPageCreateNewEvent"


ongoingEventView : Time.Posix -> Time.Zone -> Bool -> Maybe (Id UserId) -> ( EventId, Event ) -> Element Msg
ongoingEventView currentTime timezone isOwner maybeUserId ( eventId, event ) =
    let
        isAttending =
            maybeUserId |> Maybe.map (\userId -> Set.member userId (Event.attendees event)) |> Maybe.withDefault False

        attendeeCount =
            Event.attendees event |> Set.size
    in
    eventCard
        [ eventCardHeader currentTime timezone IsOngoingEvent event
        , Event.description event |> Description.toParagraph False
        , eventTypeView False event
        , Element.paragraph
            []
            [ case attendeeCount of
                0 ->
                    Element.text "• No one plans on attending"

                1 ->
                    if isAttending then
                        Element.text "• One person is attending (it's you)"

                    else
                        Element.text "• One person is attending"

                _ ->
                    "• "
                        ++ String.fromInt attendeeCount
                        ++ " people are attending"
                        ++ (if isAttending then
                                " (including you)"

                            else
                                ""
                           )
                        |> Element.text
            ]
        , case Event.eventType event of
            Event.MeetOnline (Just link) ->
                Element.paragraph []
                    [ Element.text "• The event is taking place now at "
                    , Element.link
                        [ Element.Font.color Ui.linkColor ]
                        { url = Link.toString link, label = Element.text (Link.toString link) }
                    ]

            _ ->
                Element.none
        , if isOwner then
            Element.el
                []
                (Ui.button editEventId { onPress = PressedEditEvent eventId, label = "Edit event" })

          else
            Element.none
        ]


pastEventView : Time.Posix -> Time.Zone -> Maybe (Id UserId) -> Event -> Element Msg
pastEventView currentTime timezone maybeUserId event =
    let
        isAttending =
            maybeUserId |> Maybe.map (\userId -> Set.member userId (Event.attendees event)) |> Maybe.withDefault False

        attendeeCount =
            Event.attendees event |> Set.size
    in
    eventCard
        [ eventCardHeader currentTime timezone IsPastEvent event
        , Event.description event |> Description.toParagraph False
        , eventTypeView True event
        , Element.paragraph
            []
            [ case attendeeCount of
                0 ->
                    Element.text "• No one attended 💔"

                1 ->
                    if isAttending then
                        Element.text "• One person attended (it was you)"

                    else
                        Element.text "• One person attended"

                _ ->
                    "• "
                        ++ String.fromInt attendeeCount
                        ++ " people attended"
                        ++ (if isAttending then
                                "(you included)"

                            else
                                ""
                           )
                        |> Element.text
            ]
        ]


eventCardHeader : Time.Posix -> Time.Zone -> PastOngoingOrFuture -> Event -> Element msg
eventCardHeader currentTime timezone eventStatus event =
    Element.wrappedRow
        [ Element.spacing 16, Element.width Element.fill ]
        [ eventTitle event
        , Element.column
            [ Element.spacing 4, Element.alignTop ]
            [ datetimeToString (Just timezone) (Event.startTime event) |> Element.text
            , case eventStatus of
                IsOngoingEvent ->
                    "Ends in "
                        ++ Time.diffToString currentTime (Event.endTime event)
                        |> Element.text

                IsFutureEvent ->
                    "Begins in "
                        ++ Time.diffToString currentTime (Event.startTime event)
                        |> Element.text

                IsPastEvent ->
                    "Ended "
                        ++ Time.diffToString currentTime (Event.endTime event)
                        |> Element.text
            ]
        ]


futureEventView :
    Time.Posix
    -> Time.Zone
    -> Bool
    -> Maybe (Id UserId)
    -> Dict EventId EventJoinOrLeaveStatus
    -> ( EventId, Event )
    -> Element Msg
futureEventView currentTime timezone isOwner maybeUserId pendingJoinOrLeaveStatuses ( eventId, event ) =
    let
        isAttending =
            maybeUserId |> Maybe.map (\userId -> Set.member userId (Event.attendees event)) |> Maybe.withDefault False

        maybeJoinOrLeaveStatus : Maybe EventJoinOrLeaveStatus
        maybeJoinOrLeaveStatus =
            Dict.get eventId pendingJoinOrLeaveStatuses

        attendeeCount =
            Event.attendees event |> Set.size

        joinOrLeaveButton =
            if isAttending then
                Ui.submitButton
                    leaveEventButtonId
                    (maybeJoinOrLeaveStatus == Just JoinOrLeavePending)
                    { onPress = PressedLeaveEvent eventId, label = "Leave event" }

            else
                case Event.maxAttendees event |> MaxAttendees.toMaybe of
                    Just value ->
                        let
                            spotsLeft : Int
                            spotsLeft =
                                value - attendeeCount
                        in
                        if spotsLeft == 1 then
                            Ui.submitButton
                                joinEventButtonId
                                (maybeJoinOrLeaveStatus == Just JoinOrLeavePending)
                                { onPress = PressedJoinEvent eventId, label = "Join event (1 spot left)" }

                        else if spotsLeft > 0 then
                            Ui.submitButton
                                joinEventButtonId
                                (maybeJoinOrLeaveStatus == Just JoinOrLeavePending)
                                { onPress = PressedJoinEvent eventId, label = "Join event (" ++ String.fromInt spotsLeft ++ " spots left)" }

                        else
                            Ui.error "No spots left"

                    Nothing ->
                        Ui.submitButton
                            joinEventButtonId
                            (maybeJoinOrLeaveStatus == Just JoinOrLeavePending)
                            { onPress = PressedJoinEvent eventId, label = "Join event" }
    in
    eventCard
        [ eventCardHeader currentTime timezone IsFutureEvent event
        , eventTypeView False event
        , Element.paragraph
            []
            [ case attendeeCount of
                0 ->
                    Element.text "• No one plans on attending"

                1 ->
                    if isAttending then
                        Element.text "• One person plans on attending (it's you)"

                    else
                        Element.text "• One person plans on attending"

                _ ->
                    "• "
                        ++ String.fromInt attendeeCount
                        ++ " people plan on attending"
                        ++ (if isAttending then
                                " (including you)"

                            else
                                ""
                           )
                        |> Element.text
            ]
        , maxAttendeesView event
        , Element.wrappedRow
            [ Element.spacingXY 16 8 ]
            [ case Event.cancellationStatus event of
                Just ( Event.EventUncancelled, _ ) ->
                    joinOrLeaveButton

                Just ( Event.EventCancelled, cancelTime ) ->
                    Ui.error
                        ("This event was cancelled "
                            ++ Time.diffToString
                                (if Duration.from currentTime cancelTime |> Quantity.lessThanZero then
                                    currentTime

                                 else
                                    cancelTime
                                )
                                cancelTime
                        )

                Nothing ->
                    joinOrLeaveButton
            , if isOwner then
                Ui.button editEventId { onPress = PressedEditEvent eventId, label = "Edit event" }

              else
                Element.none
            ]
        , case maybeJoinOrLeaveStatus of
            Just LeaveFailure ->
                Ui.error "Failed to leave event"

            Just (JoinFailure Group.EventNotFound) ->
                Ui.error "Failed to join, this event doesn't exist (try refreshing the page?)"

            Just (JoinFailure Group.NoSpotsLeftInEvent) ->
                Ui.error "Failed to join event, there aren't any spots left."

            Just JoinOrLeavePending ->
                Element.none

            Nothing ->
                Element.none
        , Event.description event |> Description.toParagraph False
        ]


maxAttendeesView event =
    case Event.maxAttendees event |> MaxAttendees.toMaybe of
        Just value ->
            "• At most "
                ++ String.fromInt value
                ++ " people can attend this event"
                |> Element.text
                |> List.singleton
                |> Element.paragraph []

        Nothing ->
            Element.none


eventTitle : Event -> Element msg
eventTitle event =
    Event.name event
        |> EventName.toString
        |> Element.text
        |> List.singleton
        |> Element.paragraph [ Element.Region.heading 2, Element.Font.size 20, Element.Font.bold ]


eventCard : List (Element msg) -> Element msg
eventCard =
    Element.column
        [ Element.width Element.fill
        , Element.spacing 16
        , Element.Border.rounded 4
        , Element.padding 15
        , Element.Border.width 1
        , Element.Border.color grey
        , Element.Border.shadow { offset = ( 0, 3 ), size = -1, blur = 3, color = grey }
        ]


eventTypeView : Bool -> Event -> Element msg
eventTypeView isPastEvent event =
    let
        duration =
            Event.duration event |> EventDuration.toString

        thisIsA =
            if isPastEvent then
                "• This was a "

            else
                "• This is a "

        itsTakingPlaceAt =
            if isPastEvent then
                ". It took place at "

            else
                ". It's taking place at "
    in
    case Event.eventType event of
        Event.MeetInPerson maybeAddress ->
            Element.paragraph []
                (Element.text (thisIsA ++ duration ++ " long in-person event 🤝")
                    :: (case maybeAddress of
                            Just address ->
                                [ Element.text itsTakingPlaceAt
                                , Element.el [ Element.Font.bold ] (Element.text (Address.toString address))
                                , Element.text "."
                                ]

                            Nothing ->
                                []
                       )
                )

        Event.MeetOnline _ ->
            Element.paragraph
                []
                [ Element.text (thisIsA ++ duration ++ " long online event 💻") ]


cancelEventId =
    Id.buttonId "groupCancelEvent"


uncancelEventId =
    Id.buttonId "groupUncancelEvent"


recancelEventId =
    Id.buttonId "groupRecancelEvent"


editEventId =
    Id.buttonId "groupEditEvent"


leaveEventButtonId =
    Id.buttonId "groupLeaveEvent"


joinEventButtonId =
    Id.buttonId "groupJoinEvent"


intToMonth : Int -> Maybe Time.Month
intToMonth value =
    case value of
        1 ->
            Just Time.Jan

        2 ->
            Just Time.Feb

        3 ->
            Just Time.Mar

        4 ->
            Just Time.Apr

        5 ->
            Just Time.May

        6 ->
            Just Time.Jun

        7 ->
            Just Time.Jul

        8 ->
            Just Time.Aug

        9 ->
            Just Time.Sep

        10 ->
            Just Time.Oct

        11 ->
            Just Time.Nov

        12 ->
            Just Time.Dec

        _ ->
            Nothing


type EventType
    = MeetOnline
    | MeetInPerson


eventNameInputId =
    Id.textInputId "groupEventName"


eventDescriptionInputId =
    Id.textInputId "groupEventDescription"


eventMeetingTypeId =
    Id.radioButtonId
        "groupEventMeeting_"
        (\meetingType ->
            case meetingType of
                MeetOnline ->
                    "MeetOnline"

                MeetInPerson ->
                    "MeetInPerson"
        )


eventMeetingOnlineInputId =
    Id.textInputId "groupEventMeetingOnline"


eventMeetingInPersonInputId =
    Id.textInputId "groupEventMeetingInPerson"


editEventView : Time.Posix -> Time.Zone -> Maybe ( Event.CancellationStatus, Time.Posix ) -> Group.PastOngoingOrFuture -> EditEvent -> Element Msg
editEventView currentTime timezone maybeCancellationStatus eventStatus event =
    let
        pressedSubmit =
            case event.submitStatus of
                NotSubmitted notSubmitted ->
                    notSubmitted.pressedSubmit

                IsSubmitting ->
                    False

                Failed _ ->
                    True

        isSubmitting =
            case event.submitStatus of
                IsSubmitting ->
                    True

                _ ->
                    False
    in
    Element.column
        [ Element.spacing 20, Element.padding 8, Ui.contentWidth, Element.centerX ]
        [ Ui.title "Edit event"
        , Ui.columnCard
            [ Ui.textInput
                eventNameInputId
                (\text -> ChangedEditEvent { event | eventName = text })
                event.eventName
                "Event name"
                (case ( pressedSubmit, EventName.fromString event.eventName ) of
                    ( True, Err error ) ->
                        EventName.errorToString event.eventName error |> Just

                    _ ->
                        Nothing
                )
            , Ui.multiline
                eventDescriptionInputId
                (\text -> ChangedEditEvent { event | description = text })
                event.description
                "Event description (optional)"
                (case ( pressedSubmit, Description.fromString event.description ) of
                    ( True, Err error ) ->
                        Description.errorToString event.description error |> Just

                    _ ->
                        Nothing
                )
            , Ui.radioGroup
                eventMeetingTypeId
                (\meetingType -> ChangedEditEvent { event | meetingType = meetingType })
                (Nonempty MeetOnline [ MeetInPerson ])
                (Just event.meetingType)
                (\a ->
                    case a of
                        MeetOnline ->
                            "This event will be online"

                        MeetInPerson ->
                            "This event will be in person"
                )
                Nothing
            , case event.meetingType of
                MeetOnline ->
                    Ui.textInput
                        eventMeetingOnlineInputId
                        (\text -> ChangedEditEvent { event | meetOnlineLink = text })
                        event.meetOnlineLink
                        "Link that will be shown when the event starts (optional)"
                        (case ( pressedSubmit, validateLink event.meetOnlineLink ) of
                            ( True, Err error ) ->
                                Just error

                            _ ->
                                Nothing
                        )

                MeetInPerson ->
                    Ui.textInput
                        eventMeetingInPersonInputId
                        (\text -> ChangedEditEvent { event | meetInPersonAddress = text })
                        event.meetInPersonAddress
                        "Meeting address (optional)"
                        (case ( pressedSubmit, validateAddress event.meetInPersonAddress ) of
                            ( True, Err error ) ->
                                Just error

                            _ ->
                                Nothing
                        )
            , Element.column
                [ Element.width Element.fill, Element.spacing 8 ]
                [ Ui.dateTimeInput
                    { dateInputId = createEventStartDateId
                    , timeInputId = createEventStartTimeId
                    , dateChanged = \text -> ChangedEditEvent { event | startDate = text }
                    , timeChanged = \text -> ChangedEditEvent { event | startTime = text }
                    , labelText = "When does it start?"
                    , minTime = currentTime
                    , timezone = timezone
                    , dateText = event.startDate
                    , timeText = event.startTime
                    , isDisabled =
                        case eventStatus of
                            IsFutureEvent ->
                                False

                            _ ->
                                True
                    , maybeError =
                        case ( eventStatus, pressedSubmit, validateDateTime currentTime timezone event.startDate event.startTime ) of
                            ( IsFutureEvent, True, Err error ) ->
                                Just error

                            _ ->
                                Nothing
                    }
                , case eventStatus of
                    IsFutureEvent ->
                        Element.none

                    _ ->
                        Element.paragraph
                            []
                            [ Element.text "The start time can't be changed since the event has already started." ]
                ]
            , Ui.numberInput
                eventDurationId
                (\text -> ChangedEditEvent { event | duration = text })
                event.duration
                "How many hours long is it?"
                (case ( pressedSubmit, validateDuration event.duration ) of
                    ( True, Err error ) ->
                        Just error

                    _ ->
                        Nothing
                )
            , Ui.numberInput
                eventMaxAttendeesId
                (\text -> ChangedEditEvent { event | maxAttendees = text })
                event.maxAttendees
                "How many people can join (leave this empty if there's no limit)"
                (case ( pressedSubmit, validateMaxAttendees event.maxAttendees ) of
                    ( True, Err error ) ->
                        Just error

                    _ ->
                        Nothing
                )
            , Element.wrappedRow
                [ Element.spacing 8, Element.width Element.fill ]
                [ Ui.submitButton createEventSubmitId isSubmitting { onPress = PressedSubmitEditEvent, label = "Save changes" }
                , Ui.button createEventCancelId { onPress = PressedCancelEditEvent, label = "Cancel changes" }
                ]
            , case event.submitStatus of
                Failed EditEventStartsInThePast ->
                    Ui.error "Event can't start in the past"

                Failed (EditEventOverlapsOtherEvents _) ->
                    Ui.error "Event overlaps other events"

                Failed CantEditPastEvent ->
                    Ui.error "You can't edit events that have already happened"

                Failed CantChangeStartTimeOfOngoingEvent ->
                    Ui.error "You can't edit the start time of an event that is ongoing"

                Failed EditEventNotFound ->
                    Ui.error "This event somehow doesn't exist. Try refreshing the page?"

                NotSubmitted _ ->
                    Element.none

                IsSubmitting ->
                    Element.none
            , case eventStatus of
                IsFutureEvent ->
                    Ui.horizontalLine

                IsOngoingEvent ->
                    Element.none

                IsPastEvent ->
                    Element.none
            , case eventStatus of
                IsFutureEvent ->
                    Element.el
                        [ Element.alignRight ]
                        (case maybeCancellationStatus of
                            Just ( Event.EventCancelled, _ ) ->
                                Ui.dangerButton uncancelEventId { onPress = PressedUncancelEvent, label = "Uncancel event" }

                            Just ( Event.EventUncancelled, _ ) ->
                                Ui.dangerButton recancelEventId { onPress = PressedCancelEvent, label = "Recancel event" }

                            Nothing ->
                                Ui.dangerButton cancelEventId { onPress = PressedCancelEvent, label = "Cancel event" }
                        )

                IsOngoingEvent ->
                    Element.none

                IsPastEvent ->
                    Element.none
            ]
        ]


newEventView : Time.Posix -> Time.Zone -> NewEvent -> Element Msg
newEventView currentTime timezone event =
    let
        pressedSubmit =
            case event.submitStatus of
                NotSubmitted notSubmitted ->
                    notSubmitted.pressedSubmit

                IsSubmitting ->
                    False

                Failed _ ->
                    True

        isSubmitting =
            case event.submitStatus of
                IsSubmitting ->
                    True

                _ ->
                    False
    in
    Element.column
        [ Element.spacing 20, Element.padding 8, Ui.contentWidth, Element.centerX ]
        [ Ui.title "New event"
        , Ui.columnCard
            [ Ui.textInput
                eventNameInputId
                (\text -> ChangedNewEvent { event | eventName = text })
                event.eventName
                "Event name"
                (case ( pressedSubmit, EventName.fromString event.eventName ) of
                    ( True, Err error ) ->
                        EventName.errorToString event.eventName error |> Just

                    _ ->
                        Nothing
                )
            , Ui.multiline
                eventDescriptionInputId
                (\text -> ChangedNewEvent { event | description = text })
                event.description
                "Event description (optional)"
                (case ( pressedSubmit, Description.fromString event.description ) of
                    ( True, Err error ) ->
                        Description.errorToString event.description error |> Just

                    _ ->
                        Nothing
                )
            , Element.column
                [ Element.spacing 8, Element.width Element.fill ]
                [ Ui.radioGroup
                    eventMeetingTypeId
                    (\meetingType -> ChangedNewEvent { event | meetingType = Just meetingType })
                    (Nonempty MeetOnline [ MeetInPerson ])
                    event.meetingType
                    (\a ->
                        case a of
                            MeetOnline ->
                                "This event will be online"

                            MeetInPerson ->
                                "This event will be in-person"
                    )
                    (case ( pressedSubmit, event.meetingType ) of
                        ( True, Nothing ) ->
                            Just "Choose what type of event this is"

                        _ ->
                            Nothing
                    )
                , case event.meetingType of
                    Just MeetOnline ->
                        Ui.textInput
                            eventMeetingOnlineInputId
                            (\text -> ChangedNewEvent { event | meetOnlineLink = text })
                            event.meetOnlineLink
                            "Link that will be shown when the event starts (optional)"
                            (case ( pressedSubmit, validateLink event.meetOnlineLink ) of
                                ( True, Err error ) ->
                                    Just error

                                _ ->
                                    Nothing
                            )

                    Just MeetInPerson ->
                        Ui.textInput
                            eventMeetingInPersonInputId
                            (\text -> ChangedNewEvent { event | meetInPersonAddress = text })
                            event.meetInPersonAddress
                            "Meeting address (optional)"
                            (case ( pressedSubmit, validateAddress event.meetInPersonAddress ) of
                                ( True, Err error ) ->
                                    Just error

                                _ ->
                                    Nothing
                            )

                    Nothing ->
                        Element.none
                ]
            , Ui.dateTimeInput
                { dateInputId = createEventStartDateId
                , timeInputId = createEventStartTimeId
                , dateChanged = \text -> ChangedNewEvent { event | startDate = text }
                , timeChanged = \text -> ChangedNewEvent { event | startTime = text }
                , labelText = "When does it start?"
                , minTime = currentTime
                , timezone = timezone
                , dateText = event.startDate
                , timeText = event.startTime
                , isDisabled = False
                , maybeError =
                    case ( pressedSubmit, validateDateTime currentTime timezone event.startDate event.startTime ) of
                        ( True, Err error ) ->
                            Just error

                        _ ->
                            Nothing
                }
            , Ui.numberInput
                eventDurationId
                (\text -> ChangedNewEvent { event | duration = text })
                event.duration
                "How many hours long is it?"
                (case ( pressedSubmit, validateDuration event.duration ) of
                    ( True, Err error ) ->
                        Just error

                    _ ->
                        Nothing
                )
            , Ui.numberInput
                eventMaxAttendeesId
                (\text -> ChangedNewEvent { event | maxAttendees = text })
                event.maxAttendees
                "How many people can join (leave this empty if there's no limit)"
                (case ( pressedSubmit, validateMaxAttendees event.maxAttendees ) of
                    ( True, Err error ) ->
                        Just error

                    _ ->
                        Nothing
                )
            , Element.wrappedRow
                [ Element.spacing 8 ]
                [ Ui.submitButton
                    createEventSubmitId
                    isSubmitting
                    { onPress = PressedCreateNewEvent, label = "Create event" }
                , Ui.button createEventCancelId { onPress = PressedCancelNewEvent, label = "Cancel" }
                ]
            , case event.submitStatus of
                Failed EventStartsInThePast ->
                    Ui.error "Events can't start in the past"

                Failed (EventOverlapsOtherEvents _) ->
                    Ui.error "Event overlaps with another event"

                Failed TooManyEvents ->
                    Ui.error "This group has too many events"

                NotSubmitted _ ->
                    Element.none

                IsSubmitting ->
                    Element.none
            ]
        ]


eventMaxAttendeesId =
    Id.numberInputId "groupPageEditMaxAttendeesId"


eventDurationId =
    Id.numberInputId "groupPageEventDurationId"


createEventStartDateId =
    Id.dateInputId "groupPageCreateEventStartDate"


createEventStartTimeId =
    Id.timeInputId "groupPageCreateEventStartTime"


datetimeToString : Maybe Time.Zone -> Time.Posix -> String
datetimeToString maybeTimezone posix =
    let
        timezone =
            Maybe.withDefault Time.utc maybeTimezone
    in
    (posix |> Date.fromPosix timezone |> Date.format "MMMM ddd")
        ++ ", "
        ++ Ui.timeToString timezone posix
        ++ (case maybeTimezone of
                Just _ ->
                    ""

                Nothing ->
                    " (UTC)"
           )


dateToString : Maybe Time.Zone -> Time.Posix -> String
dateToString maybeTimezone posix =
    let
        timezone =
            Maybe.withDefault Time.utc maybeTimezone
    in
    posix |> Date.fromPosix timezone |> Date.format "MMMM ddd"


validateDuration : String -> Result String EventDuration
validateDuration text =
    case String.toFloat text of
        Just hours ->
            case hours * 60 |> round |> EventDuration.fromMinutes of
                Ok value ->
                    Ok value

                Err error ->
                    EventDuration.errorToString error |> Err

        Nothing ->
            Err "Invalid input. Write something like 1 or 2.5"


validateDateTime : Time.Posix -> Time.Zone -> String -> String -> Result String Time.Posix
validateDateTime currentTime timezone date time =
    if String.trim date == "" then
        Err "Date value missing"

    else
        case String.split "-" date |> List.map String.toInt of
            [ Just year, Just monthInt, Just day ] ->
                case intToMonth monthInt of
                    Just month ->
                        if String.trim time == "" then
                            Err "Time value missing"

                        else
                            case String.split ":" time |> List.map String.toInt of
                                [ Just hour, Just minute ] ->
                                    let
                                        timePosix =
                                            Time.partsToPosix
                                                timezone
                                                { year = year
                                                , month = month
                                                , day = day
                                                , hour = hour
                                                , minute = minute
                                                , second = 0
                                                , millisecond = 0
                                                }
                                    in
                                    if Duration.from currentTime timePosix |> Quantity.lessThanZero then
                                        Err "The event can't start in the past"

                                    else
                                        Ok timePosix

                                _ ->
                                    Err "Invalid time format. Expected something like 22:59"

                    Nothing ->
                        Err "Invalid date format. Expected something like 2020-01-31"

            _ ->
                Err "Invalid date format. Expected something like 2020-01-31"


validateLink : String -> Result String (Maybe Link)
validateLink text =
    let
        trimmed =
            String.trim text
    in
    if trimmed == "" then
        Ok Nothing

    else
        case Link.fromString trimmed of
            Just url ->
                Ok (Just url)

            Nothing ->
                Err "Invalid url. Enter something like https://my-hangouts.com or leave it blank"


validateAddress : String -> Result String (Maybe Address)
validateAddress text =
    if String.trim text == "" then
        Ok Nothing

    else
        case Address.fromString text of
            Ok value ->
                Ok (Just value)

            Err error ->
                Address.errorToString text error |> Err


section : Bool -> String -> Element msg -> Element msg -> Element msg
section hasError title headerExtra content =
    Element.column
        [ Element.spacing 8
        , Element.padding 8
        , Element.Border.rounded 4
        , Ui.inputBackground hasError
        , Element.width Element.fill
        ]
        [ Element.row
            [ Element.spacing 16 ]
            [ Element.paragraph [ Element.Font.bold ] [ Element.text title ]
            , headerExtra
            ]
        , content
        ]


smallButton : HtmlId ButtonId -> msg -> String -> Element msg
smallButton htmlId onPress label =
    Element.Input.button
        [ Element.Border.width 2
        , Element.Border.color <| grey
        , Element.paddingXY 8 2
        , Element.Border.rounded 4
        , Element.Font.center
        , Id.htmlIdToString htmlId |> Html.Attributes.id |> Element.htmlAttribute
        ]
        { onPress = Just onPress
        , label = Element.text label
        }


smallSubmitButton : HtmlId ButtonId -> Bool -> { onPress : msg, label : String } -> Element msg
smallSubmitButton htmlId isSubmitting { onPress, label } =
    Element.Input.button
        [ Element.Background.color <| Element.rgb 0.1 0.6 0.25
        , Element.paddingXY 8 4
        , Element.Border.rounded 4
        , Element.Font.center
        , Element.Font.color <| Element.rgb 1 1 1
        , Id.htmlIdToString htmlId |> Html.Attributes.id |> Element.htmlAttribute
        ]
        { onPress = Just onPress
        , label =
            Element.el
                [ Element.width Element.fill
                , Element.paddingXY 30 0
                , if isSubmitting then
                    Element.inFront (Element.el [] (Element.text "⌛"))

                  else
                    Element.inFront Element.none
                ]
                (Element.text label)
        }


multiline : (String -> msg) -> String -> String -> Element msg
multiline onChange text labelText =
    Element.Input.multiline
        [ Element.width Element.fill, Element.height (Element.px 200) ]
        { text = text
        , onChange = onChange
        , placeholder = Nothing
        , label = Element.Input.labelHidden labelText
        , spellcheck = True
        }


groupNameInputId =
    Id.textInputId "groupPageGroupName"


groupNameTextInput : (String -> msg) -> String -> String -> Element msg
groupNameTextInput onChange text labelText =
    Element.Input.text
        [ Element.width Element.fill
        , Element.paddingXY 8 4
        , Id.htmlIdToString groupNameInputId |> Html.Attributes.id |> Element.htmlAttribute
        ]
        { text = text
        , onChange = onChange
        , placeholder = Nothing
        , label = Element.Input.labelHidden labelText
        }
