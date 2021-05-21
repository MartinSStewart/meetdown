module ProfileForm exposing (CurrentValues, Effects, Form, Model, Msg, init, update, view)

import Description exposing (Description, Error(..))
import Duration exposing (Duration)
import Element exposing (Element)
import Element.Border
import Element.Font
import Element.Input
import EmailAddress exposing (EmailAddress)
import Html
import Html.Attributes
import MockFile exposing (File)
import Name exposing (Error(..), Name)
import ProfileImage exposing (ProfileImage)
import Ui
import Untrusted exposing (Untrusted)


type Msg
    = FormChanged Form
    | SleepFinished Int
    | PressedProfileImage
    | SelectedImage File
    | PressedDeleteAccount


type Editable a
    = Unchanged
    | Editting a


type alias Model =
    { form : Form
    , changeCounter : Int
    , profileImage : Editable (Maybe File)
    , pressedDeleteAccount : Bool
    }


type alias Form =
    { name : Editable String
    , description : Editable String
    , emailAddress : Editable String
    }


type alias CurrentValues a =
    { a
        | name : Name
        , description : Description
        , emailAddress : EmailAddress
        , profileImage : ProfileImage
    }


init : Model
init =
    { form =
        { name = Unchanged
        , description = Unchanged
        , emailAddress = Unchanged
        }
    , changeCounter = 0
    , profileImage = Unchanged
    , pressedDeleteAccount = False
    }


type alias Effects cmd =
    { wait : Duration -> Msg -> cmd
    , none : cmd
    , changeName : Untrusted Name -> cmd
    , changeDescription : Untrusted Description -> cmd
    , changeEmailAddress : Untrusted EmailAddress -> cmd
    , selectFile : List String -> (File -> Msg) -> cmd
    , sendDeleteAccountEmail : cmd
    , batch : List cmd -> cmd
    }


update : Effects cmd -> Msg -> Model -> ( Model, cmd )
update effects msg model =
    case msg of
        FormChanged newForm ->
            ( { model | form = newForm, changeCounter = model.changeCounter + 1 }
            , effects.wait (Duration.seconds 2) (SleepFinished (model.changeCounter + 1))
            )

        SleepFinished changeCount ->
            let
                validate : (a -> Maybe b) -> Editable a -> Maybe b
                validate validator editable =
                    case editable of
                        Editting value ->
                            validator value

                        Unchanged ->
                            Nothing
            in
            ( model
            , if changeCount == model.changeCounter then
                [ validate
                    (Name.fromString >> Result.toMaybe >> Maybe.map (Untrusted.untrust >> effects.changeName))
                    model.form.name
                , validate
                    (Description.fromString >> Result.toMaybe >> Maybe.map (Untrusted.untrust >> effects.changeDescription))
                    model.form.description
                , validate
                    (EmailAddress.fromString >> Maybe.map (Untrusted.untrust >> effects.changeEmailAddress))
                    model.form.emailAddress
                ]
                    |> List.filterMap identity
                    |> effects.batch

              else
                effects.none
            )

        PressedProfileImage ->
            ( model
            , effects.selectFile [ "image/png", "image/jpg", "image/jpeg" ] SelectedImage
            )

        SelectedImage file ->
            ( { model | profileImage = Editting (Just file) }, effects.none )

        PressedDeleteAccount ->
            ( { model | pressedDeleteAccount = True }, effects.sendDeleteAccountEmail )


profileImageSize =
    128


view : CurrentValues a -> Model -> Element Msg
view currentValues { form, profileImage } =
    Element.column
        [ Element.spacing 8, Element.padding 8, Element.width Element.fill ]
        [ Element.wrappedRow [ Element.width Element.fill ]
            [ Element.el [ Element.alignTop ] (Ui.title "Profile")
            , Element.Input.button
                [ Element.alignRight
                , Element.Border.rounded 9999
                , Element.clip
                ]
                { onPress = Just PressedProfileImage
                , label =
                    case profileImage of
                        Unchanged ->
                            Element.image
                                [ Element.width (Element.px profileImageSize)
                                , Element.height (Element.px profileImageSize)
                                , Element.alignRight
                                , Ui.inputBackground False
                                ]
                                { src = "./default-profile.png", description = "Your profile image" }

                        Editting _ ->
                            Element.html
                                (Html.canvas
                                    [ Html.Attributes.width profileImageSize
                                    , Html.Attributes.height profileImageSize
                                    ]
                                    []
                                )
                }
            ]
        , editableTextInput
            (\a -> FormChanged { form | name = a })
            Name.toString
            (\a ->
                case Name.fromString a of
                    Ok name ->
                        Ok name

                    Err Name.NameTooShort ->
                        Err "Your name can't be empty"

                    Err Name.NameTooLong ->
                        "Keep it below " ++ String.fromInt (Name.maxLength + 1) ++ " characters" |> Err
            )
            currentValues.name
            form.name
            "Your name"
        , editableMultiline
            (\a -> FormChanged { form | description = a })
            Description.toString
            (\a ->
                case Description.fromString a of
                    Ok name ->
                        Ok name

                    Err DescriptionTooLong ->
                        "Less than "
                            ++ String.fromInt Description.maxLength
                            ++ " characters please"
                            |> Err
            )
            currentValues.description
            form.description
            "What do you want people to know about you?"
        , editableEmailInput
            (\_ -> FormChanged form)
            --(\a -> FormChanged { form | emailAddress = a })
            EmailAddress.toString
            (EmailAddress.fromString >> Result.fromMaybe "Invalid email")
            currentValues.emailAddress
            form.emailAddress
            "Your email address"
        , Ui.filler (Element.px 8)
        , Ui.dangerButton { onPress = PressedDeleteAccount, label = "Delete account" }
        ]


editableTextInput :
    (Editable String -> msg)
    -> (a -> String)
    -> (String -> Result String a)
    -> a
    -> Editable String
    -> String
    -> Element msg
editableTextInput onChange toString validate currentValue text labelText =
    let
        result =
            case text of
                Unchanged ->
                    Ok currentValue

                Editting edit ->
                    validate edit

        maybeError =
            case result of
                Ok _ ->
                    Nothing

                Err error ->
                    Just error
    in
    Element.column
        [ Element.width Element.fill
        , Ui.inputBackground (maybeError /= Nothing)
        , Element.padding 8
        , Element.Border.rounded 4
        ]
        [ Element.Input.text
            [ Element.width Element.fill ]
            { text =
                case text of
                    Unchanged ->
                        toString currentValue

                    Editting value ->
                        value
            , onChange = Editting >> onChange
            , placeholder = Nothing
            , label =
                Element.Input.labelAbove
                    [ Element.paddingXY 4 0 ]
                    (Element.paragraph [] [ Element.text labelText ])
            }
        , case maybeError of
            Just error ->
                Ui.error error

            Nothing ->
                if result == Ok currentValue then
                    Element.none

                else
                    Element.el
                        [ Element.paddingEach { left = 4, right = 4, top = 4, bottom = 0 }
                        , Element.Font.size 16
                        ]
                        (Element.text "Saving...")
        ]


editableEmailInput :
    (Editable String -> msg)
    -> (a -> String)
    -> (String -> Result String a)
    -> a
    -> Editable String
    -> String
    -> Element msg
editableEmailInput onChange toString validate currentValue text labelText =
    let
        result =
            case text of
                Unchanged ->
                    Ok currentValue

                Editting edit ->
                    validate edit

        maybeError =
            case result of
                Ok _ ->
                    Nothing

                Err error ->
                    Just error
    in
    Element.column
        [ Element.width Element.fill
        , Ui.inputBackground (maybeError /= Nothing)
        , Element.padding 8
        , Element.Border.rounded 4
        ]
        [ Element.Input.email
            [ Element.width Element.fill ]
            { text =
                case text of
                    Unchanged ->
                        toString currentValue

                    Editting value ->
                        value
            , onChange = Editting >> onChange
            , placeholder = Nothing
            , label =
                Element.Input.labelAbove
                    [ Element.paddingXY 4 0 ]
                    (Element.paragraph [] [ Element.text labelText ])
            }
        , case maybeError of
            Just error ->
                Ui.error error

            Nothing ->
                if result == Ok currentValue then
                    Element.none

                else
                    Element.el
                        [ Element.paddingEach { left = 4, right = 4, top = 4, bottom = 0 }
                        , Element.Font.size 16
                        ]
                        (Element.text "Saving...")
        ]


editableMultiline : (Editable String -> msg) -> (a -> String) -> (String -> Result String a) -> a -> Editable String -> String -> Element msg
editableMultiline onChange toString validate currentValue text labelText =
    let
        result =
            case text of
                Unchanged ->
                    Ok currentValue

                Editting edit ->
                    validate edit

        maybeError =
            case result of
                Ok _ ->
                    Nothing

                Err error ->
                    Just error
    in
    Element.column
        [ Element.width Element.fill
        , Ui.inputBackground (maybeError /= Nothing)
        , Element.padding 8
        , Element.Border.rounded 4
        ]
        [ Element.Input.multiline
            [ Element.width Element.fill, Element.height (Element.px 200) ]
            { text =
                case text of
                    Unchanged ->
                        toString currentValue

                    Editting value ->
                        value
            , onChange = Editting >> onChange
            , placeholder = Nothing
            , label =
                Element.Input.labelAbove
                    [ Element.paddingXY 4 0 ]
                    (Element.paragraph [] [ Element.text labelText ])
            , spellcheck = True
            }
        , case maybeError of
            Just error ->
                Ui.error error

            Nothing ->
                if result == Ok currentValue then
                    Element.none

                else
                    Element.el
                        [ Element.paddingEach { left = 4, right = 4, top = 4, bottom = 0 }
                        , Element.Font.size 16
                        ]
                        (Element.text "Saving...")
        ]
