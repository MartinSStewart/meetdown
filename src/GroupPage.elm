module GroupPage exposing (Model, Msg, init, savedDescription, update, view)

import Description exposing (Description)
import Element exposing (Element)
import Element.Background
import Element.Border
import Element.Font
import Element.Input
import FrontendUser exposing (FrontendUser)
import Group exposing (Group)
import GroupName exposing (GroupName)
import Id exposing (Id, UserId)
import Name
import ProfileImage
import Time
import Ui
import Untrusted exposing (Untrusted)


type alias Model =
    { name : Editable GroupName
    , description : Editable Description
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


type alias Effects cmd =
    { none : cmd
    , changeDescription : Untrusted Description -> cmd
    }


init : Model
init =
    { name = Unchanged
    , description = Unchanged
    }


savedDescription : Model -> Model
savedDescription model =
    case model.description of
        Submitting _ ->
            { model | description = Unchanged }

        _ ->
            model


update : Effects cmd -> Group -> Id UserId -> Msg -> Model -> ( Model, cmd )
update effects group userId msg model =
    if Group.ownerId group == userId then
        case msg of
            PressedEditDescription ->
                ( { model | description = Group.description group |> Description.toString |> Editting }, effects.none )

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

    else
        ( model, effects.none )


view : Time.Posix -> FrontendUser -> Group -> Maybe ( Id UserId, Model ) -> Element Msg
view currentTime owner group maybeLoggedIn =
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
            [ Element.width Element.fill ]
            [ group
                |> Group.name
                |> GroupName.toString
                |> Ui.title
                |> Element.el [ Element.alignTop, Element.width Element.fill ]
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

                            Err Description.DescriptionTooLong ->
                                "Description is "
                                    ++ String.fromInt (String.length description)
                                    ++ " characters long. Keep it under "
                                    ++ String.fromInt Description.maxLength
                                    ++ "."
                                    |> Just
                in
                Element.column
                    [ Element.spacing 8
                    , Element.padding 8
                    , Element.Border.rounded 4
                    , Ui.inputBackground (error /= Nothing)
                    , Element.width Element.fill
                    ]
                    [ Element.row
                        [ Element.spacing 16 ]
                        [ Element.paragraph [ Element.Font.bold ] [ Element.text "Description" ]
                        , smallButton PressedResetDescription "Reset"
                        , smallSubmitButton False { onPress = PressedSaveDescription, label = "Save" }
                        ]
                    , multiline TypedDescription description ""
                    , Maybe.map Ui.error error |> Maybe.withDefault Element.none
                    ]

            Just (Submitting description) ->
                Element.column
                    [ Element.spacing 8
                    , Element.padding 8
                    , Element.Border.rounded 4
                    , Ui.inputBackground False
                    , Element.width Element.fill
                    ]
                    [ Element.row
                        [ Element.spacing 16 ]
                        [ Element.paragraph [ Element.Font.bold ] [ Element.text "Description" ]
                        , smallButton PressedResetDescription "Reset"
                        , smallSubmitButton True { onPress = PressedSaveDescription, label = "Save" }
                        ]
                    , multiline TypedDescription (Description.toString description) ""
                    ]

            _ ->
                Element.column
                    [ Element.spacing 8
                    , Element.padding 8
                    , Element.Border.rounded 4
                    , Ui.inputBackground False
                    , Element.width Element.fill
                    ]
                    [ Element.row
                        [ Element.spacing 16 ]
                        [ Element.paragraph [ Element.Font.bold ] [ Element.text "Description" ]
                        , if isOwner then
                            smallButton PressedEditDescription "Edit"

                          else
                            Element.none
                        ]
                    , Element.paragraph
                        []
                        [ group
                            |> Group.description
                            |> Description.toString
                            |> Element.text
                        ]
                    ]

        --, Ui.section "Description"
        --    (if Description.toString (Group.description group) == "" then
        --        Element.paragraph
        --            [ Element.Font.color <| Element.rgb 0.45 0.45 0.45
        --            , Element.Font.italic
        --            ]
        --            [ Element.text "No description provided" ]
        --
        --     else
        --        Element.paragraph
        --            []
        --            [ group
        --                |> Group.description
        --                |> Description.toString
        --                |> Element.text
        --            ]
        --    )
        , case futureEvents of
            nextEvent :: _ ->
                Ui.section "Next event"
                    (Element.paragraph
                        []
                        [ Element.text "No more events have been planned yet." ]
                    )

            [] ->
                Ui.section "Next event"
                    (Element.paragraph
                        []
                        [ Element.text "No more events have been planned yet." ]
                    )
        ]


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
        , label =
            Element.Input.labelAbove
                [ Element.paddingXY 4 0 ]
                (Element.paragraph [] [ Element.text labelText ])
        , spellcheck = True
        }
