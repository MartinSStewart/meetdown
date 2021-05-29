module GroupPage exposing (CreateEventError(..), EventType(..), Model, Msg, addedNewEvent, init, savedDescription, savedName, update, view)

import Address exposing (Address, Error(..))
import Description exposing (Description)
import Element exposing (Element)
import Element.Background
import Element.Border
import Element.Font
import Element.Input
import Event exposing (Event, EventType)
import EventDuration exposing (EventDuration)
import EventName exposing (EventName)
import FrontendUser exposing (FrontendUser)
import Group exposing (Group)
import GroupName exposing (GroupName)
import Html
import Html.Attributes
import Html.Events
import Id exposing (Id, UserId)
import Link exposing (Link)
import List.Nonempty exposing (Nonempty(..))
import Name
import ProfileImage
import Time
import Ui
import Untrusted exposing (Untrusted)


type alias Model =
    { name : Editable GroupName
    , description : Editable Description
    , addingNewEvent : Bool
    , newEvent : NewEvent
    }


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
    | EventOverlapsAnotherEvent
    | TooManyEvents


addedNewEvent : Result CreateEventError Event -> Model -> Model
addedNewEvent result model =
    case result of
        Ok _ ->
            { model | addingNewEvent = False, newEvent = initNewEvent }

        Err _ ->
            model


update : Effects cmd -> Group -> Id UserId -> Msg -> Model -> ( Model, cmd )
update effects group userId msg model =
    if Group.ownerId group == userId then
        case msg of
            PressedEditName ->
                ( { model | name = Group.name group |> GroupName.toString |> Editting }
                , effects.none
                )

            PressedSaveName ->
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

            PressedResetName ->
                ( { model | name = Unchanged }, effects.none )

            TypedName name ->
                case model.name of
                    Editting _ ->
                        ( { model | name = Editting name }, effects.none )

                    _ ->
                        ( model, effects.none )

            PressedEditDescription ->
                ( { model | description = Group.description group |> Description.toString |> Editting }
                , effects.none
                )

            PressedSaveDescription ->
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

            PressedResetDescription ->
                ( { model | description = Unchanged }, effects.none )

            TypedDescription description ->
                case model.description of
                    Editting _ ->
                        ( { model | description = Editting description }, effects.none )

                    _ ->
                        ( model, effects.none )

            PressedAddEvent ->
                ( { model | addingNewEvent = True }, effects.none )

            ChangedNewEvent newEvent ->
                ( { model | newEvent = newEvent }, effects.none )

            PressedCancelNewEvent ->
                ( { model | addingNewEvent = False }, effects.none )

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
                        Nothing
                in
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


view : Time.Posix -> Time.Zone -> FrontendUser -> Group -> Maybe ( Id UserId, Model ) -> Element Msg
view currentTime timezone owner group maybeLoggedIn =
    let
        { pastEvents, futureEvents } =
            Group.events currentTime group

        isOwner =
            case maybeLoggedIn of
                Just ( userId, _ ) ->
                    Group.ownerId group == userId

                Nothing ->
                    False
    in
    Element.column
        [ Element.spacing 8, Element.padding 8, Element.width Element.fill ]
        [ Element.row
            [ Element.width Element.fill, Element.spacing 8 ]
            [ Element.column [ Element.alignTop, Element.width Element.fill, Element.spacing 4 ]
                (case Maybe.map (Tuple.second >> .name) maybeLoggedIn of
                    Just (Editting name) ->
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
                            [ smallButton PressedResetName "Reset"
                            , smallSubmitButton False { onPress = PressedSaveName, label = "Save" }
                            ]
                        ]

                    Just (Submitting name) ->
                        [ Element.el
                            [ Ui.titleFontSize, Element.width <| Element.maximum 800 Element.fill ]
                            (textInput TypedName (GroupName.toString name) "Group name")
                        , Element.row
                            [ Element.spacing 16, Element.paddingXY 8 0 ]
                            [ smallButton PressedResetName "Reset"
                            , smallSubmitButton True { onPress = PressedSaveName, label = "Save" }
                            ]
                        ]

                    _ ->
                        [ group
                            |> Group.name
                            |> GroupName.toString
                            |> Ui.title
                            |> Element.el [ Element.paddingXY 8 4 ]
                        , if isOwner then
                            Element.el [ Element.paddingXY 8 0 ] (smallButton PressedEditName "Edit")

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
        , case Maybe.map (Tuple.second >> .description) maybeLoggedIn of
            Just (Editting description) ->
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
                        [ smallButton PressedResetDescription "Reset"
                        , smallSubmitButton False { onPress = PressedSaveDescription, label = "Save" }
                        ]
                    )
                    (Element.column
                        [ Element.spacing 8, Element.width Element.fill ]
                        [ multiline TypedDescription description "Group description"
                        , Maybe.map Ui.error error |> Maybe.withDefault Element.none
                        ]
                    )

            Just (Submitting description) ->
                section
                    False
                    "Description"
                    (Element.row [ Element.spacing 8 ]
                        [ smallButton PressedResetDescription "Reset"
                        , smallSubmitButton True { onPress = PressedSaveDescription, label = "Save" }
                        ]
                    )
                    (multiline TypedDescription (Description.toString description) "")

            _ ->
                section
                    False
                    "Description"
                    (if isOwner then
                        -- Extra el prevents focus on both reset and save buttons
                        Element.el [] (smallButton PressedEditDescription "Edit")

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
                case maybeLoggedIn of
                    Just ( _, model ) ->
                        if model.addingNewEvent then
                            Element.row
                                [ Element.spacing 8 ]
                                [ smallButton PressedCancelNewEvent "Cancel"
                                , smallSubmitButton False { onPress = PressedCreateNewEvent, label = "Create new event" }
                                ]

                        else
                            Element.el [] (smallButton PressedAddEvent "Add event")

                    Nothing ->
                        Element.none

             else
                Element.none
            )
            (case Maybe.map Tuple.second maybeLoggedIn of
                Just model ->
                    if model.addingNewEvent then
                        newEventView currentTime timezone model.newEvent

                    else
                        Element.paragraph
                            []
                            [ Element.text "No more events have been planned yet." ]

                _ ->
                    Element.paragraph
                        []
                        [ Element.text "No more events have been planned yet." ]
            )
        ]


timestamp : Time.Posix -> Time.Zone -> String
timestamp time timezone =
    let
        monthValue =
            case Time.toMonth timezone time of
                Time.Jan ->
                    "01"

                Time.Feb ->
                    "02"

                Time.Mar ->
                    "03"

                Time.Apr ->
                    "04"

                Time.May ->
                    "05"

                Time.Jun ->
                    "06"

                Time.Jul ->
                    "07"

                Time.Aug ->
                    "08"

                Time.Sep ->
                    "09"

                Time.Oct ->
                    "10"

                Time.Nov ->
                    "11"

                Time.Dec ->
                    "12"
    in
    String.fromInt (Time.toYear timezone time)
        ++ "-"
        ++ monthValue
        ++ "-"
        ++ String.padLeft 2 '0' (String.fromInt (Time.toDay timezone time))


type EventType
    = MeetOnline
    | MeetInPerson


newEventView : Time.Posix -> Time.Zone -> NewEvent -> Element Msg
newEventView currentTime timezone event =
    Element.column
        [ Element.width Element.fill ]
        [ Ui.textInput
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
                    (\text -> ChangedNewEvent { event | meetOnlineLink = text })
                    event.meetOnlineLink
                    "Meeting url (you can add this later)"
                    (case ( event.pressedSubmit, validateLink event.meetOnlineLink |> Debug.log "a" ) of
                        ( True, Err error ) ->
                            Just error

                        _ ->
                            Nothing
                    )

            Just MeetInPerson ->
                Ui.textInput
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
        , Element.column
            [ Element.spacing 4 ]
            [ Element.text "Start date"
            , Element.html <|
                Html.input
                    [ Html.Attributes.type_ "date"
                    , Html.Attributes.min (timestamp currentTime timezone)
                    , Html.Events.onInput (\text -> ChangedNewEvent { event | startDate = Debug.log "date" text })
                    ]
                    []
            ]
        , Element.column
            [ Element.spacing 4 ]
            [ Element.text "Start time"
            , Element.html <|
                Html.input
                    [ Html.Attributes.type_ "time"
                    , Html.Events.onInput (\text -> ChangedNewEvent { event | startTime = Debug.log "time" text })
                    ]
                    []
            ]
        , Element.column
            [ Element.spacing 4 ]
            [ Element.text "How many hours long is it?"
            , Element.html <|
                Html.input
                    [ Html.Attributes.type_ "number"
                    , Html.Events.onInput (\text -> ChangedNewEvent { event | duration = text })
                    ]
                    []
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



--time: "22:00" 0-1234:259:10
--date: "2021-05-31"


validateDateTime : Time.Zone -> String -> String -> Result String Time.Posix
validateDateTime timezone date time =
    case String.split "-" date |> List.map String.toInt of
        [ Just year, Just month, Just day ] ->
            case String.split ":" time |> List.map String.toInt of
                [ Just hour, Just minute ] ->
                    Err ""

                _ ->
                    Err "Invalid time format. Expected something like 22:59"

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


smallButton : msg -> String -> Element msg
smallButton onPress label =
    Element.Input.button
        [ Element.Background.color <| Element.rgb 0.9 0.9 0.9
        , Element.Border.width 2
        , Element.Border.color <| Element.rgb 0.3 0.3 0.3
        , Element.paddingXY 8 2
        , Element.Border.rounded 4
        , Element.Font.center
        ]
        { onPress = Just onPress
        , label = Element.text label
        }


smallSubmitButton : Bool -> { onPress : msg, label : String } -> Element msg
smallSubmitButton isSubmitting { onPress, label } =
    Element.Input.button
        [ Element.Background.color <| Element.rgb 0.1 0.6 0.25
        , Element.paddingXY 8 4
        , Element.Border.rounded 4
        , Element.Font.center
        , Element.Font.color <| Element.rgb 1 1 1
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
