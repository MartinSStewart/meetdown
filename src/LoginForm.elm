module LoginForm exposing (submitForm, typedEmail, view)

import Element exposing (Element)
import Element.Input
import EmailAddress exposing (EmailAddress)
import FrontendEffect
import Route exposing (Route)
import Types exposing (FrontendMsg(..), LoginForm, ToBackendRequest(..))
import Ui
import Untrusted


view : LoginForm -> Element FrontendMsg
view { email, pressedSubmitEmail } =
    Element.el
        [ Element.width Element.fill, Element.height Element.fill ]
        (Element.column
            [ Element.centerX, Element.centerY, Element.spacing 16 ]
            [ Element.Input.text
                []
                { onChange = TypedEmail
                , text = email
                , placeholder = Nothing
                , label = Element.Input.labelAbove [] (Element.text "Enter your email address")
                }
            , case ( pressedSubmitEmail, validateEmail email ) of
                ( True, Err error ) ->
                    Element.text error

                _ ->
                    Element.none
            , Ui.button { onPress = PressedSubmitEmail, label = "Sign up/Login" }
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
            ( { loginForm | emailSent = True }
            , Untrusted.untrust email |> GetLoginTokenRequest route |> FrontendEffect.sendToBackend
            )

        Err _ ->
            ( { loginForm | pressedSubmitEmail = True }, FrontendEffect.none )


typedEmail : String -> LoginForm -> LoginForm
typedEmail emailText loginForm =
    { loginForm | email = emailText }
