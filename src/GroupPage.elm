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
    , init
    , joinEventButtonId
    , joinEventResponse
    , leaveEventButtonId
    , leaveEventResponse
    , notifyMeOfNewEvents
    , savedDescription
    , savedName
    , subscribeButtonId
    , update
    , view
    )

import Address exposing (Address, Error(..))
import AdminStatus exposing (AdminStatus(..))
import AssocList as Dict exposing (Dict)
import AssocSet as Set exposing (Set)
import Cache exposing (Cache)
import Colors exposing (..)
import Date
import Description exposing (Description)
import Duration
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Lamdera as Lamdera
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Region as Region
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
                                                Just <| Event.MeetOnlineAndInPerson link address

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
    el
        Ui.pageContentAttributes
        (case model.eventOverlay of
            Just AddingNewEvent ->
                newEventView userConfig currentTime timezone group model.newEvent

            Just (EdittingEvent eventId editEvent) ->
                case Group.getEvent currentTime eventId group of
                    Just ( event, eventStatus ) ->
                        editEventView userConfig currentTime timezone (Event.cancellationStatus event) eventStatus editEvent

                    Nothing ->
                        text texts.thisEventDoesnTExist

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
titlePart userConfig model owner group maybeLoggedIn =
    let
        canEdit_ =
            canEdit group maybeLoggedIn
    in
    wrappedRow
        [ width fill, spacing 8 ]
        [ column
            [ alignTop, width fill, spacing 4 ]
            ((case model.name of
                Editing name ->
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
                    [ el
                        [ Ui.titleFontSize, Ui.contentWidth ]
                        (groupNameTextInput userConfig TypedName name "Group name")
                    , Maybe.map (Ui.error userConfig.theme) error |> Maybe.withDefault none
                    , row
                        [ spacing 16, paddingXY 8 0 ]
                        [ smallButton userConfig.theme resetGroupNameId PressedResetName "Reset"
                        , Ui.smallSubmitButton saveGroupNameId False { onPress = PressedSaveName, label = "Save" }
                        ]
                    ]

                Submiting name ->
                    [ el
                        [ Ui.titleFontSize, Ui.contentWidth ]
                        (groupNameTextInput userConfig TypedName (GroupName.toString name) "Group name")
                    , row
                        [ spacing 16, paddingXY 8 0 ]
                        [ smallButton userConfig.theme resetGroupNameId PressedResetName "Reset"
                        , Ui.smallSubmitButton saveGroupNameId True { onPress = PressedSaveName, label = "Save" }
                        ]
                    ]

                Unchanged ->
                    [ group
                        |> Group.name
                        |> GroupName.toString
                        |> Ui.title
                        |> el [ paddingXY 8 4 ]
                    , if canEdit_ then
                        el [ paddingXY 8 0 ] (smallButton userConfig.theme editGroupNameId PressedEditName "Edit")

                      else
                        none
                    ]
             )
                ++ [ case ( canEdit_, maybeLoggedIn ) of
                        ( False, Just loggedIn ) ->
                            el
                                []
                                (if loggedIn.isSubscribed then
                                    Ui.submitButton
                                        userConfig.theme
                                        unsubscribeButtonId
                                        (PendingUnsubscribe == model.subscribePending)
                                        { onPress = PressedUnsubscribe, label = "Stop notifying me of new events" }

                                 else
                                    Ui.submitButton
                                        userConfig.theme
                                        subscribeButtonId
                                        (PendingSubscribe == model.subscribePending)
                                        { onPress = PressedSubscribe, label = notifyMeOfNewEvents }
                                )

                        _ ->
                            none
                   ]
            )
        , Ui.section
            userConfig.theme
            "Organizer"
            (link
                []
                { url = Route.encode (Route.UserRoute (Group.ownerId group) owner.name)
                , label =
                    row
                        [ spacing 16 ]
                        [ ProfileImage.smallImage userConfig owner.profileImage
                        , text (Name.toString owner.name)
                        ]
                }
            )
        ]


notifyMeOfNewEvents : String
notifyMeOfNewEvents =
    "Notify me of new events"


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
groupView userConfig isMobile currentTime timezone owner cachedUsers group model maybeLoggedIn =
    let
        { pastEvents, ongoingEvent, futureEvents } =
            Group.events currentTime group

        canEdit_ =
            canEdit group maybeLoggedIn
    in
    column
        [ spacing 24, Ui.contentWidth, centerX ]
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
                                Description.errorToString description error_ |> Just
                in
                section
                    userConfig
                    (error /= Nothing)
                    "Description"
                    (row
                        [ spacing 8 ]
                        [ smallButton userConfig.theme resetDescriptionId PressedResetDescription "Reset"
                        , Ui.smallSubmitButton saveDescriptionId False { onPress = PressedSaveDescription, label = "Save" }
                        ]
                    )
                    (column
                        [ spacing 8, width fill ]
                        [ multiline userConfig.theme TypedDescription description "Group description"
                        , Maybe.map (Ui.error userConfig.theme) error |> Maybe.withDefault none
                        ]
                    )

            Submiting description ->
                section
                    userConfig
                    False
                    "Description"
                    (row [ spacing 8 ]
                        [ smallButton userConfig.theme resetDescriptionId PressedResetDescription "Reset"
                        , Ui.smallSubmitButton saveDescriptionId True { onPress = PressedSaveDescription, label = "Save" }
                        ]
                    )
                    (multiline userConfig.theme TypedDescription (Description.toString description) "")

            Unchanged ->
                section
                    userConfig
                    False
                    "Description"
                    (if canEdit_ then
                        -- Extra el prevents focus on both reset and save buttons
                        el [] (smallButton userConfig.theme editDescriptionId PressedEditDescription "Edit")

                     else
                        none
                    )
                    (Description.toParagraph userConfig False (Group.description group))
        , case ongoingEvent of
            Just event ->
                section
                    userConfig
                    False
                    "Ongoing event"
                    none
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
                none
        , section
            userConfig
            False
            "Future events"
            (let
                showAllButton =
                    if List.length futureEvents > 1 then
                        if model.showAllFutureEvents then
                            smallButton userConfig.theme showFirstFutureEventsId PressedShowFirstFutureEvents "Show first"

                        else
                            smallButton userConfig.theme showAllFutureEventsId PressedShowAllFutureEvents "Show all"

                    else
                        none
             in
             if canEdit_ then
                row
                    [ spacing 16 ]
                    [ showAllButton
                    , smallButton userConfig.theme createNewEventId PressedAddEvent "Add event"
                    ]

             else
                el [] showAllButton
            )
            ((case futureEvents of
                [] ->
                    [ paragraph
                        []
                        [ text "No new events have been planned yet." ]
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
                |> column [ width fill, spacing 8 ]
            )
        , case pastEvents of
            head :: rest ->
                section
                    userConfig
                    False
                    "Past events"
                    none
                    (List.map
                        (pastEventView userConfig isMobile cachedUsers currentTime timezone maybeLoggedIn model.showAttendees)
                        (head :: rest)
                        |> column [ width fill, spacing 8 ]
                    )

            [] ->
                none
        , Ui.section
            userConfig.theme
            "Info"
            (paragraph
                [ alignRight ]
                [ text ("This group was created on " ++ dateToString (Just timezone) (Group.createdAt group)) ]
            )
        , if canEdit_ then
            el []
                (case Group.visibility group of
                    Group.PublicGroup ->
                        Ui.submitButton
                            userConfig.theme
                            makeUnlistedGroupId
                            model.pendingToggleVisibility
                            { onPress = PressedMakeGroupUnlisted, label = "Make group unlisted" }

                    Group.UnlistedGroup ->
                        Ui.submitButton
                            userConfig.theme
                            makePublicGroupId
                            model.pendingToggleVisibility
                            { onPress = PressedMakeGroupPublic, label = "Make group public" }
                )

          else
            none
        , case Maybe.map (.adminStatus >> AdminStatus.isAdminEnabled) maybeLoggedIn of
            Just True ->
                Ui.dangerButton userConfig.theme deleteGroupButtonId False { onPress = PressedDeleteGroup, label = "Delete group" }

            _ ->
                none
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
        [ eventCardHeader isMobile currentTime timezone IsOngoingEvent event
        , eventTypeView texts False event
        , paragraph
            []
            [ case attendeeCount of
                0 ->
                    text "• No one plans on attending"

                1 ->
                    if isAttending then
                        text "• One person is attending (it's you)"

                    else
                        text "• One person is attending"

                _ ->
                    "• "
                        ++ String.fromInt attendeeCount
                        ++ " people are attending"
                        ++ (if isAttending then
                                " (including you)"

                            else
                                ""
                           )
                        |> text
            , showAttendeesButton userConfig eventId showAttendees_
            ]
        , if showAttendees_ then
            attendeesView userConfig cachedUsers event

          else
            none
        , case Event.eventType event of
            Event.MeetOnline (Just link_) ->
                if isAttending then
                    paragraph []
                        [ text "• The event is taking place now at "
                        , link
                            [ Font.color userConfig.theme.link ]
                            { url = Link.toString link_, label = text (Link.toString link_) }
                        ]

                else
                    none

            _ ->
                none
        , case Event.cancellationStatus event of
            Just ( Event.EventUncancelled, _ ) ->
                joinOrLeaveButton userConfig isAttending maybeJoinOrLeaveStatus eventId event attendeeCount

            Just ( Event.EventCancelled, cancelTime ) ->
                Ui.error
                    userConfig.theme
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
                joinOrLeaveButton userConfig isAttending maybeJoinOrLeaveStatus eventId event attendeeCount
        , if isOwner then
            el
                []
                (Ui.button userConfig.theme editEventId { onPress = PressedEditEvent eventId, label = "Edit event" })

          else
            none
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
pastEventView ({ texts } as userConfig) isMobile cachedUsers currentTime timezone maybeLoggedIn showAttendees ( eventId, event ) =
    let
        isAttending =
            maybeLoggedIn |> Maybe.map (\{ userId } -> Set.member userId (Event.attendees event)) |> Maybe.withDefault False

        attendeeCount =
            Event.attendees event |> Set.size

        showAttendees_ =
            Set.member eventId showAttendees
    in
    eventCard
        userConfig.theme
        [ eventCardHeader isMobile currentTime timezone IsPastEvent event
        , eventTypeView texts True event
        , paragraph
            []
            [ case attendeeCount of
                0 ->
                    text "• No one attended 💔"

                1 ->
                    if isAttending then
                        text "• One person attended (it was you)"

                    else
                        text "• One person attended"

                _ ->
                    "• "
                        ++ String.fromInt attendeeCount
                        ++ " people attended"
                        ++ (if isAttending then
                                " (including you)"

                            else
                                ""
                           )
                        |> text
            , text " "
            , showAttendeesButton userConfig eventId showAttendees_
            ]
        , if showAttendees_ then
            attendeesView userConfig cachedUsers event

          else
            none
        , Event.description event |> Description.toParagraph userConfig False
        ]


attendeesView : UserConfig -> Dict (Id UserId) (Cache FrontendUser) -> Event -> Element msg
attendeesView userConfig cachedUsers event =
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
    wrappedRow [ spacing 4 ]
        (visibleAttendees
            ++ [ if anonymousAttendees == 0 then
                    none

                 else if List.isEmpty visibleAttendees then
                    (if anonymousAttendees == 1 then
                        "• Just 1 anonymous attendee"

                     else
                        "• Just " ++ String.fromInt anonymousAttendees ++ " anonymous attendees"
                    )
                        |> text
                        |> el [ moveRight 24 ]

                 else
                    (if anonymousAttendees == 1 then
                        "And one\nanonymous\nattendee"

                     else
                        "And " ++ String.fromInt anonymousAttendees ++ "\nanonymous\nattendees"
                    )
                        |> text
                        |> el
                            [ alignTop
                            , Font.center
                            , paddingXY 8 8
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
    link
        [ Ui.inputFocusClass, alignTop ]
        { url = Route.UserRoute userId user.name |> Route.encode
        , label =
            column
                [ spacing 2 ]
                [ ProfileImage.image userConfig (Pixels.pixels attendeeImageSize) user.profileImage
                , paragraph
                    [ Font.size 12
                    , Font.center
                    , width (px attendeeImageSize)
                    ]
                    [ (if String.length nameText > 23 then
                        String.left 20 nameText ++ "..."

                       else
                        nameText
                      )
                        |> text
                    ]
                ]
        }


showAttendeesButton : UserConfig -> EventId -> Bool -> Element Msg
showAttendeesButton userConfig eventId showAttendees =
    el
        []
        (if showAttendees then
            Input.button
                [ Font.color userConfig.theme.link
                , htmlAttribute (Dom.idToAttribute hideAttendeesButtonId)
                ]
                { onPress = PressedHideAttendees eventId |> Just
                , label = text "(Hide\u{00A0}attendees)"
                }

         else
            Input.button
                [ Font.color userConfig.theme.link
                , htmlAttribute (Dom.idToAttribute showAttendeesButtonId)
                ]
                { onPress = PressedShowAttendees eventId |> Just
                , label = text "(Show\u{00A0}attendees)"
                }
        )


showAttendeesButtonId : HtmlId
showAttendeesButtonId =
    Dom.id "groupPage_showAttendeesButton"


hideAttendeesButtonId : HtmlId
hideAttendeesButtonId =
    Dom.id "groupPage_hideAttendeesButton"


eventCardHeader : Bool -> Time.Posix -> Time.Zone -> PastOngoingOrFuture -> Event -> Element msg
eventCardHeader isMobile currentTime timezone eventStatus event =
    wrappedRow
        [ spacing 16
        , width fill
        , if isMobile then
            Font.size 14

          else
            Ui.defaultFontSize
        ]
        [ eventTitle event
        , column
            [ spacing 4, alignTop ]
            [ Ui.datetimeToString timezone (Event.startTime event) |> text
            , (case eventStatus of
                IsOngoingEvent ->
                    "Ends in "
                        ++ Time.diffToString currentTime (Event.endTime event)

                IsFutureEvent ->
                    "Begins in "
                        ++ Time.diffToString currentTime (Event.startTime event)

                IsPastEvent ->
                    "Ended "
                        ++ Time.diffToString currentTime (Event.endTime event)
              )
                |> text
                |> el [ alignRight ]
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
        [ eventCardHeader isMobile currentTime timezone IsFutureEvent event
        , eventTypeView texts False event
        , paragraph
            []
            [ case attendeeCount of
                0 ->
                    text "• No one plans on attending"

                1 ->
                    if isAttending then
                        text "• One person plans on attending (it's you)"

                    else
                        text "• One person plans on attending"

                _ ->
                    "• "
                        ++ String.fromInt attendeeCount
                        ++ " people plan on attending"
                        ++ (if isAttending then
                                " (including you)"

                            else
                                ""
                           )
                        |> text
            , text " "
            , showAttendeesButton userConfig eventId showAttendees_
            ]
        , if showAttendees_ then
            attendeesView userConfig cachedUsers event

          else
            none
        , if Duration.from currentTime (Event.startTime event) |> Quantity.lessThan Duration.day then
            case Event.eventType event of
                Event.MeetOnline (Just link_) ->
                    if isAttending then
                        paragraph []
                            [ text "• The event will take place at "
                            , link
                                [ Font.color userConfig.theme.link ]
                                { url = Link.toString link_, label = text <| Link.toString link_ }
                            ]

                    else
                        none

                _ ->
                    none

          else
            none
        , maxAttendeesView event
        , wrappedRow
            [ spacingXY 16 8
            , width
                (if isMobile then
                    fill

                 else
                    shrink
                )
            ]
            [ case Event.cancellationStatus event of
                Just ( Event.EventUncancelled, _ ) ->
                    joinOrLeaveButton userConfig isAttending maybeJoinOrLeaveStatus eventId event attendeeCount

                Just ( Event.EventCancelled, cancelTime ) ->
                    Ui.error
                        userConfig.theme
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
                    joinOrLeaveButton userConfig isAttending maybeJoinOrLeaveStatus eventId event attendeeCount
            , if isOwner then
                Ui.button userConfig.theme editEventId { onPress = PressedEditEvent eventId, label = "Edit event" }

              else
                none
            ]
        , case maybeJoinOrLeaveStatus of
            Just LeaveFailure ->
                Ui.error userConfig.theme "Failed to leave event"

            Just (JoinFailure Group.EventNotFound) ->
                Ui.error userConfig.theme "Failed to join, this event doesn't exist (try refreshing the page?)"

            Just (JoinFailure Group.NoSpotsLeftInEvent) ->
                Ui.error userConfig.theme "Failed to join event, there aren't any spots left."

            Just JoinOrLeavePending ->
                none

            Nothing ->
                none
        , Event.description event |> Description.toParagraph userConfig False
        ]


joinOrLeaveButton : UserConfig -> Bool -> Maybe EventJoinOrLeaveStatus -> EventId -> Event -> Int -> Element Msg
joinOrLeaveButton { theme } isAttending maybeJoinOrLeaveStatus eventId event attendeeCount =
    if isAttending then
        Ui.submitButton
            theme
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
                    { onPress = PressedJoinEvent eventId, label = "Join event" }


maxAttendeesView : Event -> Element msg
maxAttendeesView event =
    case Event.maxAttendees event |> MaxAttendees.toMaybe of
        Just value ->
            "• At most "
                ++ String.fromInt value
                ++ " people can attend this event"
                |> text
                |> List.singleton
                |> paragraph []

        Nothing ->
            none


eventTitle : Event -> Element msg
eventTitle event =
    Event.name event
        |> EventName.toString
        |> text
        |> List.singleton
        |> paragraph [ Region.heading 2, Font.size 20, Font.bold ]


eventCard : Theme -> List (Element msg) -> Element msg
eventCard theme =
    column
        [ width fill
        , spacing 16
        , Border.rounded 4
        , padding 15
        , Border.width 1
        , Border.color theme.grey
        , Border.shadow { offset = ( 0, 3 ), size = -1, blur = 3, color = theme.grey }
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
            paragraph []
                (text eventDurationText
                    :: (case maybeAddress of
                            Just address ->
                                [ text <| texts.itsTakingPlaceAt isPastEvent
                                , el [ Font.bold ] (text (Address.toString address))
                                , text "."
                                ]

                            Nothing ->
                                []
                       )
                )

        Event.MeetOnline _ ->
            paragraph
                []
                [ text eventDurationText ]

        Event.MeetOnlineAndInPerson _ maybeAddress ->
            paragraph
                []
                (text eventDurationText
                    :: (case maybeAddress of
                            Just address ->
                                [ text <| texts.itsTakingPlaceAt isPastEvent
                                , el [ Font.bold ] (text (Address.toString address))
                                , text "."
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
editEventView ({ texts } as userConfig) currentTime timezone maybeCancellationStatus eventStatus event =
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
    column
        [ spacing 20, padding 8, Ui.contentWidth, centerX ]
        [ Ui.title "Edit event"
        , Ui.columnCard
            userConfig.theme
            [ Ui.textInput
                userConfig.theme
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
                userConfig.theme
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
                userConfig.theme
                eventMeetingTypeId
                (\meetingType -> ChangedEditEvent { event | meetingType = meetingType })
                (Nonempty MeetOnline [ MeetInPerson, MeetOnlineAndInPerson ])
                (Just event.meetingType)
                (\a ->
                    case a of
                        MeetOnline ->
                            "This event will be online"

                        MeetInPerson ->
                            "This event will be in person"

                        MeetOnlineAndInPerson ->
                            "This event will be online and in person"
                )
                Nothing
            , case event.meetingType of
                MeetOnline ->
                    Ui.textInput
                        userConfig.theme
                        eventMeetingOnlineInputId
                        (\text -> ChangedEditEvent { event | meetOnlineLink = text })
                        event.meetOnlineLink
                        "Link that will be shown when the event starts (optional)"
                        (case ( pressedSubmit, validateLink texts event.meetOnlineLink ) of
                            ( True, Err error ) ->
                                Just error

                            _ ->
                                Nothing
                        )

                MeetInPerson ->
                    Ui.textInput
                        userConfig.theme
                        eventMeetingInPersonInputId
                        (\text -> ChangedEditEvent { event | meetInPersonAddress = text })
                        event.meetInPersonAddress
                        "Meeting address (optional)"
                        (case ( pressedSubmit, validateAddress texts event.meetInPersonAddress ) of
                            ( True, Err error ) ->
                                Just error

                            _ ->
                                Nothing
                        )

                MeetOnlineAndInPerson ->
                    column [ spacing 32 ]
                        [ Ui.textInput
                            userConfig.theme
                            eventMeetingOnlineInputId
                            (\text -> ChangedEditEvent { event | meetOnlineLink = text })
                            event.meetOnlineLink
                            "Link that will be shown when the event starts (optional)"
                            (case ( pressedSubmit, validateLink texts event.meetOnlineLink ) of
                                ( True, Err error ) ->
                                    Just error

                                _ ->
                                    Nothing
                            )
                        , Ui.textInput
                            userConfig.theme
                            eventMeetingInPersonInputId
                            (\text -> ChangedEditEvent { event | meetInPersonAddress = text })
                            event.meetInPersonAddress
                            "Meeting address (optional)"
                            (case ( pressedSubmit, validateAddress texts event.meetInPersonAddress ) of
                                ( True, Err error ) ->
                                    Just error

                                _ ->
                                    Nothing
                            )
                        ]
            , column
                [ width fill, spacing 8 ]
                [ Ui.dateTimeInput
                    userConfig.theme
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
                        case ( eventStatus, pressedSubmit, validateDateTime texts currentTime timezone event.startDate event.startTime ) of
                            ( IsFutureEvent, True, Err error ) ->
                                Just error

                            _ ->
                                Nothing
                    }
                , case eventStatus of
                    IsFutureEvent ->
                        none

                    _ ->
                        paragraph
                            []
                            [ text "The start time can't be changed since the event has already started." ]
                ]
            , Ui.numberInput
                userConfig.theme
                eventDurationId
                (\text -> ChangedEditEvent { event | duration = text })
                event.duration
                "How many hours long is it?"
                (case ( pressedSubmit, validateDuration texts event.duration ) of
                    ( True, Err error ) ->
                        Just error

                    _ ->
                        Nothing
                )
            , Ui.numberInput
                userConfig.theme
                eventMaxAttendeesId
                (\text -> ChangedEditEvent { event | maxAttendees = text })
                event.maxAttendees
                "How many people can join (leave this empty if there's no limit)"
                (case ( pressedSubmit, validateMaxAttendees texts event.maxAttendees ) of
                    ( True, Err error ) ->
                        Just error

                    _ ->
                        Nothing
                )
            , wrappedRow
                [ spacing 8, width fill ]
                [ Ui.submitButton userConfig.theme createEventSubmitId isSubmitting { onPress = PressedSubmitEditEvent, label = "Save changes" }
                , Ui.button userConfig.theme createEventCancelId { onPress = PressedCancelEditEvent, label = "Cancel changes" }
                ]
            , case event.submitStatus of
                Failed EditEventStartsInThePast ->
                    Ui.error userConfig.theme "Event can't start in the past"

                Failed (EditEventOverlapsOtherEvents _) ->
                    Ui.error userConfig.theme "Event overlaps other events"

                Failed CantEditPastEvent ->
                    Ui.error userConfig.theme "You can't edit events that have already happened"

                Failed CantChangeStartTimeOfOngoingEvent ->
                    Ui.error userConfig.theme "You can't edit the start time of an event that is ongoing"

                Failed EditEventNotFound ->
                    Ui.error userConfig.theme "This event somehow doesn't exist. Try refreshing the page?"

                NotSubmitted _ ->
                    none

                IsSubmitting ->
                    none
            , case eventStatus of
                IsFutureEvent ->
                    Ui.horizontalLine userConfig.theme

                IsOngoingEvent ->
                    none

                IsPastEvent ->
                    none
            , case eventStatus of
                IsFutureEvent ->
                    el
                        [ alignRight ]
                        (case maybeCancellationStatus of
                            Just ( Event.EventCancelled, _ ) ->
                                Ui.dangerButton
                                    userConfig.theme
                                    uncancelEventId
                                    False
                                    { onPress = PressedUncancelEvent, label = "Uncancel event" }

                            Just ( Event.EventUncancelled, _ ) ->
                                Ui.dangerButton
                                    userConfig.theme
                                    recancelEventId
                                    False
                                    { onPress = PressedCancelEvent, label = "Recancel event" }

                            Nothing ->
                                Ui.dangerButton
                                    userConfig.theme
                                    cancelEventId
                                    False
                                    { onPress = PressedCancelEvent, label = "Cancel event" }
                        )

                IsOngoingEvent ->
                    none

                IsPastEvent ->
                    none
            ]
        ]


newEventView : UserConfig -> Time.Posix -> Time.Zone -> Group -> NewEvent -> Element Msg
newEventView ({ texts } as userConfig) currentTime timezone group event =
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
    column
        [ spacing 20, padding 8, Ui.contentWidth, centerX ]
        [ Ui.title "New event"
        , Ui.columnCard
            userConfig.theme
            [ case latestEvent group of
                Just _ ->
                    el []
                        (Ui.button
                            userConfig.theme
                            copyPreviousEventButtonId
                            { onPress = PressedCopyPreviousEvent, label = "Copy previous event" }
                        )

                Nothing ->
                    none
            , Ui.textInput
                userConfig.theme
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
                userConfig.theme
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
            , column
                [ spacing 8, width fill ]
                [ Ui.radioGroup
                    userConfig.theme
                    eventMeetingTypeId
                    (\meetingType -> ChangedNewEvent { event | meetingType = Just meetingType })
                    (Nonempty MeetOnline [ MeetInPerson, MeetOnlineAndInPerson ])
                    event.meetingType
                    (\a ->
                        case a of
                            MeetOnline ->
                                "This event will be online"

                            MeetInPerson ->
                                "This event will be in-person"

                            MeetOnlineAndInPerson ->
                                "This event will be online and in-person"
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
                            userConfig.theme
                            eventMeetingOnlineInputId
                            (\text -> ChangedNewEvent { event | meetOnlineLink = text })
                            event.meetOnlineLink
                            "Link that will be shown when the event starts (optional)"
                            (case ( pressedSubmit, validateLink texts event.meetOnlineLink ) of
                                ( True, Err error ) ->
                                    Just error

                                _ ->
                                    Nothing
                            )

                    Just MeetInPerson ->
                        Ui.textInput
                            userConfig.theme
                            eventMeetingInPersonInputId
                            (\text -> ChangedNewEvent { event | meetInPersonAddress = text })
                            event.meetInPersonAddress
                            "Meeting address (optional)"
                            (case ( pressedSubmit, validateAddress texts event.meetInPersonAddress ) of
                                ( True, Err error ) ->
                                    Just error

                                _ ->
                                    Nothing
                            )

                    Just MeetOnlineAndInPerson ->
                        column
                            [ spacing 8, width fill ]
                            [ Ui.textInput
                                userConfig.theme
                                eventMeetingOnlineInputId
                                (\text -> ChangedNewEvent { event | meetOnlineLink = text })
                                event.meetOnlineLink
                                "Link that will be shown when the event starts (optional)"
                                (case ( pressedSubmit, validateLink texts event.meetOnlineLink ) of
                                    ( True, Err error ) ->
                                        Just error

                                    _ ->
                                        Nothing
                                )
                            , Ui.textInput
                                userConfig.theme
                                eventMeetingInPersonInputId
                                (\text -> ChangedNewEvent { event | meetInPersonAddress = text })
                                event.meetInPersonAddress
                                "Meeting address (optional)"
                                (case ( pressedSubmit, validateAddress texts event.meetInPersonAddress ) of
                                    ( True, Err error ) ->
                                        Just error

                                    _ ->
                                        Nothing
                                )
                            ]

                    Nothing ->
                        none
                ]
            , Ui.dateTimeInput
                userConfig.theme
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
                    case ( pressedSubmit, validateDateTime texts currentTime timezone event.startDate event.startTime ) of
                        ( True, Err error ) ->
                            Just error

                        _ ->
                            Nothing
                }
            , Ui.numberInput
                userConfig.theme
                eventDurationId
                (\text -> ChangedNewEvent { event | duration = text })
                event.duration
                "How many hours long is it?"
                (case ( pressedSubmit, validateDuration texts event.duration ) of
                    ( True, Err error ) ->
                        Just error

                    _ ->
                        Nothing
                )
            , Ui.numberInput
                userConfig.theme
                eventMaxAttendeesId
                (\text -> ChangedNewEvent { event | maxAttendees = text })
                event.maxAttendees
                "How many people can join (leave this empty if there's no limit)"
                (case ( pressedSubmit, validateMaxAttendees texts event.maxAttendees ) of
                    ( True, Err error ) ->
                        Just error

                    _ ->
                        Nothing
                )
            , wrappedRow
                [ spacing 8 ]
                [ Ui.submitButton
                    userConfig.theme
                    createEventSubmitId
                    isSubmitting
                    { onPress = PressedCreateNewEvent, label = "Create event" }
                , Ui.button userConfig.theme createEventCancelId { onPress = PressedCancelNewEvent, label = "Cancel" }
                ]
            , case event.submitStatus of
                Failed EventStartsInThePast ->
                    Ui.error userConfig.theme "Events can't start in the past"

                Failed (EventOverlapsOtherEvents _) ->
                    Ui.error userConfig.theme "Event overlaps with another event"

                Failed TooManyEvents ->
                    Ui.error userConfig.theme "This group has too many events"

                NotSubmitted _ ->
                    none

                IsSubmitting ->
                    none
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


dateToString : Maybe Time.Zone -> Time.Posix -> String
dateToString maybeTimezone posix =
    let
        timezone =
            Maybe.withDefault Time.utc maybeTimezone
    in
    posix |> Date.fromPosix timezone |> Date.format "MMMM ddd"


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
                Ok <| Just url

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
section userConfig hasError title headerExtra content =
    column
        [ spacing 8
        , Border.rounded 4
        , Ui.inputBackground userConfig.theme hasError
        , width fill
        ]
        [ row
            [ spacing 16 ]
            [ paragraph [ Font.bold ] [ text title ]
            , headerExtra
            ]
        , content
        ]


smallButton : Theme -> HtmlId -> msg -> String -> Element msg
smallButton theme htmlId onPress label =
    Input.button
        [ Border.width 2
        , Border.color <| theme.grey
        , paddingXY 8 2
        , Border.rounded 4
        , Font.center
        , Dom.idToAttribute htmlId |> htmlAttribute
        ]
        { onPress = Just onPress
        , label = text label
        }


multiline : Theme -> (String -> msg) -> String -> String -> Element msg
multiline theme onChange text labelText =
    Input.multiline
        [ width fill
        , height (px 200)
        , Background.color theme.background
        ]
        { text = text
        , onChange = onChange
        , placeholder = Nothing
        , label = Input.labelHidden labelText
        , spellcheck = True
        }


groupNameInputId : HtmlId
groupNameInputId =
    HtmlId.textInputId "groupPageGroupName"


copyPreviousEventButtonId : HtmlId
copyPreviousEventButtonId =
    HtmlId.buttonId "groupPage_CopyPreviousEvent"


groupNameTextInput : UserConfig -> (String -> msg) -> String -> String -> Element msg
groupNameTextInput userConfig onChange text labelText =
    Input.text
        [ width fill
        , paddingXY 8 4
        , Dom.idToAttribute groupNameInputId |> htmlAttribute
        , Background.color userConfig.theme.background
        ]
        { text = text
        , onChange = onChange
        , placeholder = Nothing
        , label = Input.labelHidden labelText
        }
