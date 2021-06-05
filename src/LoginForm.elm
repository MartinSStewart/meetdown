module LoginForm exposing (emailAddressInputId, submitButtonId, submitForm, typedEmail, view)

import Element exposing (Element)
import Element.Border
import Element.Input
import EmailAddress exposing (EmailAddress)
import Id exposing (HtmlId(..))
import Route exposing (Route)
import Types exposing (FrontendMsg(..), LoginForm, ToBackend(..))
import Ui
import Untrusted


emailInput : HtmlId -> msg -> (String -> msg) -> String -> String -> Maybe String -> Element msg
emailInput id onSubmit onChange text labelText maybeError =
    Element.column
        [ Element.width Element.fill
        , Ui.inputBackground (maybeError /= Nothing)
        , Element.paddingEach { left = 8, right = 8, top = 8, bottom = 8 }
        , Element.Border.rounded 4
        ]
        [ Element.Input.email
            [ Element.width Element.fill, Ui.onEnter onSubmit, Ui.id id ]
            { text = text
            , onChange = onChange
            , placeholder = Nothing
            , label =
                Element.Input.labelAbove
                    [ Element.paddingXY 4 0 ]
                    (Element.paragraph [] [ Element.text labelText ])
            }
        , Maybe.map Ui.error maybeError |> Maybe.withDefault Element.none
        ]


view : LoginForm -> Element FrontendMsg
view { email, pressedSubmitEmail, emailSent } =
    Element.el
        [ Element.width Element.fill, Element.height Element.fill ]
        (Element.column
            [ Element.centerX
            , Element.centerY
            , Element.spacing 16
            , Element.width <| Element.minimum 400 Element.shrink
            , Element.below
                (case emailSent of
                    Just emailAddress ->
                        Element.column
                            [ Element.spacing 4, Element.padding 8 ]
                            [ Element.paragraph
                                []
                                [ Element.text "A login email has been sent to "
                                , Ui.emailAddressText emailAddress
                                , Element.text "."
                                ]
                            , Element.paragraph [] [ Element.text "Check your spam folder if you don't see it." ]
                            ]

                    Nothing ->
                        Element.none
                )
            ]
            [ emailInput
                emailAddressInputId
                PressedSubmitEmail
                TypedEmail
                email
                "Enter your email address"
                (case ( pressedSubmitEmail, validateEmail email ) of
                    ( True, Err error ) ->
                        Just error

                    _ ->
                        Nothing
                )
            , Ui.submitButton submitButtonId False { onPress = PressedSubmitEmail, label = "Sign up/Login" }
            ]
        )


validateEmail : String -> Result String EmailAddress
validateEmail text =
    case EmailAddress.fromString text of
        Just email ->
            Ok email

        Nothing ->
            if String.isEmpty text then
                Err "Enter your email first"

            else
                Err "Invalid email address"


submitForm : { a | none : cmd, sendToBackend : ToBackend -> cmd } -> Route -> LoginForm -> ( LoginForm, cmd )
submitForm cmds route loginForm =
    case validateEmail loginForm.email of
        Ok email ->
            ( { loginForm | emailSent = Just email }
            , Untrusted.untrust email |> GetLoginTokenRequest route |> cmds.sendToBackend
            )

        Err _ ->
            ( { loginForm | pressedSubmitEmail = True }, cmds.none )


typedEmail : String -> LoginForm -> LoginForm
typedEmail emailText loginForm =
    { loginForm | email = emailText }


emailAddressInputId =
    HtmlId "loginTextInput"


submitButtonId : HtmlId
submitButtonId =
    HtmlId "loginSubmit"
