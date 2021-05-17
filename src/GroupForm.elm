module GroupForm exposing (CreateGroupError(..), GroupFormValidated, GroupVisibility(..), Model, Msg, OutMsg(..), init, submitFailed, update, view)

import Element exposing (Element)
import Element.Input
import GroupDescription exposing (GroupDescription)
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
    , description : GroupDescription
    , visibility : GroupVisibility
    }


validatedToForm : GroupFormValidated -> Form
validatedToForm validated =
    { pressedSubmit = False
    , name = GroupName.toString validated.name
    , description = GroupDescription.toString validated.description
    , visibility = Just validated.visibility
    }


type Msg
    = FormChanged Form
    | PressedSubmit
    | PressedCancel


type alias Form =
    { pressedSubmit : Bool
    , name : String
    , description : String
    , visibility : Maybe GroupVisibility
    }


init : Model
init =
    Editting
        { pressedSubmit = False
        , name = ""
        , description = ""
        , visibility = Nothing
        }


validate : Form -> Maybe GroupFormValidated
validate form =
    case ( GroupName.fromString form.name, GroupDescription.fromString form.description, form.visibility ) of
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
    | Cancelled
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

        PressedCancel ->
            ( wrapper form, Cancelled )


view : Model -> Element Msg
view model =
    case model of
        Editting form ->
            formView form

        Submitting validated ->
            Element.column
                [ Element.width Element.fill ]
                [ formView (validatedToForm validated)
                , Element.text "Submitting..."
                ]

        SubmitFailed error form ->
            Element.column
                [ Element.width Element.fill ]
                [ formView form
                , Element.text
                    (case error of
                        GroupNameAlreadyInUse ->
                            "Sorry, that group name is already being used."
                    )
                ]


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


formView : Form -> Element Msg
formView form =
    Element.column
        [ Element.width Element.fill, Element.spacing 16 ]
        [ Ui.header "Create a new group"
        , case ( form.pressedSubmit, GroupName.fromString form.name ) of
            ( True, Err error ) ->
                case error of
                    GroupName.GroupNameTooShort ->
                        "Name must be at least "
                            ++ String.fromInt GroupName.minLength
                            ++ " characters long."
                            |> Ui.error

                    GroupName.GroupNameTooLong ->
                        "Name is too long. Keep it under "
                            ++ String.fromInt (GroupName.maxLength + 1)
                            ++ " characters."
                            |> Ui.error

            _ ->
                Element.none
        , Element.Input.text
            [ Element.width Element.fill ]
            { text = form.name
            , onChange = \a -> FormChanged { form | name = a }
            , placeholder = Nothing
            , label =
                Element.Input.labelAbove
                    []
                    (Element.paragraph [] [ Element.text "What's the name of your group?" ])
            }
        , case ( form.pressedSubmit, GroupDescription.fromString form.description ) of
            ( True, Err error ) ->
                case error of
                    GroupDescription.GroupDescriptionTooLong ->
                        "Description is "
                            ++ String.fromInt (String.length form.description)
                            ++ " characters long. Keep it under "
                            ++ String.fromInt GroupDescription.maxLength
                            ++ "."
                            |> Ui.error

            _ ->
                Element.none
        , Element.Input.multiline
            [ Element.width Element.fill, Element.height (Element.px 200) ]
            { text = form.description
            , onChange = \a -> FormChanged { form | description = a }
            , placeholder = Nothing
            , label =
                Element.Input.labelAbove
                    []
                    (Element.paragraph [] [ Element.text "Describe what your group is about! (you can fill out this later)" ])
            , spellcheck = True
            }
        , case ( form.pressedSubmit, form.visibility ) of
            ( True, Nothing ) ->
                Ui.error "Pick a visibility setting"

            _ ->
                Element.none
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
        , Element.row
            [ Element.spacing 16, Element.width Element.fill ]
            [ Ui.button Ui.buttonAttributes { onPress = PressedSubmit, label = Element.text "Submit" }
            , Ui.button Ui.buttonAttributes { onPress = PressedCancel, label = Element.text "Cancel" }
            ]
        ]
