module GroupForm exposing
    ( CreateGroupError(..)
    , GroupFormValidated
    , GroupVisibility(..)
    , Model
    , Msg
    , OutMsg(..)
    , init
    , submitFailed
    , update
    , view
    )

import Description exposing (Description)
import Element exposing (Element)
import GroupName exposing (GroupName)
import List.Nonempty exposing (Nonempty(..))
import Ui


type GroupVisibility
    = PrivateGroup
    | PublicGroup


type Model
    = Editting Form
    | Submitting GroupFormValidated
    | SubmitFailed CreateGroupError Form


type alias GroupFormValidated =
    { name : GroupName
    , description : Description
    , visibility : GroupVisibility
    }


validatedToForm : GroupFormValidated -> Form
validatedToForm validated =
    { pressedSubmit = False
    , name = GroupName.toString validated.name
    , description = Description.toString validated.description
    , visibility = Just validated.visibility
    }


type Msg
    = FormChanged Form
    | PressedSubmit
    | PressedClear


type alias Form =
    { pressedSubmit : Bool
    , name : String
    , description : String
    , visibility : Maybe GroupVisibility
    }


init : Model
init =
    Editting initForm


initForm : Form
initForm =
    { pressedSubmit = False
    , name = ""
    , description = ""
    , visibility = Nothing
    }


validate : Form -> Maybe GroupFormValidated
validate form =
    case ( GroupName.fromString form.name, Description.fromString form.description, form.visibility ) of
        ( Ok groupName, Ok description, Just visibility ) ->
            { name = groupName
            , description = description
            , visibility = visibility
            }
                |> Just

        _ ->
            Nothing


type OutMsg
    = Submitted GroupFormValidated
    | NoChange


update : Msg -> Model -> ( Model, OutMsg )
update msg model =
    case model of
        Editting form ->
            updateForm Editting msg form

        Submitting _ ->
            ( model, NoChange )

        SubmitFailed error form ->
            updateForm (SubmitFailed error) msg form


updateForm : (Form -> Model) -> Msg -> Form -> ( Model, OutMsg )
updateForm wrapper msg form =
    case msg of
        FormChanged newForm ->
            ( wrapper newForm, NoChange )

        PressedSubmit ->
            case validate form of
                Just validated ->
                    ( Submitting validated, Submitted validated )

                Nothing ->
                    ( wrapper { form | pressedSubmit = True }, NoChange )

        PressedClear ->
            ( wrapper initForm, NoChange )


view : Model -> Element Msg
view model =
    case model of
        Editting form ->
            formView Nothing False form

        Submitting validated ->
            formView Nothing True (validatedToForm validated)

        SubmitFailed error form ->
            formView
                (case error of
                    GroupNameAlreadyInUse ->
                        Just "Sorry, that group name is already being used."
                )
                False
                form


type CreateGroupError
    = GroupNameAlreadyInUse


submitFailed : CreateGroupError -> Model -> Model
submitFailed error model =
    case model of
        Editting _ ->
            model

        Submitting validated ->
            SubmitFailed error (validatedToForm validated)

        SubmitFailed createGroupError form ->
            SubmitFailed createGroupError form


formView : Maybe String -> Bool -> Form -> Element Msg
formView maybeSubmitError isSubmitting form =
    Element.column
        [ Element.width Element.fill
        , Element.spacing 8
        , Element.padding 8
        ]
        [ Ui.title "Create a new group"
        , Ui.textInput (\a -> FormChanged { form | name = a })
            form.name
            "What's the name of your group?"
            (case ( form.pressedSubmit, GroupName.fromString form.name ) of
                ( True, Err error ) ->
                    case error of
                        GroupName.GroupNameTooShort ->
                            "Name must be at least "
                                ++ String.fromInt GroupName.minLength
                                ++ " characters long."
                                |> Just

                        GroupName.GroupNameTooLong ->
                            "Name is too long. Keep it under "
                                ++ String.fromInt (GroupName.maxLength + 1)
                                ++ " characters."
                                |> Just

                _ ->
                    Nothing
            )
        , Ui.multiline
            (\a -> FormChanged { form | description = a })
            form.description
            "Describe what your group is about (you can fill out this later)"
            (case ( form.pressedSubmit, Description.fromString form.description ) of
                ( True, Err error ) ->
                    case error of
                        Description.DescriptionTooLong ->
                            "Description is "
                                ++ String.fromInt (String.length form.description)
                                ++ " characters long. Keep it under "
                                ++ String.fromInt Description.maxLength
                                ++ "."
                                |> Just

                _ ->
                    Nothing
            )
        , Ui.radioGroup
            (\a -> FormChanged { form | visibility = Just a })
            (Nonempty PublicGroup [ PrivateGroup ])
            form.visibility
            (\visibility ->
                case visibility of
                    PrivateGroup ->
                        "I want this group to be private"

                    PublicGroup ->
                        "I want this group to be publicly visible"
            )
            (case ( form.pressedSubmit, form.visibility ) of
                ( True, Nothing ) ->
                    Just "Pick a visibility setting"

                _ ->
                    Nothing
            )
        , Element.column
            [ Element.spacing 8, Element.paddingXY 0 16 ]
            [ case maybeSubmitError of
                Just error ->
                    Ui.formError error

                Nothing ->
                    Element.none
            , Element.row
                [ Element.spacing 16, Element.width Element.fill ]
                [ Ui.submitButton isSubmitting { onPress = PressedSubmit, label = "Submit" }
                , Ui.button { onPress = PressedClear, label = "Clear" }
                ]
            ]
        ]
