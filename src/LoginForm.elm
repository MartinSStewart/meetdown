module LoginForm exposing (cancelButtonId, emailAddressInputId, submitButtonId, submitForm, typedEmail, view)

import AssocList as Dict exposing (Dict)
import Colors
import Element exposing (Element)
import Element.Font
import Element.Input
import EmailAddress exposing (EmailAddress)
import FrontendEffect exposing (FrontendEffect)
import Group exposing (EventId, Group)
import GroupName
import Html.Attributes
import Id exposing (ButtonId(..), GroupId, HtmlId, Id, TextInputId)
import Route exposing (Route)
import Types exposing (Cache(..), FrontendMsg(..), LoginForm, ToBackend(..))
import Ui
import Untrusted


emailInput : HtmlId TextInputId -> msg -> (String -> msg) -> String -> String -> Maybe String -> Element msg
emailInput id onSubmit onChange text labelText maybeError =
    Element.column
        [ Element.width Element.fill ]
        [ Element.Input.email
            [ Element.width Element.fill
            , Ui.onEnter onSubmit
            , Ui.inputBorder (maybeError /= Nothing)
            , Id.htmlIdToString id |> Html.Attributes.id |> Element.htmlAttribute
            ]
            { text = text
            , onChange = onChange
            , placeholder = Nothing
            , label =
                Element.Input.labelAbove
                    []
                    (Element.paragraph [] [ Element.text labelText ])
            }
        , Maybe.map Ui.error maybeError |> Maybe.withDefault Element.none
        ]


view : Maybe ( Id GroupId, EventId ) -> Dict (Id GroupId) (Cache Group) -> LoginForm -> Element FrontendMsg
view joiningEvent cachedGroups { email, pressedSubmitEmail, emailSent } =
    Element.column
        [ Element.centerX
        , Element.centerY
        , Element.padding 8
        , Element.spacing 16
        , Element.width <| Element.maximum 400 Element.shrink
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
        [ case joiningEvent of
            Just ( groupId, _ ) ->
                case Dict.get groupId cachedGroups of
                    Just (ItemCached group) ->
                        Element.paragraph []
                            [ Element.text "Sign in and we'll get you signed up for the "
                            , GroupName.toString (Group.name group)
                                |> Element.text
                                |> Element.el [ Element.Font.bold ]
                            , Element.text " event"
                            ]

                    _ ->
                        Element.paragraph
                            []
                            [ Element.text "Sign in and we'll get you signed up for that event" ]

            Nothing ->
                Element.none
        , emailInput
            emailAddressInputId
            PressedSubmitLogin
            TypedEmail
            email
            "Enter your email address"
            (case ( pressedSubmitEmail, validateEmail email ) of
                ( True, Err error ) ->
                    Just error

                _ ->
                    Nothing
            )
        , Element.paragraph []
            [ Element.text "By continuing you agree to the "
            , Ui.routeLink Route.TermsOfServiceRoute "Terms"
            , Element.text "."
            ]
        , Element.wrappedRow
            [ Element.spacingXY 16 8, Element.width Element.fill ]
            [ Ui.submitButton submitButtonId False { onPress = PressedSubmitLogin, label = "Sign up/Login" }
            , Ui.button cancelButtonId { onPress = PressedCancelLogin, label = "Cancel" }
            ]
        ]


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


submitForm :
    Route
    -> Maybe ( Id GroupId, EventId )
    -> LoginForm
    -> ( LoginForm, FrontendEffect ToBackend FrontendMsg )
submitForm route maybeJoinEvent loginForm =
    case validateEmail loginForm.email of
        Ok email ->
            ( { loginForm | emailSent = Just email }
            , GetLoginTokenRequest route (Untrusted.untrust email) maybeJoinEvent |> FrontendEffect.SendToBackend
            )

        Err _ ->
            ( { loginForm | pressedSubmitEmail = True }, FrontendEffect.None )


typedEmail : String -> LoginForm -> LoginForm
typedEmail emailText loginForm =
    { loginForm | email = emailText }


emailAddressInputId : HtmlId TextInputId
emailAddressInputId =
    Id.textInputId "loginTextInput"


submitButtonId : HtmlId ButtonId
submitButtonId =
    Id.buttonId "loginSubmit"


cancelButtonId : HtmlId ButtonId
cancelButtonId =
    Id.buttonId "loginCancel"
