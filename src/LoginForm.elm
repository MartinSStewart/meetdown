module LoginForm exposing (emailAddressInputId, submitButtonId, submitForm, typedEmail, view)

import AssocList as Dict exposing (Dict)
import Cache exposing (Cache(..))
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Lamdera as Lamdera
import Element exposing (Element)
import Element.Background
import Element.Input
import EmailAddress exposing (EmailAddress)
import Group exposing (EventId, Group)
import GroupName
import HtmlId
import Id exposing (GroupId, Id)
import Route exposing (Route)
import Types exposing (FrontendMsg(..), LoginForm, ToBackend(..))
import Ui
import Untrusted
import UserConfig exposing (Texts, UserConfig)


emailInput : UserConfig -> HtmlId -> msg -> (String -> msg) -> String -> String -> Maybe String -> Element msg
emailInput userConfig id onSubmit onChange text labelText maybeError =
    Element.column
        [ Element.width Element.fill ]
        [ Element.Input.email
            [ Element.width Element.fill
            , Ui.onEnter onSubmit
            , Ui.inputBorder userConfig.theme (maybeError /= Nothing)
            , Dom.idToAttribute id |> Element.htmlAttribute
            , Element.Background.color userConfig.theme.background
            ]
            { text = text
            , onChange = onChange
            , placeholder = Nothing
            , label =
                Element.Input.labelAbove
                    []
                    (Element.paragraph [] [ Element.text labelText ])
            }
        , Maybe.map (Ui.error userConfig.theme) maybeError |> Maybe.withDefault Element.none
        ]


view : UserConfig -> Maybe ( Id GroupId, EventId ) -> Dict (Id GroupId) (Cache Group) -> LoginForm -> Element FrontendMsg
view ({ texts } as userConfig) joiningEvent cachedGroups { email, pressedSubmitEmail, emailSent } =
    Element.column
        [ Element.centerX
        , Element.centerY
        , Element.padding 8
        , Element.spacing 16
        , Element.width (Element.maximum 400 Element.shrink)
        , Element.below
            (case emailSent of
                Just emailAddress ->
                    Element.column
                        [ Element.spacing 4, Element.padding 8 ]
                        [ Element.paragraph
                            []
                            [ Element.text texts.aLoginEmailHasBeenSentTo
                            , Ui.emailAddressText emailAddress
                            , Element.text "."
                            ]
                        , Element.paragraph [] [ Element.text texts.checkYourSpamFolderIfYouDonTSeeIt ]
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
                            [ Group.name group
                                |> GroupName.toString
                                |> texts.signInAndWeLlGetYouSignedUpForThe
                                |> Element.text
                            ]

                    _ ->
                        Element.paragraph
                            []
                            [ Element.text texts.signInAndWeLlGetYouSignedUpForThatEvent ]

            Nothing ->
                Element.none
        , emailInput
            userConfig
            emailAddressInputId
            PressedSubmitLogin
            TypedEmail
            email
            texts.enterYourEmailAddress
            (case ( pressedSubmitEmail, validateEmail texts email ) of
                ( True, Err error ) ->
                    Just error

                _ ->
                    Nothing
            )
        , Element.paragraph []
            [ Element.text texts.byContinuingYouAgreeToThe
            , Ui.routeLink userConfig.theme Route.TermsOfServiceRoute texts.terms
            , Element.text "."
            ]
        , Element.wrappedRow
            [ Element.spacingXY 16 8, Element.width Element.fill ]
            [ Ui.submitButton userConfig.theme submitButtonId False { onPress = PressedSubmitLogin, label = texts.login }
            , Ui.button userConfig.theme cancelButtonId { onPress = PressedCancelLogin, label = texts.cancel }
            ]
        ]


validateEmail : Texts -> String -> Result String EmailAddress
validateEmail texts text =
    EmailAddress.fromString text
        |> Result.fromMaybe
            (if String.isEmpty text then
                texts.enterYourEmailFirst

             else
                texts.invalidEmailAddress
            )


submitForm :
    Route
    -> Maybe ( Id GroupId, EventId )
    -> LoginForm
    -> ( LoginForm, Command FrontendOnly ToBackend FrontendMsg )
submitForm route maybeJoinEvent loginForm =
    case EmailAddress.fromString loginForm.email of
        Just email ->
            ( { loginForm | emailSent = Just email }
            , GetLoginTokenRequest route (Untrusted.untrust email) maybeJoinEvent |> Lamdera.sendToBackend
            )

        Nothing ->
            ( { loginForm | pressedSubmitEmail = True }, Command.none )


typedEmail : String -> LoginForm -> LoginForm
typedEmail emailText loginForm =
    { loginForm | email = emailText }


emailAddressInputId : HtmlId
emailAddressInputId =
    HtmlId.textInputId "loginTextInput"


submitButtonId : HtmlId
submitButtonId =
    HtmlId.buttonId "loginSubmit"


cancelButtonId : HtmlId
cancelButtonId =
    HtmlId.buttonId "loginCancel"
