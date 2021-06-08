module GroupPage exposing (CreateEventError(..), EventType(..), Model, Msg, addedNewEvent, createEventCancelId, createEventStartDateId, createEventStartTimeId, createEventSubmitId, createNewEventId, editDescriptionId, editGroupNameId, eventDescriptionInputId, eventDurationId, eventMeetingInPersonInputId, eventMeetingOnlineInputId, eventMeetingTypeId, eventNameInputId, init, joinEventButtonId, joinOrLeaveResponse, leaveEventButtonId, resetDescriptionId, resetGroupNameId, saveDescriptionId, saveGroupNameId, savedDescription, savedName, update, view)

import Address exposing (Address, Error(..))
import AssocList as Dict exposing (Dict)
import AssocSet as Set exposing (Set)
import Description exposing (Description)
import Duration
import Element exposing (Element)
import Element.Background
import Element.Border
import Element.Font
import Element.Input
import Event exposing (Event, EventType)
import EventDuration exposing (EventDuration)
import EventName exposing (EventName)
import FrontendUser exposing (FrontendUser)
import Group exposing (EventId, Group)
import GroupName exposing (GroupName)
import Html.Attributes
import Id exposing (ButtonId(..), HtmlId, Id, UserId)
import Link exposing (Link)
import List.Nonempty exposing (Nonempty(..))
import Name
import ProfileImage
import Quantity
import Time
import Time.Extra as Time
import Ui
import Untrusted exposing (Untrusted)


type alias Model =
    { name : Editable GroupName
    , description : Editable Description
    , addingNewEvent : Bool
    , newEvent : NewEvent
    , pendingJoinOrLeave : Dict EventId EventJoinOrLeaveStatus
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
    | ChangedNewEvent NewEvent
    | PressedCancelNewEvent
    | PressedCreateNewEvent
    | PressedLeaveEvent EventId
    | PressedJoinEvent EventId


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
    , joinEvent : EventId -> cmd
    , leaveEvent : EventId -> cmd
    }


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


init : Model
init =
    { name = Unchanged
    , description = Unchanged
    , addingNewEvent = False
    , newEvent = initNewEvent
    , pendingJoinOrLeave = Dict.empty
    }


initNewEvent : NewEvent
initNewEvent =
    { pressedSubmit = False
    , isSubmitting = False
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
    case result of
        Ok _ ->
            { model | addingNewEvent = False, newEvent = initNewEvent }

        Err _ ->
            model


update :
    Effects cmd
    -> { a | time : Time.Posix, timezone : Time.Zone }
    -> Group
    -> Maybe (Id UserId)
    -> Msg
    -> Model
    -> ( Model, cmd )
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
                )

            else
                ( model, effects.none )

        PressedSaveName ->
            if isOwner then
                case model.name of
                    Unchanged ->
                        ( model, effects.none )

                    Editting nameText ->
                        case GroupName.fromString nameText of
                            Ok name ->
                                ( { model | name = Submitting name }
                                , Untrusted.untrust name |> effects.changeName
                                )

                            Err _ ->
                                ( model, effects.none )

                    Submitting _ ->
                        ( model, effects.none )

            else
                ( model, effects.none )

        PressedResetName ->
            if isOwner then
                ( { model | name = Unchanged }, effects.none )

            else
                ( model, effects.none )

        TypedName name ->
            if isOwner then
                case model.name of
                    Editting _ ->
                        ( { model | name = Editting name }, effects.none )

                    _ ->
                        ( model, effects.none )

            else
                ( model, effects.none )

        PressedEditDescription ->
            if isOwner then
                ( { model | description = Group.description group |> Description.toString |> Editting }
                , effects.none
                )

            else
                ( model, effects.none )

        PressedSaveDescription ->
            if isOwner then
                case model.description of
                    Unchanged ->
                        ( model, effects.none )

                    Editting descriptionText ->
                        case Description.fromString descriptionText of
                            Ok description ->
                                ( { model | description = Submitting description }
                                , Untrusted.untrust description |> effects.changeDescription
                                )

                            Err _ ->
                                ( model, effects.none )

                    Submitting _ ->
                        ( model, effects.none )

            else
                ( model, effects.none )

        PressedResetDescription ->
            if isOwner then
                ( { model | description = Unchanged }, effects.none )

            else
                ( model, effects.none )

        TypedDescription description ->
            if isOwner then
                case model.description of
                    Editting _ ->
                        ( { model | description = Editting description }, effects.none )

                    _ ->
                        ( model, effects.none )

            else
                ( model, effects.none )

        PressedAddEvent ->
            if isOwner then
                ( { model | addingNewEvent = True }, effects.none )

            else
                ( model, effects.none )

        ChangedNewEvent newEvent ->
            if isOwner then
                ( { model | newEvent = newEvent }, effects.none )

            else
                ( model, effects.none )

        PressedCancelNewEvent ->
            if isOwner then
                ( { model | addingNewEvent = False }, effects.none )

            else
                ( model, effects.none )

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
                        ( { model | newEvent = { newEvent | isSubmitting = True } }
                        , effects.createEvent
                            (Untrusted.untrust name)
                            (Untrusted.untrust description)
                            (Untrusted.untrust eventType)
                            startTime
                            (Untrusted.untrust duration)
                        )
                    )
                    (EventName.fromString newEvent.eventName |> Result.toMaybe)
                    (Description.fromString newEvent.description |> Result.toMaybe)
                    maybeEventType
                    maybeStartTime
                    (validateDuration newEvent.duration |> Result.toMaybe)
                    |> Maybe.withDefault ( { model | newEvent = { newEvent | pressedSubmit = True } }, effects.none )

            else
                ( model, effects.none )

        PressedLeaveEvent eventId ->
            case Dict.get eventId model.pendingJoinOrLeave of
                Just JoinOrLeavePending ->
                    ( model, effects.none )

                _ ->
                    ( { model | pendingJoinOrLeave = Dict.insert eventId JoinOrLeavePending model.pendingJoinOrLeave }
                    , effects.leaveEvent eventId
                    )

        PressedJoinEvent eventId ->
            case Dict.get eventId model.pendingJoinOrLeave of
                Just JoinOrLeavePending ->
                    ( model, effects.none )

                _ ->
                    ( { model | pendingJoinOrLeave = Dict.insert eventId JoinOrLeavePending model.pendingJoinOrLeave }
                    , effects.joinEvent eventId
                    )


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
    let
        { pastEvents, futureEvents } =
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
        , section
            False
            "Next event"
            (if isOwner then
                if model.addingNewEvent then
                    Element.row
                        [ Element.spacing 8 ]
                        [ smallButton createEventCancelId PressedCancelNewEvent "Cancel"
                        , smallSubmitButton createEventSubmitId False { onPress = PressedCreateNewEvent, label = "Create new event" }
                        ]

                else
                    Element.el [] (smallButton createNewEventId PressedAddEvent "Add event")

             else
                Element.none
            )
            ((if model.addingNewEvent then
                [ newEventView currentTime timezone model.newEvent ]

              else
                []
             )
                ++ (case futureEvents of
                        [] ->
                            [ Element.paragraph
                                []
                                [ Element.text "No new events have been planned yet." ]
                            ]

                        _ ->
                            List.map (futureEventView timezone maybeUserId model.pendingJoinOrLeave) futureEvents
                   )
                |> List.intersperse Ui.hr
                |> Element.column
                    [ Element.width Element.fill, Element.spacing 8 ]
            )
        ]


resetGroupNameId =
    Id.buttonId "groupPageResetGroupNameButton"


editGroupNameId =
    Id.buttonId "groupPageEditGroupNameButton"


saveGroupNameId =
    Id.buttonId "groupPageSaveGroupNameButton"


resetDescriptionId =
    Id.buttonId "groupPageResetDescriptionButton"


editDescriptionId =
    Id.buttonId "groupPageEditDescriptionButton"


saveDescriptionId =
    Id.buttonId "groupPageSaveDescriptionButton"


createEventCancelId =
    Id.buttonId "groupPageCreateEventCancelButton"


createEventSubmitId =
    Id.buttonId "groupPageCreateEventSubmitButton"


createNewEventId =
    Id.buttonId "groupPageCreateNewEventButton"


futureEventView : Time.Zone -> Maybe (Id UserId) -> Dict EventId EventJoinOrLeaveStatus -> ( EventId, Event ) -> Element Msg
futureEventView timezone maybeUserId pendingJoinOrLeaveStatuses ( eventId, event ) =
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
        [ Event.name event |> EventName.toString |> Element.text |> List.singleton |> Element.paragraph [ Element.Font.bold ]
        , Event.description event |> Description.toString |> Element.text |> List.singleton |> Element.paragraph []
        , Event.startTime event
            |> datetimeToString (Just timezone)
            |> Element.text
        , case Event.eventType event of
            Event.MeetInPerson _ ->
                Element.paragraph [] [ Element.text "This is an in person event 🤝" ]

            Event.MeetOnline _ ->
                Element.paragraph [] [ Element.text "This is an online event 💻" ]
        , case attendeeCount of
            0 ->
                Element.text "No one plans on attending"

            1 ->
                Element.text "One person plans on attending"

            _ ->
                String.fromInt attendeeCount ++ " people plan on attending" |> Element.text
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


newEventView : Time.Posix -> Time.Zone -> NewEvent -> Element Msg
newEventView currentTime timezone event =
    Element.column
        [ Element.width Element.fill, Element.spacing 8 ]
        [ Ui.textInput
            eventNameInputId
            (\text -> ChangedNewEvent { event | eventName = text })
            event.eventName
            "Event name"
            (case ( event.pressedSubmit, EventName.fromString event.eventName ) of
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
            (case ( event.pressedSubmit, Description.fromString event.description ) of
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
            (case ( event.pressedSubmit, event.meetingType ) of
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
                    (case ( event.pressedSubmit, validateLink event.meetOnlineLink ) of
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
                    (case ( event.pressedSubmit, validateAddress event.meetInPersonAddress ) of
                        ( True, Err error ) ->
                            Just error

                        _ ->
                            Nothing
                    )

            Nothing ->
                Element.none
        , dateTimeInput currentTime timezone event
        , Element.column
            [ Element.spacing 4 ]
            [ Element.text "How many hours long is it?"
            , Ui.numberInput eventDurationId (\text -> ChangedNewEvent { event | duration = text }) event.duration
            , (case ( event.pressedSubmit, validateDuration event.duration ) of
                ( True, Err error ) ->
                    Just error

                _ ->
                    Nothing
              )
                |> Maybe.map Ui.error
                |> Maybe.withDefault Element.none
            ]
        ]


eventDurationId =
    Id.numberInputId "groupPageEventDurationId"


createEventStartDateId =
    Id.dateInputId "groupPageCreateEventStartDate"


createEventStartTimeId =
    Id.timeInputId "groupPageCreateEventStartTime"


dateTimeInput : Time.Posix -> Time.Zone -> NewEvent -> Element Msg
dateTimeInput currentTime timezone event =
    Element.column [ Element.spacing 4 ]
        [ Element.row [ Element.spacing 8 ]
            [ Element.column
                [ Element.spacing 4 ]
                [ Element.text "Start date"
                , Ui.dateInput
                    createEventStartDateId
                    (\text -> ChangedNewEvent { event | startDate = text })
                    currentTime
                    timezone
                    event.startDate
                ]
            , Element.column
                [ Element.spacing 4 ]
                [ Element.text "Start time"
                , Ui.timeInput
                    createEventStartTimeId
                    (\text -> ChangedNewEvent { event | startTime = text })
                    event.startTime
                ]
            ]
        , case ( event.pressedSubmit, validateDateTime currentTime timezone event.startDate event.startTime ) of
            ( True, Err error ) ->
                Ui.error error

            ( _, Ok datetime ) ->
                datetimeToString Nothing datetime
                    |> Element.text
                    |> List.singleton
                    |> Element.paragraph [ Element.Font.size 16 ]

            ( False, Err _ ) ->
                Element.none
        ]


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
        ++ String.fromInt (Time.toHour timezone datetime)
        ++ ":"
        ++ String.padLeft 2 '0' (String.fromInt (Time.toMinute timezone datetime))
        ++ (case maybeTimezone of
                Just _ ->
                    ""

                Nothing ->
                    " (UTC)"
           )


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
