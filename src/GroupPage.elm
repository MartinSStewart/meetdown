module GroupPage exposing (CreateEventError(..), EventType(..), Model, Msg, addedNewEvent, createEventCancelId, createEventStartDateId, createEventStartTimeId, createEventSubmitId, createNewEventId, editDescriptionId, editEventResponse, editGroupNameId, eventDescriptionInputId, eventDurationId, eventMeetingInPersonInputId, eventMeetingOnlineInputId, eventMeetingTypeId, eventNameInputId, init, joinEventButtonId, joinOrLeaveResponse, leaveEventButtonId, resetDescriptionId, resetGroupNameId, saveDescriptionId, saveGroupNameId, savedDescription, savedName, update, view)

import Address exposing (Address, Error(..))
import AssocList as Dict exposing (Dict)
import AssocSet as Set exposing (Set)
import Date
import Description exposing (Description)
import Duration exposing (Duration)
import Element exposing (Element)
import Element.Background
import Element.Border
import Element.Font
import Element.Input
import Event exposing (Event, EventType)
import EventDuration exposing (EventDuration)
import EventName exposing (EventName)
import FrontendUser exposing (FrontendUser)
import Group exposing (EditEventError(..), EventId, Group)
import GroupName exposing (GroupName)
import Html.Attributes
import Id exposing (ButtonId(..), HtmlId, Id, UserId)
import Link exposing (Link)
import List.Extra as List
import List.Nonempty exposing (Nonempty(..))
import Name
import ProfileImage
import Quantity exposing (Quantity)
import Time
import Time.Extra as Time
import Ui
import Untrusted exposing (Untrusted)


type alias Model =
    { name : Editable GroupName
    , description : Editable Description
    , eventOverlay : Maybe EventOverlay
    , newEvent : NewEvent
    , pendingJoinOrLeave : Dict EventId EventJoinOrLeaveStatus
    , showAllFutureEvents : Bool
    }


type EventJoinOrLeaveStatus
    = JoinOrLeavePending
    | JoinOrLeaveFailure


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
        -> cmd
    , editEvent :
        EventId
        -> Untrusted EventName
        -> Untrusted Description
        -> Untrusted Event.EventType
        -> Time.Posix
        -> Untrusted EventDuration
        -> cmd
    , joinEvent : EventId -> cmd
    , leaveEvent : EventId -> cmd
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
    }


init : Model
init =
    { name = Unchanged
    , description = Unchanged
    , eventOverlay = Nothing
    , newEvent = initNewEvent
    , pendingJoinOrLeave = Dict.empty
    , showAllFutureEvents = False
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


update :
    Effects cmd
    -> { a | time : Time.Posix, timezone : Time.Zone }
    -> Group
    -> Maybe (Id UserId)
    -> Msg
    -> Model
    -> ( Model, cmd, { showLogin : Bool } )
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
                , { showLogin = False }
                )

            else
                ( model, effects.none, { showLogin = False } )

        PressedSaveName ->
            if isOwner then
                case model.name of
                    Unchanged ->
                        ( model, effects.none, { showLogin = False } )

                    Editting nameText ->
                        case GroupName.fromString nameText of
                            Ok name ->
                                ( { model | name = Submitting name }
                                , Untrusted.untrust name |> effects.changeName
                                , { showLogin = False }
                                )

                            Err _ ->
                                ( model, effects.none, { showLogin = False } )

                    Submitting _ ->
                        ( model, effects.none, { showLogin = False } )

            else
                ( model, effects.none, { showLogin = False } )

        PressedResetName ->
            if isOwner then
                ( { model | name = Unchanged }, effects.none, { showLogin = False } )

            else
                ( model, effects.none, { showLogin = False } )

        TypedName name ->
            if isOwner then
                case model.name of
                    Editting _ ->
                        ( { model | name = Editting name }, effects.none, { showLogin = False } )

                    _ ->
                        ( model, effects.none, { showLogin = False } )

            else
                ( model, effects.none, { showLogin = False } )

        PressedEditDescription ->
            if isOwner then
                ( { model | description = Group.description group |> Description.toString |> Editting }
                , effects.none
                , { showLogin = False }
                )

            else
                ( model, effects.none, { showLogin = False } )

        PressedSaveDescription ->
            if isOwner then
                case model.description of
                    Unchanged ->
                        ( model, effects.none, { showLogin = False } )

                    Editting descriptionText ->
                        case Description.fromString descriptionText of
                            Ok description ->
                                ( { model | description = Submitting description }
                                , Untrusted.untrust description |> effects.changeDescription
                                , { showLogin = False }
                                )

                            Err _ ->
                                ( model, effects.none, { showLogin = False } )

                    Submitting _ ->
                        ( model, effects.none, { showLogin = False } )

            else
                ( model, effects.none, { showLogin = False } )

        PressedResetDescription ->
            if isOwner then
                ( { model | description = Unchanged }, effects.none, { showLogin = False } )

            else
                ( model, effects.none, { showLogin = False } )

        TypedDescription description ->
            if isOwner then
                case model.description of
                    Editting _ ->
                        ( { model | description = Editting description }, effects.none, { showLogin = False } )

                    _ ->
                        ( model, effects.none, { showLogin = False } )

            else
                ( model, effects.none, { showLogin = False } )

        PressedAddEvent ->
            if isOwner && model.eventOverlay == Nothing then
                ( { model | eventOverlay = Just AddingNewEvent }, effects.none, { showLogin = False } )

            else
                ( model, effects.none, { showLogin = False } )

        PressedShowAllFutureEvents ->
            ( { model | showAllFutureEvents = True }, effects.none, { showLogin = False } )

        PressedShowFirstFutureEvents ->
            ( { model | showAllFutureEvents = False }, effects.none, { showLogin = False } )

        ChangedNewEvent newEvent ->
            if isOwner then
                ( { model | newEvent = newEvent }, effects.none, { showLogin = False } )

            else
                ( model, effects.none, { showLogin = False } )

        PressedCancelNewEvent ->
            if isOwner then
                case model.eventOverlay of
                    Just AddingNewEvent ->
                        ( { model | eventOverlay = Nothing }, effects.none, { showLogin = False } )

                    _ ->
                        ( model, effects.none, { showLogin = False } )

            else
                ( model, effects.none, { showLogin = False } )

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
                    (\name description eventType startTime duration ->
                        ( { model | newEvent = { newEvent | submitStatus = IsSubmitting } }
                        , effects.createEvent
                            (Untrusted.untrust name)
                            (Untrusted.untrust description)
                            (Untrusted.untrust eventType)
                            startTime
                            (Untrusted.untrust duration)
                        , { showLogin = False }
                        )
                    )
                    (EventName.fromString newEvent.eventName |> Result.toMaybe)
                    (Description.fromString newEvent.description |> Result.toMaybe)
                    maybeEventType
                    maybeStartTime
                    (validateDuration newEvent.duration |> Result.toMaybe)
                    |> Maybe.withDefault
                        ( { model | newEvent = pressSubmit model.newEvent }
                        , effects.none
                        , { showLogin = False }
                        )

            else
                ( model, effects.none, { showLogin = False } )

        PressedLeaveEvent eventId ->
            case Dict.get eventId model.pendingJoinOrLeave of
                Just JoinOrLeavePending ->
                    ( model, effects.none, { showLogin = False } )

                _ ->
                    ( { model | pendingJoinOrLeave = Dict.insert eventId JoinOrLeavePending model.pendingJoinOrLeave }
                    , effects.leaveEvent eventId
                    , { showLogin = False }
                    )

        PressedJoinEvent eventId ->
            case maybeUserId of
                Just _ ->
                    case Dict.get eventId model.pendingJoinOrLeave of
                        Just JoinOrLeavePending ->
                            ( model, effects.none, { showLogin = False } )

                        _ ->
                            ( { model | pendingJoinOrLeave = Dict.insert eventId JoinOrLeavePending model.pendingJoinOrLeave }
                            , effects.joinEvent eventId
                            , { showLogin = False }
                            )

                Nothing ->
                    ( model, effects.none, { showLogin = True } )

        PressedEditEvent eventId ->
            if isOwner && model.eventOverlay == Nothing then
                case Group.events config.time group |> .futureEvents |> List.find (Tuple.first >> (==) eventId) of
                    Just ( _, event ) ->
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
                                            |> String.fromFloat
                                            |> String.left 4
                                    }
                                    |> Just
                          }
                        , effects.none
                        , { showLogin = False }
                        )

                    Nothing ->
                        ( model, effects.none, { showLogin = False } )

            else
                ( model, effects.none, { showLogin = False } )

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
            , { showLogin = False }
            )

        PressedSubmitEditEvent ->
            case model.eventOverlay of
                Just (EdittingEvent eventId event) ->
                    if event.submitStatus == IsSubmitting then
                        ( model, effects.none, { showLogin = False } )

                    else if isOwner then
                        let
                            maybeEventType : Maybe Event.EventType
                            maybeEventType =
                                case event.meetingType of
                                    MeetOnline ->
                                        validateLink event.meetOnlineLink
                                            |> Result.toMaybe
                                            |> Maybe.map Event.MeetOnline

                                    MeetInPerson ->
                                        validateAddress event.meetInPersonAddress
                                            |> Result.toMaybe
                                            |> Maybe.map Event.MeetInPerson

                            maybeStartTime =
                                validateDateTime config.time config.timezone event.startDate event.startTime
                                    |> Result.toMaybe
                        in
                        Maybe.map5
                            (\name description eventType startTime duration ->
                                ( { model
                                    | eventOverlay =
                                        EdittingEvent eventId
                                            { event | submitStatus = IsSubmitting }
                                            |> Just
                                  }
                                , effects.editEvent
                                    eventId
                                    (Untrusted.untrust name)
                                    (Untrusted.untrust description)
                                    (Untrusted.untrust eventType)
                                    startTime
                                    (Untrusted.untrust duration)
                                , { showLogin = False }
                                )
                            )
                            (EventName.fromString event.eventName |> Result.toMaybe)
                            (Description.fromString event.description |> Result.toMaybe)
                            maybeEventType
                            maybeStartTime
                            (validateDuration event.duration |> Result.toMaybe)
                            |> Maybe.withDefault
                                ( { model
                                    | eventOverlay = EdittingEvent eventId (pressSubmit event) |> Just
                                  }
                                , effects.none
                                , { showLogin = False }
                                )

                    else
                        ( model, effects.none, { showLogin = False } )

                _ ->
                    ( model, effects.none, { showLogin = False } )

        PressedCancelEditEvent ->
            case model.eventOverlay of
                Just (EdittingEvent _ _) ->
                    ( { model | eventOverlay = Nothing }, effects.none, { showLogin = False } )

                _ ->
                    ( model, effects.none, { showLogin = False } )


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


joinOrLeaveResponse : EventId -> Result () () -> Model -> Model
joinOrLeaveResponse eventId result model =
    { model
        | pendingJoinOrLeave =
            case result of
                Ok () ->
                    Dict.remove eventId model.pendingJoinOrLeave

                Err () ->
                    Dict.insert eventId JoinOrLeaveFailure model.pendingJoinOrLeave
    }


view : Time.Posix -> Time.Zone -> FrontendUser -> Group -> Model -> Maybe (Id UserId) -> Element Msg
view currentTime timezone owner group model maybeUserId =
    case model.eventOverlay of
        Just AddingNewEvent ->
            newEventView currentTime timezone model.newEvent

        Just (EdittingEvent _ event) ->
            editEventView currentTime timezone event

        Nothing ->
            groupView currentTime timezone owner group model maybeUserId


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
        [ Element.spacing 8, Element.padding 8, Element.width Element.fill ]
        [ Element.row
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
                            [ Ui.titleFontSize, Element.width <| Element.maximum 800 Element.fill ]
                            (textInput TypedName name "Group name")
                        , Maybe.map Ui.error error |> Maybe.withDefault Element.none
                        , Element.row
                            [ Element.spacing 16, Element.paddingXY 8 0 ]
                            [ smallButton resetGroupNameId PressedResetName "Reset"
                            , smallSubmitButton saveGroupNameId False { onPress = PressedSaveName, label = "Save" }
                            ]
                        ]

                    Submitting name ->
                        [ Element.el
                            [ Ui.titleFontSize, Element.width <| Element.maximum 800 Element.fill ]
                            (textInput TypedName (GroupName.toString name) "Group name")
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
                    (Element.paragraph
                        []
                        [ group
                            |> Group.description
                            |> Description.toString
                            |> Element.text
                        ]
                    )
        , case ongoingEvent of
            Just ( _, ongoing ) ->
                section
                    False
                    "Ongoing event"
                    Element.none
                    (ongoingEventView currentTime maybeUserId ongoing)

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
                |> List.intersperse Ui.hr
                |> Element.column
                    [ Element.width Element.fill, Element.spacing 8 ]
            )
        , case pastEvents of
            head :: rest ->
                section
                    False
                    "Past events"
                    Element.none
                    (List.map (Tuple.second >> pastEventView currentTime maybeUserId) (head :: rest)
                        |> List.intersperse Ui.hr
                        |> Element.column
                            [ Element.width Element.fill, Element.spacing 8 ]
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


timeDifference : Time.Posix -> Time.Posix -> String
timeDifference start end =
    let
        difference : Duration
        difference =
            Duration.from start end |> Quantity.abs

        months =
            Duration.inDays difference / 30 |> floor

        weeks =
            Duration.inWeeks difference |> floor

        days =
            Duration.inDays difference |> floor

        hours =
            Duration.inHours difference |> floor

        minutes =
            Duration.inMinutes difference |> round

        suffix =
            if Time.posixToMillis start <= Time.posixToMillis end then
                ""

            else
                " ago"
    in
    if months >= 2 then
        String.fromInt months ++ " months" ++ suffix

    else if weeks >= 2 then
        String.fromInt weeks ++ " weeks" ++ suffix

    else if days > 1 then
        String.fromInt days ++ " days" ++ suffix

    else if days == 1 then
        if Time.posixToMillis start <= Time.posixToMillis end then
            "tomorrow"

        else
            "yesterday"

    else if hours > 6 then
        String.fromInt hours ++ " hours" ++ suffix

    else if hours > 1 then
        (String.fromFloat (Duration.inHours difference) |> String.left 3) ++ " hours" ++ suffix

    else if hours == 1 then
        "1 hour" ++ suffix

    else if minutes > 1 then
        String.fromInt minutes ++ " minutes" ++ suffix

    else if minutes == 1 then
        "1 minute" ++ suffix

    else
        "now"


ongoingEventView : Time.Posix -> Maybe (Id UserId) -> Event -> Element Msg
ongoingEventView currentTime maybeUserId event =
    let
        isAttending =
            maybeUserId |> Maybe.map (\userId -> Set.member userId (Event.attendees event)) |> Maybe.withDefault False

        attendeeCount =
            Event.attendees event |> Set.size
    in
    Element.column
        [ Element.width Element.fill, Element.spacing 8, Element.paddingXY 16 0 ]
        [ Event.name event |> EventName.toString |> Element.text |> List.singleton |> Element.paragraph [ Element.Font.bold ]
        , Event.description event |> Description.toString |> Element.text |> List.singleton |> Element.paragraph []
        , "Ends in "
            ++ timeDifference currentTime (Event.endTime event)
            |> Element.text
            |> List.singleton
            |> Element.paragraph []
        , case Event.eventType event of
            Event.MeetInPerson _ ->
                Element.paragraph [] [ Element.text "This is an in person event 🤝" ]

            Event.MeetOnline _ ->
                Element.paragraph [] [ Element.text "This is an online event 💻" ]
        , case attendeeCount of
            0 ->
                Element.text "No one plans on attending"

            1 ->
                if isAttending then
                    Element.text "One person is attending (it's you)"

                else
                    Element.text "One person is attending"

            _ ->
                String.fromInt attendeeCount
                    ++ " people are attending"
                    ++ (if isAttending then
                            "(including you)"

                        else
                            ""
                       )
                    |> Element.text
        ]


pastEventView : Time.Posix -> Maybe (Id UserId) -> Event -> Element Msg
pastEventView currentTime maybeUserId event =
    let
        isAttending =
            maybeUserId |> Maybe.map (\userId -> Set.member userId (Event.attendees event)) |> Maybe.withDefault False

        attendeeCount =
            Event.attendees event |> Set.size
    in
    Element.column
        [ Element.width Element.fill, Element.spacing 8, Element.paddingXY 16 0 ]
        [ Event.name event |> EventName.toString |> Element.text |> List.singleton |> Element.paragraph [ Element.Font.bold ]
        , Event.description event |> Description.toString |> Element.text |> List.singleton |> Element.paragraph []
        , "Ended "
            ++ timeDifference currentTime (Event.endTime event)
            |> Element.text
            |> List.singleton
            |> Element.paragraph []
        , EventDuration.toString (Event.duration event) ++ " long" |> Element.text
        , case Event.eventType event of
            Event.MeetInPerson _ ->
                Element.paragraph [] [ Element.text "This is an in person event 🤝" ]

            Event.MeetOnline _ ->
                Element.paragraph [] [ Element.text "This is an online event 💻" ]
        , case attendeeCount of
            0 ->
                Element.text "No one attended 💔"

            1 ->
                if isAttending then
                    Element.text "One person attended (it was you)"

                else
                    Element.text "One person attended"

            _ ->
                String.fromInt attendeeCount
                    ++ " people attended"
                    ++ (if isAttending then
                            "(you included)"

                        else
                            ""
                       )
                    |> Element.text
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
    in
    Element.column
        [ Element.width Element.fill, Element.spacing 8, Element.paddingXY 16 0 ]
        [ Element.row
            [ Element.spacing 16 ]
            [ Event.name event |> EventName.toString |> Element.text |> List.singleton |> Element.paragraph [ Element.Font.bold ]
            , if isOwner then
                smallButton editEventId (PressedEditEvent eventId) "Edit"

              else
                Element.none
            ]
        , Event.description event |> Description.toString |> Element.text |> List.singleton |> Element.paragraph []
        , datetimeToString (Just timezone) (Event.startTime event)
            ++ " (Starts in "
            ++ timeDifference currentTime (Event.startTime event)
            ++ ")"
            |> Element.text
            |> List.singleton
            |> Element.paragraph []
        , EventDuration.toString (Event.duration event) ++ " long" |> Element.text
        , case Event.eventType event of
            Event.MeetInPerson _ ->
                Element.paragraph [] [ Element.text "This is an in person event 🤝" ]

            Event.MeetOnline _ ->
                Element.paragraph [] [ Element.text "This is an online event 💻" ]
        , case attendeeCount of
            0 ->
                Element.text "No one plans on attending"

            1 ->
                if isAttending then
                    Element.text "One person plans on attending (it's you)"

                else
                    Element.text "One person plans on attending"

            _ ->
                String.fromInt attendeeCount
                    ++ " people plan on attending"
                    ++ (if isAttending then
                            "(including you)"

                        else
                            ""
                       )
                    |> Element.text
        , if isAttending then
            Ui.submitButton
                leaveEventButtonId
                (maybeJoinOrLeaveStatus == Just JoinOrLeavePending)
                { onPress = PressedLeaveEvent eventId, label = "Leave event" }

          else
            Ui.submitButton
                joinEventButtonId
                (maybeJoinOrLeaveStatus == Just JoinOrLeavePending)
                { onPress = PressedJoinEvent eventId, label = "Join event" }
        , case maybeJoinOrLeaveStatus of
            Just JoinOrLeaveFailure ->
                if isAttending then
                    Ui.error "Failed to leave event"

                else
                    Ui.error "Failed to join event"

            _ ->
                Element.none
        ]


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


editEventView : Time.Posix -> Time.Zone -> EditEvent -> Element Msg
editEventView currentTime timezone event =
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
        [ Element.spacing 8, Element.padding 8, Element.width Element.fill ]
        [ Ui.title "Edit event"
        , Ui.textInput
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
            "Event description"
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
                    "Meeting url (you can add this later)"
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
                    "Meeting address (you can add this later)"
                    (case ( pressedSubmit, validateAddress event.meetInPersonAddress ) of
                        ( True, Err error ) ->
                            Just error

                        _ ->
                            Nothing
                    )
        , Ui.dateTimeInput
            { dateInputId = createEventStartDateId
            , timeInputId = createEventStartTimeId
            , dateChanged = \text -> ChangedEditEvent { event | startDate = text }
            , timeChanged = \text -> ChangedEditEvent { event | startTime = text }
            , labelText = "When does it start?"
            , minTime = currentTime
            , timezone = timezone
            , dateText = event.startDate
            , timeText = event.startTime
            , maybeError =
                case ( pressedSubmit, validateDateTime currentTime timezone event.startDate event.startTime ) of
                    ( True, Err error ) ->
                        Just error

                    _ ->
                        Nothing
            }
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
        , Element.row
            [ Element.spacing 8 ]
            [ Ui.submitButton createEventSubmitId isSubmitting { onPress = PressedSubmitEditEvent, label = "Update event" }
            , Ui.button createEventCancelId { onPress = PressedCancelEditEvent, label = "Cancel" }
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
        [ Element.spacing 8, Element.padding 8, Element.width Element.fill ]
        [ Ui.title "New event"
        , Ui.textInput
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
            "Event description"
            (case ( pressedSubmit, Description.fromString event.description ) of
                ( True, Err error ) ->
                    Description.errorToString event.description error |> Just

                _ ->
                    Nothing
            )
        , Ui.radioGroup
            eventMeetingTypeId
            (\meetingType -> ChangedNewEvent { event | meetingType = Just meetingType })
            (Nonempty MeetOnline [ MeetInPerson ])
            event.meetingType
            (\a ->
                case a of
                    MeetOnline ->
                        "This event will be online"

                    MeetInPerson ->
                        "This event will be in person"
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
                    "Meeting url (you can add this later)"
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
                    "Meeting address (you can add this later)"
                    (case ( pressedSubmit, validateAddress event.meetInPersonAddress ) of
                        ( True, Err error ) ->
                            Just error

                        _ ->
                            Nothing
                    )

            Nothing ->
                Element.none
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
        , Element.row
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


eventDurationId =
    Id.numberInputId "groupPageEventDurationId"


createEventStartDateId =
    Id.dateInputId "groupPageCreateEventStartDate"


createEventStartTimeId =
    Id.timeInputId "groupPageCreateEventStartTime"


datetimeToString : Maybe Time.Zone -> Time.Posix -> String
datetimeToString maybeTimezone datetime =
    let
        timezone =
            Maybe.withDefault Time.utc maybeTimezone
    in
    monthToText datetime Time.utc
        ++ " "
        ++ dayToText datetime timezone
        ++ ", "
        ++ Ui.timeToString timezone datetime
        ++ (case maybeTimezone of
                Just _ ->
                    ""

                Nothing ->
                    " (UTC)"
           )


dateToString : Maybe Time.Zone -> Time.Posix -> String
dateToString maybeTimezone datetime =
    let
        timezone =
            Maybe.withDefault Time.utc maybeTimezone
    in
    monthToText datetime Time.utc ++ " " ++ dayToText datetime timezone


dayToText : Time.Posix -> Time.Zone -> String
dayToText time timezone =
    case Time.toDay timezone time of
        1 ->
            "1st"

        2 ->
            "2nd"

        3 ->
            "3rd"

        n ->
            String.fromInt n ++ "th"


monthToText : Time.Posix -> Time.Zone -> String
monthToText time timezone =
    case Time.toMonth timezone time of
        Time.Jan ->
            "January"

        Time.Feb ->
            "February"

        Time.Mar ->
            "March"

        Time.Apr ->
            "April"

        Time.May ->
            "May"

        Time.Jun ->
            "June"

        Time.Jul ->
            "July"

        Time.Aug ->
            "August"

        Time.Sep ->
            "September"

        Time.Oct ->
            "October"

        Time.Nov ->
            "November"

        Time.Dec ->
            "December"


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
        [ Element.Background.color <| Element.rgb 0.9 0.9 0.9
        , Element.Border.width 2
        , Element.Border.color <| Element.rgb 0.3 0.3 0.3
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


textInput : (String -> msg) -> String -> String -> Element msg
textInput onChange text labelText =
    Element.Input.text
        [ Element.width Element.fill, Element.paddingXY 8 4 ]
        { text = text
        , onChange = onChange
        , placeholder = Nothing
        , label = Element.Input.labelHidden labelText
        }
