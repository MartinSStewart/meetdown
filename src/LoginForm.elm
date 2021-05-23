module LoginForm exposing (submitForm, typedEmail, view)

import Element exposing (Element)
import EmailAddress exposing (EmailAddress)
import FrontendEffect
import Route exposing (Route)
import Types exposing (FrontendMsg(..), LoginForm, ToBackendRequest(..))
import Ui
import Untrusted


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
            [ Ui.emailInput TypedEmail
                email
                "Enter your email address"
                (case ( pressedSubmitEmail, validateEmail email ) of
                    ( True, Err error ) ->
                        Just error

                    _ ->
                        Nothing
                )
            , Ui.submitButton False { onPress = PressedSubmitEmail, label = "Sign up/Login" }
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


submitForm : Route -> LoginForm -> ( LoginForm, FrontendEffect.FrontendEffect )
submitForm route loginForm =
    case validateEmail loginForm.email of
        Ok email ->
            ( { loginForm | emailSent = Just email }
            , Untrusted.untrust email |> GetLoginTokenRequest route |> FrontendEffect.sendToBackend
            )

        Err _ ->
            ( { loginForm | pressedSubmitEmail = True }, FrontendEffect.none )


typedEmail : String -> LoginForm -> LoginForm
typedEmail emailText loginForm =
    { loginForm | email = emailText }
