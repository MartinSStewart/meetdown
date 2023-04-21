module GroupPage exposing
    ( CreateEventError(..)
    , EventType(..)
    , Model
    , Msg
    , ToBackend(..)
    , addedNewEvent
    , changeVisibilityResponse
    , createEventStartDateId
    , createEventStartTimeId
    , createEventSubmitId
    , createNewEventId
    , editCancellationStatusResponse
    , editEventResponse
    , eventDescriptionInputId
    , eventDurationId
    , eventMeetingTypeId
    , eventNameInputId
    , hideAttendeesButtonId
    , init
    , joinEventButtonId
    , joinEventResponse
    , leaveEventButtonId
    , leaveEventResponse
    , savedDescription
    , savedName
    , showAttendeesButtonId
    , subscribeButtonId
    , update
    , view
    )

import Address exposing (Address, Error(..))
import AdminStatus exposing (AdminStatus(..))
import AssocList as Dict exposing (Dict)
import AssocSet as Set exposing (Set)
import Cache exposing (Cache)
import Date
import Description exposing (Description)
import Duration
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Lamdera as Lamdera
import Element exposing (Element)
import Element.Background
import Element.Border
import Element.Font
import Element.Input
import Element.Region
import Event exposing (CancellationStatus, Event, EventType)
import EventDuration exposing (EventDuration)
import EventName exposing (EventName)
import FrontendUser exposing (FrontendUser)
import Group exposing (EditEventError(..), EventId, Group, GroupVisibility, PastOngoingOrFuture(..))
import GroupName exposing (GroupName)
import HtmlId
import Id exposing (Id, UserId)
import Link exposing (Link)
import List.Nonempty exposing (Nonempty(..))
import MaxAttendees exposing (Error(..), MaxAttendees)
import Name
import Pixels
import ProfileImage
import Quantity
import Route
import Time
import Time.Extra as Time
import TimeExtra as Time
import Ui
import Untrusted exposing (Untrusted)
import UserConfig exposing (Texts, Theme, UserConfig)


type alias Model =
    { name : Editable GroupName
    , description : Editable Description
    , eventOverlay : Maybe EventOverlay
    , newEvent : NewEvent
    , pendingJoinOrLeave : Dict EventId EventJoinOrLeaveStatus
    , showAllFutureEvents : Bool
    , pendingEventCancelOrUncancel : Set EventId
    , pendingToggleVisibility : Bool
    , subscribePending : SubscribeStatus
    , showAttendees : Set EventId
    }


type EventJoinOrLeaveStatus
    = JoinOrLeavePending
    | LeaveFailure
    | JoinFailure Group.JoinEventError


type Editable validated
    = Unchanged
    | Editing String
    | Submiting validated


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
    | PressedUncancelEvent
    | PressedSubmitEditEvent
    | PressedCancelEditEvent
    | PressedMakeGroupPublic
    | PressedMakeGroupUnlisted
    | PressedDeleteGroup
    | PressedCopyPreviousEvent
    | PressedSubscribe
    | PressedUnsubscribe
    | PressedShowAttendees EventId
    | PressedHideAttendees EventId


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
    , pendingToggleVisibility = False
    , subscribePending = NotPendingSubscribe
    , showAttendees = Set.empty
    }


type SubscribeStatus
    = NotPendingSubscribe
    | PendingSubscribe
    | PendingUnsubscribe


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
        Submiting _ ->
            { model | name = Unchanged }

        _ ->
            model


savedDescription : Model -> Model
savedDescription model =
    case model.description of
        Submiting _ ->
            { model | description = Unchanged }

        _ ->
            model


changeVisibilityResponse : Group.GroupVisibility -> Model -> Model
changeVisibilityResponse _ model =
    { model | pendingToggleVisibility = False }


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


canEdit : Group -> Maybe LoggedInData -> Bool
canEdit group maybeLoggedIn =
    case maybeLoggedIn of
        Just loggedIn ->
            (Group.ownerId group == loggedIn.userId)
                || (case loggedIn.adminStatus of
                        IsAdminAndEnabled ->
                            True

                        IsNotAdmin ->
                            False

                        IsAdminButDisabled ->
                            False
                   )

        Nothing ->
            False


type ToBackend
    = ChangeGroupNameRequest (Untrusted GroupName)
    | ChangeGroupDescriptionRequest (Untrusted Description)
    | ChangeGroupVisibilityRequest GroupVisibility
    | CreateEventRequest (Untrusted EventName) (Untrusted Description) (Untrusted Event.EventType) Time.Posix (Untrusted EventDuration) (Untrusted MaxAttendees)
    | EditEventRequest EventId (Untrusted EventName) (Untrusted Description) (Untrusted Event.EventType) Time.Posix (Untrusted EventDuration) (Untrusted MaxAttendees)
    | JoinEventRequest EventId
    | LeaveEventRequest EventId
    | ChangeEventCancellationStatusRequest EventId CancellationStatus
    | DeleteGroupAdminRequest
    | SubscribeRequest
    | UnsubscribeRequest


update :
    Texts
    -> { a | time : Time.Posix, timezone : Time.Zone, cachedUsers : Dict (Id UserId) (Cache FrontendUser) }
    -> Group
    -> Maybe LoggedInData
    -> Msg
    -> Model
    -> ( Model, Command FrontendOnly ToBackend Msg, { joinEvent : Maybe EventId, requestUserData : Set (Id UserId) } )
update texts config group maybeLoggedIn msg model =
    let
        canEdit_ =
            canEdit group maybeLoggedIn

        noOutMsg =
            { joinEvent = Nothing, requestUserData = Set.empty }

        noChange =
            ( model, Command.none, noOutMsg )
    in
    case msg of
        PressedEditName ->
            if canEdit_ then
                ( { model | name = Group.name group |> GroupName.toString |> Editing }
                , Command.none
                , noOutMsg
                )

            else
                noChange

        PressedSaveName ->
            if canEdit_ then
                case model.name of
                    Unchanged ->
                        noChange

                    Editing nameText ->
                        case GroupName.fromString nameText of
                            Ok name ->
                                ( { model | name = Submiting name }
                                , Untrusted.untrust name |> ChangeGroupNameRequest |> Lamdera.sendToBackend
                                , noOutMsg
                                )

                            Err _ ->
                                noChange

                    Submiting _ ->
                        noChange

            else
                noChange

        PressedResetName ->
            if canEdit_ then
                ( { model | name = Unchanged }, Command.none, noOutMsg )

            else
                noChange

        TypedName name ->
            if canEdit_ then
                case model.name of
                    Editing _ ->
                        ( { model | name = Editing name }, Command.none, noOutMsg )

                    _ ->
                        noChange

            else
                noChange

        PressedEditDescription ->
            if canEdit_ then
                ( { model | description = Group.description group |> Description.toString |> Editing }
                , Command.none
                , noOutMsg
                )

            else
                noChange

        PressedSaveDescription ->
            if canEdit_ then
                case model.description of
                    Unchanged ->
                        noChange

                    Editing descriptionText ->
                        case Description.fromString descriptionText of
                            Ok description ->
                                ( { model | description = Submiting description }
                                , Untrusted.untrust description
                                    |> ChangeGroupDescriptionRequest
                                    |> Lamdera.sendToBackend
                                , noOutMsg
                                )

                            Err _ ->
                                noChange

                    Submiting _ ->
                        noChange

            else
                noChange

        PressedResetDescription ->
            if canEdit_ then
                ( { model | description = Unchanged }, Command.none, noOutMsg )

            else
                noChange

        TypedDescription description ->
            if canEdit_ then
                case model.description of
                    Editing _ ->
                        ( { model | description = Editing description }
                        , Command.none
                        , noOutMsg
                        )

                    _ ->
                        noChange

            else
                noChange

        PressedAddEvent ->
            if canEdit_ && model.eventOverlay == Nothing then
                ( { model | eventOverlay = Just AddingNewEvent }, Command.none, noOutMsg )

            else
                noChange

        PressedShowAllFutureEvents ->
            ( { model | showAllFutureEvents = True }, Command.none, noOutMsg )

        PressedShowFirstFutureEvents ->
            ( { model | showAllFutureEvents = False }, Command.none, noOutMsg )

        ChangedNewEvent newEvent ->
            if canEdit_ then
                ( { model | newEvent = newEvent }, Command.none, noOutMsg )

            else
                noChange

        PressedCancelNewEvent ->
            if canEdit_ then
                case model.eventOverlay of
                    Just AddingNewEvent ->
                        ( { model | eventOverlay = Nothing }, Command.none, noOutMsg )

                    _ ->
                        noChange

            else
                noChange

        PressedCreateNewEvent ->
            let
                newEvent =
                    model.newEvent

                maybeEventType : Maybe Event.EventType
                maybeEventType =
                    newEvent.meetingType
                        |> Maybe.andThen
                            (\meetingType ->
                                case meetingType of
                                    MeetOnline ->
                                        validateLink texts newEvent.meetOnlineLink
                                            |> Result.toMaybe
                                            |> Maybe.map Event.MeetOnline

                                    MeetInPerson ->
                                        validateAddress texts newEvent.meetInPersonAddress
                                            |> Result.toMaybe
                                            |> Maybe.map Event.MeetInPerson

                                    MeetOnlineAndInPerson ->
                                        case ( validateLink texts newEvent.meetOnlineLink, validateAddress texts newEvent.meetInPersonAddress ) of
                                            ( Ok link, Ok address ) ->
                                                Just (Event.MeetOnlineAndInPerson link address)

                                            _ ->
                                                Nothing
                            )

                maybeStartTime =
                    validateDateTime texts config.time config.timezone newEvent.startDate newEvent.startTime
                        |> Result.toMaybe
            in
            if canEdit_ then
                Maybe.map5
                    (\name description eventType startTime ( duration, maxAttendees ) ->
                        ( { model | newEvent = { newEvent | submitStatus = IsSubmitting } }
                        , CreateEventRequest
                            (Untrusted.untrust name)
                            (Untrusted.untrust description)
                            (Untrusted.untrust eventType)
                            startTime
                            (Untrusted.untrust duration)
                            (Untrusted.untrust maxAttendees)
                            |> Lamdera.sendToBackend
                        , noOutMsg
                        )
                    )
                    (EventName.fromString newEvent.eventName |> Result.toMaybe)
                    (Description.fromString newEvent.description |> Result.toMaybe)
                    maybeEventType
                    maybeStartTime
                    (Maybe.map2 Tuple.pair
                        (validateDuration texts newEvent.duration |> Result.toMaybe)
                        (validateMaxAttendees texts newEvent.maxAttendees |> Result.toMaybe)
                    )
                    |> Maybe.withDefault
                        ( { model | newEvent = pressSubmit model.newEvent }
                        , Command.none
                        , noOutMsg
                        )

            else
                noChange

        PressedLeaveEvent eventId ->
            case Dict.get eventId model.pendingJoinOrLeave of
                Just JoinOrLeavePending ->
                    noChange

                _ ->
                    ( { model | pendingJoinOrLeave = Dict.insert eventId JoinOrLeavePending model.pendingJoinOrLeave }
                    , LeaveEventRequest eventId |> Lamdera.sendToBackend
                    , noOutMsg
                    )

        PressedJoinEvent eventId ->
            case maybeLoggedIn of
                Just _ ->
                    case Dict.get eventId model.pendingJoinOrLeave of
                        Just JoinOrLeavePending ->
                            noChange

                        _ ->
                            ( { model | pendingJoinOrLeave = Dict.insert eventId JoinOrLeavePending model.pendingJoinOrLeave }
                            , JoinEventRequest eventId |> Lamdera.sendToBackend
                            , noOutMsg
                            )

                Nothing ->
                    ( model, Command.none, { joinEvent = Just eventId, requestUserData = Set.empty } )

        PressedEditEvent eventId ->
            if canEdit_ && model.eventOverlay == Nothing then
                case Group.getEvent config.time eventId group of
                    Just ( _, IsPastEvent ) ->
                        noChange

                    Nothing ->
                        noChange

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

                                            Event.MeetOnlineAndInPerson _ _ ->
                                                MeetOnlineAndInPerson
                                    , meetOnlineLink =
                                        case Event.eventType event of
                                            Event.MeetOnline (Just link) ->
                                                Link.toString link

                                            Event.MeetOnline Nothing ->
                                                ""

                                            Event.MeetInPerson _ ->
                                                ""

                                            Event.MeetOnlineAndInPerson (Just link) _ ->
                                                Link.toString link

                                            Event.MeetOnlineAndInPerson Nothing _ ->
                                                ""
                                    , meetInPersonAddress =
                                        case Event.eventType event of
                                            Event.MeetOnline _ ->
                                                ""

                                            Event.MeetInPerson (Just address) ->
                                                Address.toString address

                                            Event.MeetInPerson Nothing ->
                                                ""

                                            Event.MeetOnlineAndInPerson _ (Just address) ->
                                                Address.toString address

                                            Event.MeetOnlineAndInPerson _ Nothing ->
                                                ""
                                    , startDate = Event.startTime event |> Date.fromPosix config.timezone |> Ui.datestamp
                                    , startTime =
                                        Ui.timestamp
                                            (Time.toHour config.timezone (Event.startTime event))
                                            (Time.toMinute config.timezone (Event.startTime event))
                                    , duration =
                                        Event.duration event
                                            |> EventDuration.toDuration
                                            |> Duration.inHours
                                            |> Time.removeTrailing0s 1
                                    , maxAttendees =
                                        case Event.maxAttendees event |> MaxAttendees.toMaybe of
                                            Just value ->
                                                String.fromInt value

                                            Nothing ->
                                                ""
                                    }
                                    |> Just
                          }
                        , Command.none
                        , noOutMsg
                        )

            else
                noChange

        ChangedEditEvent editEvent ->
            ( { model
                | eventOverlay =
                    case model.eventOverlay of
                        Just (EdittingEvent eventId _) ->
                            Just (EdittingEvent eventId editEvent)

                        _ ->
                            model.eventOverlay
              }
            , Command.none
            , noOutMsg
            )

        PressedSubmitEditEvent ->
            case model.eventOverlay of
                Just (EdittingEvent eventId editEvent) ->
                    case Group.getEvent config.time eventId group of
                        Just ( event, eventStatus ) ->
                            if editEvent.submitStatus == IsSubmitting then
                                noChange

                            else if canEdit_ then
                                let
                                    maybeEventType : Maybe Event.EventType
                                    maybeEventType =
                                        case editEvent.meetingType of
                                            MeetOnline ->
                                                validateLink texts editEvent.meetOnlineLink
                                                    |> Result.toMaybe
                                                    |> Maybe.map Event.MeetOnline

                                            MeetInPerson ->
                                                validateAddress texts editEvent.meetInPersonAddress
                                                    |> Result.toMaybe
                                                    |> Maybe.map Event.MeetInPerson

                                            MeetOnlineAndInPerson ->
                                                case ( validateLink texts editEvent.meetOnlineLink, validateAddress texts editEvent.meetInPersonAddress ) of
                                                    ( Ok link, Ok address ) ->
                                                        Just (Event.MeetOnlineAndInPerson link address)

                                                    _ ->
                                                        Nothing

                                    maybeStartTime =
                                        case eventStatus of
                                            IsFutureEvent ->
                                                validateDateTime texts config.time config.timezone editEvent.startDate editEvent.startTime
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
                                        , EditEventRequest
                                            eventId
                                            (Untrusted.untrust name)
                                            (Untrusted.untrust description)
                                            (Untrusted.untrust eventType)
                                            startTime
                                            (Untrusted.untrust duration)
                                            (Untrusted.untrust maxAttendees)
                                            |> Lamdera.sendToBackend
                                        , noOutMsg
                                        )
                                    )
                                    (EventName.fromString editEvent.eventName |> Result.toMaybe)
                                    (Description.fromString editEvent.description |> Result.toMaybe)
                                    maybeEventType
                                    maybeStartTime
                                    (Maybe.map2 Tuple.pair
                                        (validateDuration texts editEvent.duration |> Result.toMaybe)
                                        (validateMaxAttendees texts editEvent.maxAttendees |> Result.toMaybe)
                                    )
                                    |> Maybe.withDefault
                                        ( { model
                                            | eventOverlay = EdittingEvent eventId (pressSubmit editEvent) |> Just
                                          }
                                        , Command.none
                                        , noOutMsg
                                        )

                            else
                                noChange

                        Nothing ->
                            noChange

                _ ->
                    noChange

        PressedCancelEditEvent ->
            case model.eventOverlay of
                Just (EdittingEvent _ _) ->
                    ( { model | eventOverlay = Nothing }, Command.none, noOutMsg )

                _ ->
                    noChange

        PressedCancelEvent ->
            case model.eventOverlay of
                Just (EdittingEvent eventId _) ->
                    ( { model | pendingEventCancelOrUncancel = Set.insert eventId model.pendingEventCancelOrUncancel }
                    , ChangeEventCancellationStatusRequest eventId Event.EventCancelled
                        |> Lamdera.sendToBackend
                    , noOutMsg
                    )

                _ ->
                    noChange

        PressedUncancelEvent ->
            case model.eventOverlay of
                Just (EdittingEvent eventId _) ->
                    ( { model | pendingEventCancelOrUncancel = Set.insert eventId model.pendingEventCancelOrUncancel }
                    , ChangeEventCancellationStatusRequest eventId Event.EventUncancelled
                        |> Lamdera.sendToBackend
                    , noOutMsg
                    )

                _ ->
                    noChange

        PressedMakeGroupPublic ->
            if canEdit_ && not model.pendingToggleVisibility then
                ( { model | pendingToggleVisibility = True }
                , ChangeGroupVisibilityRequest Group.PublicGroup |> Lamdera.sendToBackend
                , noOutMsg
                )

            else
                noChange

        PressedMakeGroupUnlisted ->
            if canEdit_ && not model.pendingToggleVisibility then
                ( { model | pendingToggleVisibility = True }
                , ChangeGroupVisibilityRequest Group.UnlistedGroup |> Lamdera.sendToBackend
                , noOutMsg
                )

            else
                noChange

        PressedDeleteGroup ->
            case Maybe.map (.adminStatus >> AdminStatus.isAdminEnabled) maybeLoggedIn of
                Just True ->
                    ( model, Lamdera.sendToBackend DeleteGroupAdminRequest, noOutMsg )

                _ ->
                    noChange

        PressedCopyPreviousEvent ->
            case model.eventOverlay of
                Just AddingNewEvent ->
                    case latestEvent group of
                        Just latestEvent_ ->
                            ( { model
                                | newEvent =
                                    fillInEmptyNewEventInputs config.timezone latestEvent_ model.newEvent
                              }
                            , Command.none
                            , noOutMsg
                            )

                        Nothing ->
                            noChange

                Just (EdittingEvent _ _) ->
                    noChange

                Nothing ->
                    noChange

        PressedSubscribe ->
            ( { model | subscribePending = PendingSubscribe }, Lamdera.sendToBackend SubscribeRequest, noOutMsg )

        PressedUnsubscribe ->
            ( { model | subscribePending = PendingUnsubscribe }, Lamdera.sendToBackend UnsubscribeRequest, noOutMsg )

        PressedShowAttendees eventId ->
            let
                attendees : Set (Id UserId)
                attendees =
                    case Group.getEvent config.time eventId group of
                        Just ( event, _ ) ->
                            Event.attendees event

                        Nothing ->
                            Set.empty
            in
            ( { model | showAttendees = Set.insert eventId model.showAttendees }
            , Command.none
            , { joinEvent = Nothing
              , requestUserData =
                    Dict.keys config.cachedUsers
                        |> Set.fromList
                        |> Set.diff attendees
              }
            )

        PressedHideAttendees eventId ->
            ( { model | showAttendees = Set.remove eventId model.showAttendees }
            , Command.none
            , noOutMsg
            )


latestEvent : Group -> Maybe Event
latestEvent group =
    Group.allEvents group
        |> Dict.values
        |> List.sortBy (Event.startTime >> Time.posixToMillis)
        |> List.reverse
        |> List.head


fillInEmptyNewEventInputs : Time.Zone -> Event -> NewEvent -> NewEvent
fillInEmptyNewEventInputs timezone copyFrom newEvent =
    { submitStatus = newEvent.submitStatus
    , eventName =
        fillEmptyInput
            (Event.name copyFrom |> EventName.toString)
            newEvent.eventName
    , description =
        fillEmptyInput
            (Event.description copyFrom |> Description.toString)
            newEvent.description
    , meetingType =
        case newEvent.meetingType of
            Just _ ->
                newEvent.meetingType

            Nothing ->
                case Event.eventType copyFrom of
                    Event.MeetOnline _ ->
                        Just MeetOnline

                    Event.MeetInPerson _ ->
                        Just MeetInPerson

                    Event.MeetOnlineAndInPerson _ _ ->
                        Just MeetOnlineAndInPerson
    , meetOnlineLink =
        case Event.eventType copyFrom of
            Event.MeetOnline (Just link) ->
                fillEmptyInput
                    (Link.toString link)
                    newEvent.meetOnlineLink

            _ ->
                newEvent.meetOnlineLink
    , meetInPersonAddress =
        case Event.eventType copyFrom of
            Event.MeetInPerson (Just address) ->
                fillEmptyInput
                    (Address.toString address)
                    newEvent.meetInPersonAddress

            _ ->
                newEvent.meetInPersonAddress
    , startDate = newEvent.startDate
    , startTime =
        fillEmptyInput
            (Ui.timestamp
                (Time.toHour timezone (Event.startTime copyFrom))
                (Time.toMinute timezone (Event.startTime copyFrom))
            )
            newEvent.startTime
    , duration =
        fillEmptyInput
            (Event.duration copyFrom
                |> EventDuration.toDuration
                |> Duration.inHours
                |> Time.removeTrailing0s 1
            )
            newEvent.duration
    , maxAttendees =
        fillEmptyInput
            (Event.maxAttendees copyFrom
                |> MaxAttendees.toMaybe
                |> Maybe.map String.fromInt
                |> Maybe.withDefault ""
            )
            newEvent.maxAttendees
    }


fillEmptyInput : String -> String -> String
fillEmptyInput replacement text =
    if String.trim text == "" then
        replacement

    else
        text


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


validateMaxAttendees : Texts -> String -> Result String MaxAttendees.MaxAttendees
validateMaxAttendees texts text =
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
                    Err texts.youNeedToAllowAtLeast2PeopleToJoinTheEvent

        ( _, Nothing ) ->
            Err texts.invalidValueChooseAnIntegerLike5Or30OrLeaveItBlank


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


view :
    UserConfig
    -> Bool
    -> Time.Posix
    -> Time.Zone
    -> FrontendUser
    -> Dict (Id UserId) (Cache FrontendUser)
    -> Group
    -> Model
    -> Maybe LoggedInData
    -> Element Msg
view ({ texts } as userConfig) isMobile currentTime timezone owner cachedUsers group model maybeLoggedIn =
    Element.el
        Ui.pageContentAttributes
        (case model.eventOverlay of
            Just AddingNewEvent ->
                newEventView userConfig currentTime timezone group model.newEvent

            Just (EdittingEvent eventId editEvent) ->
                case Group.getEvent currentTime eventId group of
                    Just ( event, eventStatus ) ->
                        editEventView userConfig currentTime timezone (Event.cancellationStatus event) eventStatus editEvent

                    Nothing ->
                        Element.text texts.thisEventDoesNotExist

            Nothing ->
                groupView userConfig isMobile currentTime timezone owner cachedUsers group model maybeLoggedIn
        )


titlePart :
    UserConfig
    -> Model
    -> FrontendUser
    -> Group
    -> Maybe LoggedInData
    -> Element Msg
titlePart ({ theme, texts } as userConfig) model owner group maybeLoggedIn =
    let
        canEdit_ =
            canEdit group maybeLoggedIn
    in
    Element.wrappedRow
        [ Element.width Element.fill, Element.spacing 8 ]
        [ Element.column
            [ Element.alignTop, Element.width Element.fill, Element.spacing 4 ]
            ((case model.name of
                Editing name ->
                    let
                        error : Maybe String
                        error =
                            case GroupName.fromString name of
                                Ok _ ->
                                    Nothing

                                Err GroupName.GroupNameTooShort ->
                                    Just (texts.nameMustBeAtLeast GroupName.minLength)

                                Err GroupName.GroupNameTooLong ->
                                    Just (texts.nameMustBeAtMost GroupName.maxLength)
                    in
                    [ Element.el
                        [ Ui.titleFontSize, Ui.contentWidth ]
                        (groupNameTextInput userConfig TypedName name texts.groupName)
                    , Maybe.map (Ui.error theme) error |> Maybe.withDefault Element.none
                    , Element.row
                        [ Element.spacing 16, Element.paddingXY 8 0 ]
                        [ smallButton theme resetGroupNameId PressedResetName texts.reset
                        , Ui.smallSubmitButton saveGroupNameId False { onPress = PressedSaveName, label = texts.save }
                        ]
                    ]

                Submiting name ->
                    [ Element.el
                        [ Ui.titleFontSize, Ui.contentWidth ]
                        (groupNameTextInput userConfig TypedName (GroupName.toString name) texts.groupName)
                    , Element.row
                        [ Element.spacing 16, Element.paddingXY 8 0 ]
                        [ smallButton theme resetGroupNameId PressedResetName texts.reset
                        , Ui.smallSubmitButton saveGroupNameId True { onPress = PressedSaveName, label = texts.save }
                        ]
                    ]

                Unchanged ->
                    [ group
                        |> Group.name
                        |> GroupName.toString
                        |> Ui.title
                        |> Element.el [ Element.paddingXY 8 4 ]
                    , if canEdit_ then
                        Element.el [ Element.paddingXY 8 0 ] (smallButton theme editGroupNameId PressedEditName texts.edit)

                      else
                        Element.none
                    ]
             )
                ++ [ case ( canEdit_, maybeLoggedIn ) of
                        ( False, Just loggedIn ) ->
                            Element.el
                                []
                                (if loggedIn.isSubscribed then
                                    Ui.submitButton
                                        theme
                                        unsubscribeButtonId
                                        (PendingUnsubscribe == model.subscribePending)
                                        { onPress = PressedUnsubscribe, label = texts.stopNotifyingMeOfNewEvents }

                                 else
                                    Ui.submitButton
                                        theme
                                        subscribeButtonId
                                        (PendingSubscribe == model.subscribePending)
                                        { onPress = PressedSubscribe, label = texts.notifyMeOfNewEvents }
                                )

                        _ ->
                            Element.none
                   ]
            )
        , Ui.section
            theme
            texts.organizer
            (Element.link
                []
                { url = Route.encode (Route.UserRoute (Group.ownerId group) owner.name)
                , label =
                    Element.row
                        [ Element.spacing 16 ]
                        [ ProfileImage.smallImage userConfig owner.profileImage
                        , Element.text (Name.toString owner.name)
                        ]
                }
            )
        ]


subscribeButtonId : HtmlId
subscribeButtonId =
    Dom.id "groupPage_subscribeButton"


unsubscribeButtonId : HtmlId
unsubscribeButtonId =
    Dom.id "groupPage_unsubscribeButton"


type alias LoggedInData =
    { userId : Id UserId, adminStatus : AdminStatus, isSubscribed : Bool }


groupView :
    UserConfig
    -> Bool
    -> Time.Posix
    -> Time.Zone
    -> FrontendUser
    -> Dict (Id UserId) (Cache FrontendUser)
    -> Group
    -> Model
    -> Maybe LoggedInData
    -> Element Msg
groupView ({ theme, texts } as userConfig) isMobile currentTime timezone owner cachedUsers group model maybeLoggedIn =
    let
        { pastEvents, ongoingEvent, futureEvents } =
            Group.events currentTime group

        canEdit_ =
            canEdit group maybeLoggedIn
    in
    Element.column
        [ Element.spacing 24, Ui.contentWidth, Element.centerX ]
        [ titlePart userConfig model owner group maybeLoggedIn
        , case model.description of
            Editing description ->
                let
                    error : Maybe String
                    error =
                        case Description.fromString description of
                            Ok _ ->
                                Nothing

                            Err error_ ->
                                Description.errorToString texts description error_ |> Just
                in
                section
                    userConfig
                    (error /= Nothing)
                    texts.description
                    (Element.row
                        [ Element.spacing 8 ]
                        [ smallButton theme resetDescriptionId PressedResetDescription texts.reset
                        , Ui.smallSubmitButton saveDescriptionId False { onPress = PressedSaveDescription, label = texts.save }
                        ]
                    )
                    (Element.column
                        [ Element.spacing 8, Element.width Element.fill ]
                        [ multiline theme TypedDescription description texts.groupDescription
                        , Maybe.map (Ui.error theme) error |> Maybe.withDefault Element.none
                        ]
                    )

            Submiting description ->
                section
                    userConfig
                    False
                    texts.description
                    (Element.row [ Element.spacing 8 ]
                        [ smallButton theme resetDescriptionId PressedResetDescription texts.reset
                        , Ui.smallSubmitButton saveDescriptionId True { onPress = PressedSaveDescription, label = texts.save }
                        ]
                    )
                    (multiline theme TypedDescription (Description.toString description) "")

            Unchanged ->
                section
                    userConfig
                    False
                    texts.description
                    (if canEdit_ then
                        -- Extra el prevents focus on both reset and save buttons
                        Element.el [] (smallButton theme editDescriptionId PressedEditDescription texts.edit)

                     else
                        Element.none
                    )
                    (Description.toParagraph userConfig False (Group.description group))
        , case ongoingEvent of
            Just event ->
                section
                    userConfig
                    False
                    texts.ongoingEvent
                    Element.none
                    (ongoingEventView
                        userConfig
                        isMobile
                        cachedUsers
                        currentTime
                        timezone
                        canEdit_
                        maybeLoggedIn
                        model.pendingJoinOrLeave
                        model.showAttendees
                        event
                    )

            Nothing ->
                Element.none
        , section
            userConfig
            False
            texts.futureEvents
            (let
                showAllButton =
                    if List.length futureEvents > 1 then
                        if model.showAllFutureEvents then
                            smallButton theme showFirstFutureEventsId PressedShowFirstFutureEvents texts.showFirst

                        else
                            smallButton theme showAllFutureEventsId PressedShowAllFutureEvents texts.showAll

                    else
                        Element.none
             in
             if canEdit_ then
                Element.row
                    [ Element.spacing 16 ]
                    [ showAllButton
                    , smallButton theme createNewEventId PressedAddEvent texts.addEvent
                    ]

             else
                Element.el [] showAllButton
            )
            ((case futureEvents of
                [] ->
                    [ Element.paragraph
                        []
                        [ Element.text texts.noNewEventsHaveBeenPlannedYet ]
                    ]

                soonest :: rest ->
                    (if model.showAllFutureEvents then
                        soonest :: rest

                     else
                        [ soonest ]
                    )
                        |> List.map
                            (futureEventView
                                userConfig
                                isMobile
                                cachedUsers
                                currentTime
                                timezone
                                canEdit_
                                maybeLoggedIn
                                model.pendingJoinOrLeave
                                model.showAttendees
                            )
             )
                |> Element.column [ Element.width Element.fill, Element.spacing 8 ]
            )
        , case pastEvents of
            head :: rest ->
                section
                    userConfig
                    False
                    texts.pastEvents
                    Element.none
                    (List.map
                        (pastEventView userConfig isMobile cachedUsers currentTime timezone maybeLoggedIn model.showAttendees)
                        (head :: rest)
                        |> Element.column [ Element.width Element.fill, Element.spacing 8 ]
                    )

            [] ->
                Element.none
        , Ui.section
            theme
            texts.info
            (Element.paragraph
                [ Element.alignRight ]
                [ Element.text (texts.thisGroupWasCreatedOn ++ dateToString texts (Just timezone) (Group.createdAt group)) ]
            )
        , if canEdit_ then
            Element.el []
                (case Group.visibility group of
                    Group.PublicGroup ->
                        Ui.submitButton
                            theme
                            makeUnlistedGroupId
                            model.pendingToggleVisibility
                            { onPress = PressedMakeGroupUnlisted, label = texts.makeGroupUnlisted }

                    Group.UnlistedGroup ->
                        Ui.submitButton
                            theme
                            makePublicGroupId
                            model.pendingToggleVisibility
                            { onPress = PressedMakeGroupPublic, label = texts.makeGroupPublic }
                )

          else
            Element.none
        , case Maybe.map (.adminStatus >> AdminStatus.isAdminEnabled) maybeLoggedIn of
            Just True ->
                Ui.dangerButton theme deleteGroupButtonId False { onPress = PressedDeleteGroup, label = texts.deleteGroup }

            _ ->
                Element.none
        ]


deleteGroupButtonId : HtmlId
deleteGroupButtonId =
    HtmlId.buttonId "groupPageDeleteGroup"


makeUnlistedGroupId : HtmlId
makeUnlistedGroupId =
    HtmlId.buttonId "groupPageMakeUnlistedGroup"


makePublicGroupId : HtmlId
makePublicGroupId =
    HtmlId.buttonId "groupPageMakePublicGroup"


showAllFutureEventsId : HtmlId
showAllFutureEventsId =
    HtmlId.buttonId "groupPageShowAllFutureEvents"


showFirstFutureEventsId : HtmlId
showFirstFutureEventsId =
    HtmlId.buttonId "groupPageShowFirstFutureEvents"


resetGroupNameId : HtmlId
resetGroupNameId =
    HtmlId.buttonId "groupPageResetGroupName"


editGroupNameId : HtmlId
editGroupNameId =
    HtmlId.buttonId "groupPageEditGroupName"


saveGroupNameId : HtmlId
saveGroupNameId =
    HtmlId.buttonId "groupPageSaveGroupName"


resetDescriptionId : HtmlId
resetDescriptionId =
    HtmlId.buttonId "groupPageResetDescription"


editDescriptionId : HtmlId
editDescriptionId =
    HtmlId.buttonId "groupPageEditDescription"


saveDescriptionId : HtmlId
saveDescriptionId =
    HtmlId.buttonId "groupPageSaveDescription"


createEventCancelId : HtmlId
createEventCancelId =
    HtmlId.buttonId "groupPageCreateEventCancel"


createEventSubmitId : HtmlId
createEventSubmitId =
    HtmlId.buttonId "groupPageCreateEventSubmit"


createNewEventId : HtmlId
createNewEventId =
    HtmlId.buttonId "groupPageCreateNewEvent"


ongoingEventView :
    UserConfig
    -> Bool
    -> Dict (Id UserId) (Cache FrontendUser)
    -> Time.Posix
    -> Time.Zone
    -> Bool
    -> Maybe { a | userId : Id UserId, adminStatus : AdminStatus }
    -> Dict EventId EventJoinOrLeaveStatus
    -> Set EventId
    -> ( EventId, Event )
    -> Element Msg
ongoingEventView ({ theme, texts } as userConfig) isMobile cachedUsers currentTime timezone isOwner maybeLoggedIn pendingJoinOrLeaveStatuses showAttendees ( eventId, event ) =
    let
        isAttending =
            maybeLoggedIn
                |> Maybe.map (\{ userId } -> Set.member userId (Event.attendees event))
                |> Maybe.withDefault False

        maybeJoinOrLeaveStatus : Maybe EventJoinOrLeaveStatus
        maybeJoinOrLeaveStatus =
            Dict.get eventId pendingJoinOrLeaveStatuses

        attendeeCount =
            Event.attendees event |> Set.size

        showAttendees_ =
            Set.member eventId showAttendees
    in
    eventCard
        theme
        [ eventCardHeader texts isMobile currentTime timezone IsOngoingEvent event
        , eventTypeView texts False event
        , Element.paragraph
            []
            [ case attendeeCount of
                0 ->
                    Element.text texts.noOnePlansOnAttending

                1 ->
                    if isAttending then
                        Element.text texts.onePersonIsAttendingItSYou

                    else
                        Element.text texts.onePersonIsAttending

                _ ->
                    Element.text (texts.peopleAreAttending attendeeCount isAttending)
            , showAttendeesButton userConfig eventId showAttendees_
            ]
        , if showAttendees_ then
            attendeesView userConfig cachedUsers event

          else
            Element.none
        , case Event.eventType event of
            Event.MeetOnline (Just link_) ->
                if isAttending then
                    Element.paragraph []
                        [ Element.text texts.theEventIsTakingPlaceNowAt
                        , Element.link
                            [ Element.Font.color theme.link ]
                            { url = Link.toString link_, label = Element.text (Link.toString link_) }
                        ]

                else
                    Element.none

            _ ->
                Element.none
        , case Event.cancellationStatus event of
            Just ( Event.EventUncancelled, _ ) ->
                joinOrLeaveButton userConfig isAttending maybeJoinOrLeaveStatus eventId event attendeeCount

            Just ( Event.EventCancelled, cancelTime ) ->
                Ui.error
                    theme
                    (texts.thisEventWasCancelled
                        ++ texts.timeDiffToString
                            (if Duration.from currentTime cancelTime |> Quantity.lessThanZero then
                                currentTime

                             else
                                cancelTime
                            )
                            cancelTime
                    )

            Nothing ->
                joinOrLeaveButton userConfig isAttending maybeJoinOrLeaveStatus eventId event attendeeCount
        , if isOwner then
            Element.el
                []
                (Ui.button theme editEventId { onPress = PressedEditEvent eventId, label = texts.editEvent })

          else
            Element.none
        , Event.description event |> Description.toParagraph userConfig False
        ]


pastEventView :
    UserConfig
    -> Bool
    -> Dict (Id UserId) (Cache FrontendUser)
    -> Time.Posix
    -> Time.Zone
    -> Maybe { a | userId : Id UserId, adminStatus : AdminStatus }
    -> Set EventId
    -> ( EventId, Event )
    -> Element Msg
pastEventView ({ theme, texts } as userConfig) isMobile cachedUsers currentTime timezone maybeLoggedIn showAttendees ( eventId, event ) =
    let
        isAttending =
            maybeLoggedIn |> Maybe.map (\{ userId } -> Set.member userId (Event.attendees event)) |> Maybe.withDefault False

        attendeeCount =
            Event.attendees event |> Set.size

        showAttendees_ =
            Set.member eventId showAttendees
    in
    eventCard
        theme
        [ eventCardHeader texts isMobile currentTime timezone IsPastEvent event
        , eventTypeView texts True event
        , Element.paragraph
            []
            [ case attendeeCount of
                0 ->
                    Element.text texts.noOneAttended

                1 ->
                    if isAttending then
                        Element.text texts.onePersonAttendedItWasYou

                    else
                        Element.text texts.onePersonAttended

                _ ->
                    Element.text (texts.peopleAttended attendeeCount isAttending)
            , Element.text " "
            , showAttendeesButton userConfig eventId showAttendees_
            ]
        , if showAttendees_ then
            attendeesView userConfig cachedUsers event

          else
            Element.none
        , Event.description event |> Description.toParagraph userConfig False
        ]


attendeesView : UserConfig -> Dict (Id UserId) (Cache FrontendUser) -> Event -> Element msg
attendeesView ({ texts } as userConfig) cachedUsers event =
    let
        visibleAttendees : List (Element msg)
        visibleAttendees =
            Event.attendees event
                |> Set.toList
                |> List.filterMap
                    (\userId ->
                        Cache.get userId cachedUsers
                            |> Maybe.andThen
                                (\user ->
                                    if user.name /= Name.anonymous || user.profileImage /= ProfileImage.DefaultImage then
                                        attendeeView userConfig userId user |> Just

                                    else
                                        Nothing
                                )
                    )

        anonymousAttendees : Int
        anonymousAttendees =
            Set.size (Event.attendees event) - List.length visibleAttendees
    in
    Element.wrappedRow [ Element.spacing 4 ]
        (visibleAttendees
            ++ [ if anonymousAttendees == 0 then
                    Element.none

                 else if List.isEmpty visibleAttendees then
                    texts.justNanonymousNattendees anonymousAttendees
                        |> Element.text
                        |> Element.el [ Element.moveRight 24 ]

                 else
                    texts.andNanonymousNattendees anonymousAttendees
                        |> Element.text
                        |> Element.el
                            [ Element.alignTop
                            , Element.Font.center
                            , Element.paddingXY 8 8
                            ]
               ]
        )


attendeeImageSize : number
attendeeImageSize =
    64


attendeeView : UserConfig -> Id UserId -> FrontendUser -> Element msg
attendeeView userConfig userId user =
    let
        nameText =
            Name.toString user.name
    in
    Element.link
        [ Ui.inputFocusClass, Element.alignTop ]
        { url = Route.UserRoute userId user.name |> Route.encode
        , label =
            Element.column
                [ Element.spacing 2 ]
                [ ProfileImage.image userConfig (Pixels.pixels attendeeImageSize) user.profileImage
                , Element.paragraph
                    [ Element.Font.size 12
                    , Element.Font.center
                    , Element.width (Element.px attendeeImageSize)
                    ]
                    [ (if String.length nameText > 23 then
                        String.left 20 nameText ++ "..."

                       else
                        nameText
                      )
                        |> Element.text
                    ]
                ]
        }


showAttendeesButton : UserConfig -> EventId -> Bool -> Element Msg
showAttendeesButton { theme, texts } eventId showAttendees =
    Element.el
        []
        (if showAttendees then
            Element.Input.button
                [ Element.Font.color theme.link
                , Element.htmlAttribute (Dom.idToAttribute hideAttendeesButtonId)
                ]
                { onPress = PressedHideAttendees eventId |> Just
                , label = Element.text texts.hideU_00A0Attendees
                }

         else
            Element.Input.button
                [ Element.Font.color theme.link
                , Element.htmlAttribute (Dom.idToAttribute showAttendeesButtonId)
                ]
                { onPress = PressedShowAttendees eventId |> Just
                , label = Element.text texts.showAttendees
                }
        )


showAttendeesButtonId : HtmlId
showAttendeesButtonId =
    Dom.id "groupPage_showAttendeesButton"


hideAttendeesButtonId : HtmlId
hideAttendeesButtonId =
    Dom.id "groupPage_hideAttendeesButton"


eventCardHeader : Texts -> Bool -> Time.Posix -> Time.Zone -> PastOngoingOrFuture -> Event -> Element msg
eventCardHeader texts isMobile currentTime timezone eventStatus event =
    Element.wrappedRow
        [ Element.spacing 16
        , Element.width Element.fill
        , if isMobile then
            Element.Font.size 14

          else
            Ui.defaultFontSize
        ]
        [ eventTitle event
        , Element.column
            [ Element.spacing 4, Element.alignTop ]
            [ Ui.datetimeToString texts timezone (Event.startTime event) |> Element.text
            , (case eventStatus of
                IsOngoingEvent ->
                    texts.endsIn ++ texts.timeDiffToString currentTime (Event.endTime event)

                IsFutureEvent ->
                    texts.beginsIn ++ texts.timeDiffToString currentTime (Event.startTime event)

                IsPastEvent ->
                    texts.ended ++ texts.timeDiffToString currentTime (Event.endTime event)
              )
                |> Element.text
                |> Element.el [ Element.alignRight ]
            ]
        ]


futureEventView :
    UserConfig
    -> Bool
    -> Dict (Id UserId) (Cache FrontendUser)
    -> Time.Posix
    -> Time.Zone
    -> Bool
    -> Maybe { a | userId : Id UserId, adminStatus : AdminStatus }
    -> Dict EventId EventJoinOrLeaveStatus
    -> Set EventId
    -> ( EventId, Event )
    -> Element Msg
futureEventView ({ theme, texts } as userConfig) isMobile cachedUsers currentTime timezone isOwner maybeLoggedIn pendingJoinOrLeaveStatuses showAttendees ( eventId, event ) =
    let
        isAttending =
            maybeLoggedIn |> Maybe.map (\{ userId } -> Set.member userId (Event.attendees event)) |> Maybe.withDefault False

        maybeJoinOrLeaveStatus : Maybe EventJoinOrLeaveStatus
        maybeJoinOrLeaveStatus =
            Dict.get eventId pendingJoinOrLeaveStatuses

        attendeeCount =
            Event.attendees event |> Set.size

        showAttendees_ =
            Set.member eventId showAttendees
    in
    eventCard
        theme
        [ eventCardHeader texts isMobile currentTime timezone IsFutureEvent event
        , eventTypeView texts False event
        , Element.paragraph
            []
            [ case attendeeCount of
                0 ->
                    Element.text texts.noOnePlansOnAttending

                1 ->
                    if isAttending then
                        Element.text texts.onePersonPlansOnAttendingItSYou

                    else
                        Element.text texts.onePersonPlansOnAttending

                _ ->
                    Element.text (texts.peoplePlanOnAttending attendeeCount isAttending)
            , Element.text " "
            , showAttendeesButton userConfig eventId showAttendees_
            ]
        , if showAttendees_ then
            attendeesView userConfig cachedUsers event

          else
            Element.none
        , if Duration.from currentTime (Event.startTime event) |> Quantity.lessThan Duration.day then
            case Event.eventType event of
                Event.MeetOnline (Just link_) ->
                    if isAttending then
                        Element.paragraph []
                            [ Element.text texts.theEventWillTakePlaceAt
                            , Element.link
                                [ Element.Font.color theme.link ]
                                { url = Link.toString link_, label = Element.text (Link.toString link_) }
                            ]

                    else
                        Element.none

                _ ->
                    Element.none

          else
            Element.none
        , maxAttendeesView event
        , Element.wrappedRow
            [ Element.spacingXY 16 8
            , Element.width
                (if isMobile then
                    Element.fill

                 else
                    Element.shrink
                )
            ]
            [ case Event.cancellationStatus event of
                Just ( Event.EventUncancelled, _ ) ->
                    joinOrLeaveButton userConfig isAttending maybeJoinOrLeaveStatus eventId event attendeeCount

                Just ( Event.EventCancelled, cancelTime ) ->
                    Ui.error
                        theme
                        (texts.thisEventWasCancelled
                            ++ texts.timeDiffToString
                                (if Duration.from currentTime cancelTime |> Quantity.lessThanZero then
                                    currentTime

                                 else
                                    cancelTime
                                )
                                cancelTime
                        )

                Nothing ->
                    joinOrLeaveButton userConfig isAttending maybeJoinOrLeaveStatus eventId event attendeeCount
            , if isOwner then
                Ui.button theme editEventId { onPress = PressedEditEvent eventId, label = texts.editEvent }

              else
                Element.none
            ]
        , case maybeJoinOrLeaveStatus of
            Just LeaveFailure ->
                Ui.error theme texts.failedToLeaveEvent

            Just (JoinFailure Group.EventNotFound) ->
                Ui.error theme texts.failedToJoinThisEventDoesnTExistTryRefreshingThePage

            Just (JoinFailure Group.NoSpotsLeftInEvent) ->
                Ui.error theme texts.failedToJoinEventThereArenTAnySpotsLeft

            Just JoinOrLeavePending ->
                Element.none

            Nothing ->
                Element.none
        , Event.description event |> Description.toParagraph userConfig False
        ]


joinOrLeaveButton : UserConfig -> Bool -> Maybe EventJoinOrLeaveStatus -> EventId -> Event -> Int -> Element Msg
joinOrLeaveButton { theme, texts } isAttending maybeJoinOrLeaveStatus eventId event attendeeCount =
    if isAttending then
        Ui.submitButton
            theme
            leaveEventButtonId
            (maybeJoinOrLeaveStatus == Just JoinOrLeavePending)
            { onPress = PressedLeaveEvent eventId, label = texts.leaveEvent }

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
                        theme
                        joinEventButtonId
                        (maybeJoinOrLeaveStatus == Just JoinOrLeavePending)
                        { onPress = PressedJoinEvent eventId, label = "Join event (1 spot left)" }

                else if spotsLeft > 0 then
                    Ui.submitButton
                        theme
                        joinEventButtonId
                        (maybeJoinOrLeaveStatus == Just JoinOrLeavePending)
                        { onPress = PressedJoinEvent eventId, label = "Join event (" ++ String.fromInt spotsLeft ++ " spots left)" }

                else
                    Ui.error theme "No spots left"

            Nothing ->
                Ui.submitButton
                    theme
                    joinEventButtonId
                    (maybeJoinOrLeaveStatus == Just JoinOrLeavePending)
                    { onPress = PressedJoinEvent eventId, label = texts.joinEvent }


maxAttendeesView : Event -> Element msg
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


eventCard : Theme -> List (Element msg) -> Element msg
eventCard theme =
    Element.column
        [ Element.width Element.fill
        , Element.spacing 16
        , Element.Border.rounded 4
        , Element.padding 15
        , Element.Border.width 1
        , Element.Border.color theme.grey
        , Element.Border.shadow { offset = ( 0, 3 ), size = -1, blur = 3, color = theme.grey }
        ]


eventTypeView : Texts -> Bool -> Event -> Element msg
eventTypeView texts isPastEvent event =
    let
        duration =
            Event.duration event |> EventDuration.toString texts

        eventTypeText =
            case Event.eventType event of
                Event.MeetInPerson _ ->
                    texts.inPersonEvent

                Event.MeetOnline _ ->
                    texts.onlineEvent

                Event.MeetOnlineAndInPerson _ _ ->
                    texts.onlineAndInPersonEvent

        eventDurationText =
            texts.eventDurationText isPastEvent duration eventTypeText
    in
    case Event.eventType event of
        Event.MeetInPerson maybeAddress ->
            Element.paragraph []
                (Element.text eventDurationText
                    :: (case maybeAddress of
                            Just address ->
                                [ Element.text (texts.itsTakingPlaceAt isPastEvent)
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
                [ Element.text eventDurationText ]

        Event.MeetOnlineAndInPerson _ maybeAddress ->
            Element.paragraph
                []
                (Element.text eventDurationText
                    :: (case maybeAddress of
                            Just address ->
                                [ Element.text (texts.itsTakingPlaceAt isPastEvent)
                                , Element.el [ Element.Font.bold ] (Element.text (Address.toString address))
                                , Element.text "."
                                ]

                            Nothing ->
                                []
                       )
                )


cancelEventId : HtmlId
cancelEventId =
    HtmlId.buttonId "groupCancelEvent"


uncancelEventId : HtmlId
uncancelEventId =
    HtmlId.buttonId "groupUncancelEvent"


recancelEventId : HtmlId
recancelEventId =
    HtmlId.buttonId "groupRecancelEvent"


editEventId : HtmlId
editEventId =
    HtmlId.buttonId "groupEditEvent"


leaveEventButtonId : HtmlId
leaveEventButtonId =
    HtmlId.buttonId "groupLeaveEvent"


joinEventButtonId : HtmlId
joinEventButtonId =
    HtmlId.buttonId "groupJoinEvent"


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
    | MeetOnlineAndInPerson


eventNameInputId : HtmlId
eventNameInputId =
    HtmlId.textInputId "groupEventName"


eventDescriptionInputId : HtmlId
eventDescriptionInputId =
    HtmlId.textInputId "groupEventDescription"


eventMeetingTypeId : EventType -> HtmlId
eventMeetingTypeId =
    HtmlId.radioButtonId
        "groupEventMeeting_"
        (\meetingType ->
            case meetingType of
                MeetOnline ->
                    "MeetOnline"

                MeetInPerson ->
                    "MeetInPerson"

                MeetOnlineAndInPerson ->
                    "MeetOnlineAndInPerson"
        )


eventMeetingOnlineInputId : HtmlId
eventMeetingOnlineInputId =
    HtmlId.textInputId "groupEventMeetingOnline"


eventMeetingInPersonInputId : HtmlId
eventMeetingInPersonInputId =
    HtmlId.textInputId "groupEventMeetingInPerson"


editEventView :
    UserConfig
    -> Time.Posix
    -> Time.Zone
    -> Maybe ( Event.CancellationStatus, Time.Posix )
    -> Group.PastOngoingOrFuture
    -> EditEvent
    -> Element Msg
editEventView { theme, texts } currentTime timezone maybeCancellationStatus eventStatus event =
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
        [ Ui.title texts.editEvent
        , Ui.columnCard
            theme
            [ Ui.textInput
                theme
                eventNameInputId
                (\text -> ChangedEditEvent { event | eventName = text })
                event.eventName
                texts.eventName
                (case ( pressedSubmit, EventName.fromString event.eventName ) of
                    ( True, Err error ) ->
                        EventName.errorToString texts error |> Just

                    _ ->
                        Nothing
                )
            , Ui.multiline
                theme
                eventDescriptionInputId
                (\text -> ChangedEditEvent { event | description = text })
                event.description
                texts.eventDescriptionOptional
                (case ( pressedSubmit, Description.fromString event.description ) of
                    ( True, Err error ) ->
                        Description.errorToString texts event.description error |> Just

                    _ ->
                        Nothing
                )
            , Ui.radioGroup
                theme
                eventMeetingTypeId
                (\meetingType -> ChangedEditEvent { event | meetingType = meetingType })
                (Nonempty MeetOnline [ MeetInPerson, MeetOnlineAndInPerson ])
                (Just event.meetingType)
                (\a ->
                    case a of
                        MeetOnline ->
                            texts.thisEventWillBeOnline

                        MeetInPerson ->
                            texts.thisEventWillBeInPerson

                        MeetOnlineAndInPerson ->
                            texts.thisEventWillBeOnlineAndInPerson
                )
                Nothing
            , case event.meetingType of
                MeetOnline ->
                    Ui.textInput
                        theme
                        eventMeetingOnlineInputId
                        (\text -> ChangedEditEvent { event | meetOnlineLink = text })
                        event.meetOnlineLink
                        texts.linkThatWillBeShownWhenTheEventStartsOptional
                        (case ( pressedSubmit, validateLink texts event.meetOnlineLink ) of
                            ( True, Err error ) ->
                                Just error

                            _ ->
                                Nothing
                        )

                MeetInPerson ->
                    Ui.textInput
                        theme
                        eventMeetingInPersonInputId
                        (\text -> ChangedEditEvent { event | meetInPersonAddress = text })
                        event.meetInPersonAddress
                        texts.meetingAddressOptional
                        (case ( pressedSubmit, validateAddress texts event.meetInPersonAddress ) of
                            ( True, Err error ) ->
                                Just error

                            _ ->
                                Nothing
                        )

                MeetOnlineAndInPerson ->
                    Element.column [ Element.spacing 32 ]
                        [ Ui.textInput
                            theme
                            eventMeetingOnlineInputId
                            (\text -> ChangedEditEvent { event | meetOnlineLink = text })
                            event.meetOnlineLink
                            texts.linkThatWillBeShownWhenTheEventStartsOptional
                            (case ( pressedSubmit, validateLink texts event.meetOnlineLink ) of
                                ( True, Err error ) ->
                                    Just error

                                _ ->
                                    Nothing
                            )
                        , Ui.textInput
                            theme
                            eventMeetingInPersonInputId
                            (\text -> ChangedEditEvent { event | meetInPersonAddress = text })
                            event.meetInPersonAddress
                            texts.meetingAddressOptional
                            (case ( pressedSubmit, validateAddress texts event.meetInPersonAddress ) of
                                ( True, Err error ) ->
                                    Just error

                                _ ->
                                    Nothing
                            )
                        ]
            , Element.column
                [ Element.width Element.fill, Element.spacing 8 ]
                [ Ui.dateTimeInput
                    theme
                    { dateInputId = createEventStartDateId
                    , timeInputId = createEventStartTimeId
                    , dateChanged = \text -> ChangedEditEvent { event | startDate = text }
                    , timeChanged = \text -> ChangedEditEvent { event | startTime = text }
                    , labelText = texts.whenDoesItStart
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
                        case ( eventStatus, pressedSubmit, validateDateTime texts currentTime timezone event.startDate event.startTime ) of
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
                            [ Element.text texts.theStartTimeCanTBeChangedSinceTheEventHasAlreadyStarted ]
                ]
            , Ui.numberInput
                theme
                eventDurationId
                (\text -> ChangedEditEvent { event | duration = text })
                event.duration
                texts.howManyHoursLongIsIt
                (case ( pressedSubmit, validateDuration texts event.duration ) of
                    ( True, Err error ) ->
                        Just error

                    _ ->
                        Nothing
                )
            , Ui.numberInput
                theme
                eventMaxAttendeesId
                (\text -> ChangedEditEvent { event | maxAttendees = text })
                event.maxAttendees
                texts.howManyPeopleCanJoinLeaveThisEmptyIfThereSNoLimit
                (case ( pressedSubmit, validateMaxAttendees texts event.maxAttendees ) of
                    ( True, Err error ) ->
                        Just error

                    _ ->
                        Nothing
                )
            , Element.wrappedRow
                [ Element.spacing 8, Element.width Element.fill ]
                [ Ui.submitButton theme createEventSubmitId isSubmitting { onPress = PressedSubmitEditEvent, label = texts.saveChanges }
                , Ui.button theme createEventCancelId { onPress = PressedCancelEditEvent, label = texts.cancelChanges }
                ]
            , case event.submitStatus of
                Failed EditEventStartsInThePast ->
                    Ui.error theme texts.eventCanTStartInThePast

                Failed (EditEventOverlapsOtherEvents _) ->
                    Ui.error theme texts.eventOverlapsOtherEvents

                Failed CantEditPastEvent ->
                    Ui.error theme texts.youCanTEditEventsThatHaveAlreadyHappened

                Failed CantChangeStartTimeOfOngoingEvent ->
                    Ui.error theme texts.youCanTEditTheStartTimeOfAnEventThatIsOngoing

                Failed EditEventNotFound ->
                    Ui.error theme texts.thisEventSomehowDoesNotExistTryRefreshingThePage

                NotSubmitted _ ->
                    Element.none

                IsSubmitting ->
                    Element.none
            , case eventStatus of
                IsFutureEvent ->
                    Ui.horizontalLine theme

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
                                Ui.dangerButton
                                    theme
                                    uncancelEventId
                                    False
                                    { onPress = PressedUncancelEvent, label = texts.uncancelEvent }

                            Just ( Event.EventUncancelled, _ ) ->
                                Ui.dangerButton
                                    theme
                                    recancelEventId
                                    False
                                    { onPress = PressedCancelEvent, label = texts.recancelEvent }

                            Nothing ->
                                Ui.dangerButton
                                    theme
                                    cancelEventId
                                    False
                                    { onPress = PressedCancelEvent, label = texts.cancelEvent }
                        )

                IsOngoingEvent ->
                    Element.none

                IsPastEvent ->
                    Element.none
            ]
        ]


newEventView : UserConfig -> Time.Posix -> Time.Zone -> Group -> NewEvent -> Element Msg
newEventView { theme, texts } currentTime timezone group event =
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
        [ Ui.title texts.newEvent
        , Ui.columnCard
            theme
            [ case latestEvent group of
                Just _ ->
                    Element.el []
                        (Ui.button
                            theme
                            copyPreviousEventButtonId
                            { onPress = PressedCopyPreviousEvent, label = texts.copyPreviousEvent }
                        )

                Nothing ->
                    Element.none
            , Ui.textInput
                theme
                eventNameInputId
                (\text -> ChangedNewEvent { event | eventName = text })
                event.eventName
                texts.eventName
                (case ( pressedSubmit, EventName.fromString event.eventName ) of
                    ( True, Err error ) ->
                        EventName.errorToString texts error |> Just

                    _ ->
                        Nothing
                )
            , Ui.multiline
                theme
                eventDescriptionInputId
                (\text -> ChangedNewEvent { event | description = text })
                event.description
                texts.eventDescriptionOptional
                (case ( pressedSubmit, Description.fromString event.description ) of
                    ( True, Err error ) ->
                        Description.errorToString texts event.description error |> Just

                    _ ->
                        Nothing
                )
            , Element.column
                [ Element.spacing 8, Element.width Element.fill ]
                [ Ui.radioGroup
                    theme
                    eventMeetingTypeId
                    (\meetingType -> ChangedNewEvent { event | meetingType = Just meetingType })
                    (Nonempty MeetOnline [ MeetInPerson, MeetOnlineAndInPerson ])
                    event.meetingType
                    (\a ->
                        case a of
                            MeetOnline ->
                                texts.thisEventWillBeOnline

                            MeetInPerson ->
                                texts.thisEventWillBeInPerson

                            MeetOnlineAndInPerson ->
                                texts.thisEventWillBeOnlineAndInPerson
                    )
                    (case ( pressedSubmit, event.meetingType ) of
                        ( True, Nothing ) ->
                            Just texts.chooseWhatTypeOfEventThisIs

                        _ ->
                            Nothing
                    )
                , case event.meetingType of
                    Just MeetOnline ->
                        Ui.textInput
                            theme
                            eventMeetingOnlineInputId
                            (\text -> ChangedNewEvent { event | meetOnlineLink = text })
                            event.meetOnlineLink
                            texts.linkThatWillBeShownWhenTheEventStartsOptional
                            (case ( pressedSubmit, validateLink texts event.meetOnlineLink ) of
                                ( True, Err error ) ->
                                    Just error

                                _ ->
                                    Nothing
                            )

                    Just MeetInPerson ->
                        Ui.textInput
                            theme
                            eventMeetingInPersonInputId
                            (\text -> ChangedNewEvent { event | meetInPersonAddress = text })
                            event.meetInPersonAddress
                            texts.meetingAddressOptional
                            (case ( pressedSubmit, validateAddress texts event.meetInPersonAddress ) of
                                ( True, Err error ) ->
                                    Just error

                                _ ->
                                    Nothing
                            )

                    Just MeetOnlineAndInPerson ->
                        Element.column
                            [ Element.spacing 8, Element.width Element.fill ]
                            [ Ui.textInput
                                theme
                                eventMeetingOnlineInputId
                                (\text -> ChangedNewEvent { event | meetOnlineLink = text })
                                event.meetOnlineLink
                                texts.linkThatWillBeShownWhenTheEventStartsOptional
                                (case ( pressedSubmit, validateLink texts event.meetOnlineLink ) of
                                    ( True, Err error ) ->
                                        Just error

                                    _ ->
                                        Nothing
                                )
                            , Ui.textInput
                                theme
                                eventMeetingInPersonInputId
                                (\text -> ChangedNewEvent { event | meetInPersonAddress = text })
                                event.meetInPersonAddress
                                texts.meetingAddressOptional
                                (case ( pressedSubmit, validateAddress texts event.meetInPersonAddress ) of
                                    ( True, Err error ) ->
                                        Just error

                                    _ ->
                                        Nothing
                                )
                            ]

                    Nothing ->
                        Element.none
                ]
            , Ui.dateTimeInput
                theme
                { dateInputId = createEventStartDateId
                , timeInputId = createEventStartTimeId
                , dateChanged = \text -> ChangedNewEvent { event | startDate = text }
                , timeChanged = \text -> ChangedNewEvent { event | startTime = text }
                , labelText = texts.whenDoesItStart
                , minTime = currentTime
                , timezone = timezone
                , dateText = event.startDate
                , timeText = event.startTime
                , isDisabled = False
                , maybeError =
                    case ( pressedSubmit, validateDateTime texts currentTime timezone event.startDate event.startTime ) of
                        ( True, Err error ) ->
                            Just error

                        _ ->
                            Nothing
                }
            , Ui.numberInput
                theme
                eventDurationId
                (\text -> ChangedNewEvent { event | duration = text })
                event.duration
                texts.howManyHoursLongIsIt
                (case ( pressedSubmit, validateDuration texts event.duration ) of
                    ( True, Err error ) ->
                        Just error

                    _ ->
                        Nothing
                )
            , Ui.numberInput
                theme
                eventMaxAttendeesId
                (\text -> ChangedNewEvent { event | maxAttendees = text })
                event.maxAttendees
                texts.howManyPeopleCanJoinLeaveThisEmptyIfThereSNoLimit
                (case ( pressedSubmit, validateMaxAttendees texts event.maxAttendees ) of
                    ( True, Err error ) ->
                        Just error

                    _ ->
                        Nothing
                )
            , Element.wrappedRow
                [ Element.spacing 8 ]
                [ Ui.submitButton
                    theme
                    createEventSubmitId
                    isSubmitting
                    { onPress = PressedCreateNewEvent, label = texts.createEvent }
                , Ui.button theme createEventCancelId { onPress = PressedCancelNewEvent, label = texts.cancel }
                ]
            , case event.submitStatus of
                Failed EventStartsInThePast ->
                    Ui.error theme texts.eventsCanTStartInThePast

                Failed (EventOverlapsOtherEvents _) ->
                    Ui.error theme texts.eventOverlapsWithAnotherEvent

                Failed TooManyEvents ->
                    Ui.error theme texts.thisGroupHasTooManyEvents

                NotSubmitted _ ->
                    Element.none

                IsSubmitting ->
                    Element.none
            ]
        ]


eventMaxAttendeesId : HtmlId
eventMaxAttendeesId =
    HtmlId.numberInputId "groupPageEditMaxAttendeesId"


eventDurationId : HtmlId
eventDurationId =
    HtmlId.numberInputId "groupPageEventDurationId"


createEventStartDateId : HtmlId
createEventStartDateId =
    HtmlId.dateInputId "groupPageCreateEventStartDate"


createEventStartTimeId : HtmlId
createEventStartTimeId =
    HtmlId.timeInputId "groupPageCreateEventStartTime"


dateToString : Texts -> Maybe Time.Zone -> Time.Posix -> String
dateToString texts maybeTimezone posix =
    let
        timezone =
            Maybe.withDefault Time.utc maybeTimezone
    in
    posix |> Date.fromPosix timezone |> texts.formatDate


validateDuration : Texts -> String -> Result String EventDuration
validateDuration texts text =
    case String.toFloat text of
        Just hours ->
            case hours * 60 |> round |> EventDuration.fromMinutes of
                Ok value ->
                    Ok value

                Err error ->
                    EventDuration.errorToString texts error |> Err

        Nothing ->
            Err texts.invalidInput


validateDateTime : Texts -> Time.Posix -> Time.Zone -> String -> String -> Result String Time.Posix
validateDateTime texts currentTime timezone date time =
    if String.trim date == "" then
        Err texts.dateValueMissing

    else
        case String.split "-" date |> List.map String.toInt of
            [ Just year, Just monthInt, Just day ] ->
                case intToMonth monthInt of
                    Just month ->
                        if String.trim time == "" then
                            Err texts.timeValueMissing

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
                                        Err texts.theEventCanTStartInThePast

                                    else
                                        Ok timePosix

                                _ ->
                                    Err texts.invalidTimeFormatExpectedSomethingLike_22_59

                    Nothing ->
                        Err texts.invalidDateFormatExpectedSomethingLike_2020_01_31

            _ ->
                Err texts.invalidDateFormatExpectedSomethingLike_2020_01_31


validateLink : Texts -> String -> Result String (Maybe Link)
validateLink texts text =
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
                Err texts.invalidUrlLong


validateAddress : Texts -> String -> Result String (Maybe Address)
validateAddress texts text =
    if String.trim text == "" then
        Ok Nothing

    else
        case Address.fromString text of
            Ok value ->
                Ok (Just value)

            Err error ->
                Address.errorToString texts text error |> Err


section : UserConfig -> Bool -> String -> Element msg -> Element msg -> Element msg
section { theme } hasError title headerExtra content =
    Element.column
        [ Element.spacing 8
        , Element.Border.rounded 4
        , Ui.inputBackground theme hasError
        , Element.width Element.fill
        ]
        [ Element.row
            [ Element.spacing 16 ]
            [ Element.paragraph [ Element.Font.bold ] [ Element.text title ]
            , headerExtra
            ]
        , content
        ]


smallButton : Theme -> HtmlId -> msg -> String -> Element msg
smallButton theme htmlId onPress label =
    Element.Input.button
        [ Element.Border.width 2
        , Element.Border.color theme.grey
        , Element.paddingXY 8 2
        , Element.Border.rounded 4
        , Element.Font.center
        , Dom.idToAttribute htmlId |> Element.htmlAttribute
        ]
        { onPress = Just onPress
        , label = Element.text label
        }


multiline : Theme -> (String -> msg) -> String -> String -> Element msg
multiline theme onChange text labelText =
    Element.Input.multiline
        [ Element.width Element.fill
        , Element.height (Element.px 200)
        , Element.Background.color theme.background
        ]
        { text = text
        , onChange = onChange
        , placeholder = Nothing
        , label = Element.Input.labelHidden labelText
        , spellcheck = True
        }


groupNameInputId : HtmlId
groupNameInputId =
    HtmlId.textInputId "groupPageGroupName"


copyPreviousEventButtonId : HtmlId
copyPreviousEventButtonId =
    HtmlId.buttonId "groupPage_CopyPreviousEvent"


groupNameTextInput : UserConfig -> (String -> msg) -> String -> String -> Element msg
groupNameTextInput { theme } onChange text labelText =
    Element.Input.text
        [ Element.width Element.fill
        , Element.paddingXY 8 4
        , Dom.idToAttribute groupNameInputId |> Element.htmlAttribute
        , Element.Background.color theme.background
        ]
        { text = text
        , onChange = onChange
        , placeholder = Nothing
        , label = Element.Input.labelHidden labelText
        }
