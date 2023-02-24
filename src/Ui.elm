module Ui exposing
    ( attributeNone
    , button
    , cardAttributes
    , columnCard
    , contentWidth
    , css
    , dangerButton
    , dateTimeInput
    , datestamp
    , datetimeToString
    , defaultFont
    , defaultFontColor
    , defaultFontSize
    , emailAddressText
    , enterKeyCode
    , error
    , externalLink
    , formError
    , formLabelAbove
    , formLabelAboveEl
    , greedyOnClick
    , headerButton
    , headerLink
    , horizontalLine
    , inputBackground
    , inputBorder
    , inputBorderWidth
    , inputFocusClass
    , linkButton
    , loadingError
    , loadingView
    , mailToLink
    , multiline
    , numberInput
    , onEnter
    , overlayEl
    , pageContentAttributes
    , radioGroup
    , routeLink
    , routeLinkNewTab
    , section
    , smallSubmitButton
    , submitButton
    , textInput
    , timeToString
    , timestamp
    , title
    , titleFontSize
    )

import Colors
import Date exposing (Date)
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Region as Region
import EmailAddress exposing (EmailAddress)
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Json.Decode
import List.Nonempty exposing (Nonempty)
import Route exposing (Route)
import Svg
import Svg.Attributes
import Time
import Time.Extra as Time
import TimeExtra as Time
import UserConfig exposing (Texts, Theme)


css : Theme -> Html msg
css theme =
    Html.node "style"
        []
        [ """ 
          @import url('https://rsms.me/inter/inter.css');
          html { font-family: 'Inter', sans-serif; scrollbar-gutter: stable; background-color: """
            ++ Colors.toCssString theme.background
            ++ """; }
          @supports (font-variation-settings: normal) {
            html { font-family: 'Inter var', sans-serif; }
          }

          .linkFocus:focus {
              outline: solid #9bcbff !important;
          }

          .preserve-white-space {
              white-space: pre;
          }

          @keyframes fade-in {
            0% {opacity: 0;}
            50% {opacity: 0;}
            100% {opacity: 1;}
          }
        """
            |> Html.text
        ]


onEnter : msg -> Attribute msg
onEnter msg =
    Html.Events.preventDefaultOn "keydown"
        (Json.Decode.field "keyCode" Json.Decode.int
            |> Json.Decode.andThen
                (\code ->
                    if code == enterKeyCode then
                        Json.Decode.succeed ( msg, True )

                    else
                        Json.Decode.fail "Not the enter key"
                )
        )
        |> htmlAttribute


enterKeyCode : number
enterKeyCode =
    13


pageContentAttributes : List (Attribute msg)
pageContentAttributes =
    [ padding 8
    , centerX
    , width (maximum 800 fill)
    , spacing 20
    ]


inputFocusClass : Attribute msg
inputFocusClass =
    htmlAttribute <| Html.Attributes.class "linkFocus"


horizontalLine : Theme -> Element msg
horizontalLine theme =
    el
        [ width fill
        , height (px 1)
        , Background.color theme.darkGrey
        ]
        none


headerButton : Bool -> HtmlId -> { onPress : msg, label : String } -> Element msg
headerButton isMobile_ htmlId { onPress, label } =
    Input.button
        [ mouseOver [ Background.color <| rgba 1 1 1 0.5 ]
        , if isMobile_ then
            padding 6

          else
            padding 8
        , Font.center
        , inputFocusClass
        , Dom.idToAttribute htmlId |> htmlAttribute
        , if isMobile_ then
            Font.size 13

          else
            Font.size 16
        ]
        { onPress = Just onPress
        , label = text label
        }


headerLink : Theme -> Bool -> Bool -> { route : Route, label : String } -> Element msg
headerLink theme isMobile_ isSelected { route, label } =
    link
        [ mouseOver [ Background.color <| rgba 1 1 1 0.5 ]
        , below <|
            if isSelected then
                el
                    [ paddingXY 4 0, width fill ]
                    (el
                        [ Background.color theme.submit
                        , width fill
                        , height (px 2)
                        ]
                        none
                    )

            else
                none
        , if isMobile_ then
            padding 6

          else
            padding 8
        , Font.center
        , if isMobile_ then
            Font.size 13

          else
            Font.size 16
        , inputFocusClass
        ]
        { url = Route.encode route
        , label = text label
        }


emailAddressText : EmailAddress -> Element msg
emailAddressText emailAddress =
    el
        [ Font.bold ]
        (text (EmailAddress.toString emailAddress))


routeLink : Theme -> Route -> String -> Element msg
routeLink theme route label =
    link
        [ Font.color theme.link, inputFocusClass, Font.underline ]
        { url = Route.encode route, label = text label }


routeLinkNewTab : Theme -> Route -> String -> Element msg
routeLinkNewTab theme route label =
    newTabLink
        [ Font.color theme.link, inputFocusClass, Font.underline ]
        { url = "https://meetdown.app" ++ Route.encode route, label = text label }


externalLink : Theme -> String -> String -> Element msg
externalLink theme url label =
    newTabLink
        [ Font.color theme.link, inputFocusClass, Font.underline ]
        { url = url, label = text label }


mailToLink : Theme -> String -> Maybe String -> Element msg
mailToLink theme emailAddress maybeSubject =
    link
        [ Font.color theme.link, inputFocusClass ]
        { url =
            "mailto:"
                ++ emailAddress
                ++ (case maybeSubject of
                        Just subject ->
                            "?subject=" ++ subject

                        Nothing ->
                            ""
                   )
        , label = text emailAddress
        }


section : Theme -> String -> Element msg -> Element msg
section theme sectionTitle content =
    column
        [ spacing 8
        , Border.rounded 4
        , inputBackground theme False
        , alignTop
        ]
        [ paragraph [ Font.bold ] [ text sectionTitle ]
        , content
        ]


button : Theme -> HtmlId -> { onPress : msg, label : String } -> Element msg
button theme htmlId { onPress, label } =
    Input.button
        [ Border.width 2
        , Border.color theme.grey
        , padding 8
        , Border.rounded 4
        , Font.center
        , Font.color theme.mutedText
        , width (minimum 150 fill)
        , Dom.idToAttribute htmlId |> htmlAttribute
        ]
        { onPress = Just onPress
        , label = text label
        }


linkButton : Theme -> { route : Route, label : String } -> Element msg
linkButton theme { route, label } =
    link
        [ Border.width 2
        , Border.color theme.grey
        , padding 8
        , Border.rounded 4
        , Font.center
        , Font.color theme.mutedText
        , width (minimum 150 fill)
        ]
        { url = Route.encode route
        , label = text label
        }


submitButton : Theme -> HtmlId -> Bool -> { onPress : msg, label : String } -> Element msg
submitButton theme htmlId isSubmitting { onPress, label } =
    Input.button
        [ Background.color theme.submit
        , padding 10
        , Border.rounded 4
        , Font.center
        , Font.color theme.invertedText
        , Dom.idToAttribute htmlId |> htmlAttribute
        , width fill
        , Font.medium
        ]
        { onPress = Just onPress
        , label = labelWithHourglass isSubmitting label
        }


smallSubmitButton : HtmlId -> Bool -> { onPress : msg, label : String } -> Element msg
smallSubmitButton htmlId isSubmitting { onPress, label } =
    Input.button
        [ Background.color <| rgb 0.1 0.6 0.25
        , paddingXY 8 4
        , Border.rounded 4
        , Font.center
        , Font.color <| rgb 1 1 1
        , Dom.idToAttribute htmlId |> htmlAttribute
        ]
        { onPress = Just onPress
        , label = labelWithHourglass isSubmitting label
        }


dangerButton : Theme -> HtmlId -> Bool -> { onPress : msg, label : String } -> Element msg
dangerButton theme htmlId isSubmitting { onPress, label } =
    Input.button
        [ Background.color theme.error
        , padding 10
        , Border.rounded 4
        , Font.center
        , Font.color theme.invertedText
        , Dom.idToAttribute htmlId |> htmlAttribute
        ]
        { onPress = Just onPress
        , label = labelWithHourglass isSubmitting label
        }


labelWithHourglass : Bool -> String -> Element msg
labelWithHourglass isSubmitting label =
    el
        [ width fill
        , paddingXY 30 0
        , if isSubmitting then
            inFront (el [] (text "⌛"))

          else
            inFront none
        ]
        (text label)


titleFontSize : Attr decorative msg
titleFontSize =
    Font.size 28


defaultFont : Attribute msg
defaultFont =
    Font.family [ Font.typeface "Inter" ]


defaultFontColor : Theme -> Attr decorative msg
defaultFontColor theme =
    Font.color theme.defaultText


defaultFontSize : Attr decorative msg
defaultFontSize =
    Font.size 16


title : String -> Element msg
title text_ =
    paragraph [ titleFontSize, Region.heading 1 ] [ text text_ ]


error : Theme -> String -> Element msg
error theme errorMessage =
    paragraph
        [ paddingEach { left = 4, right = 4, top = 4, bottom = 0 }
        , Font.color theme.error
        , Font.size 14
        , Font.medium
        ]
        [ text errorMessage ]


formError : Theme -> String -> Element msg
formError theme errorMessage =
    paragraph
        [ Font.color theme.error ]
        [ text errorMessage ]


checkboxChecked : Element msg
checkboxChecked =
    Svg.svg
        [ Svg.Attributes.width "60.768"
        , Svg.Attributes.height "60.768"
        , Svg.Attributes.viewBox "0 0 190 190"
        , Svg.Attributes.width "20px"
        , Svg.Attributes.height "20px"
        ]
        [ Svg.path
            [ Svg.Attributes.fill "currentColor"
            , Svg.Attributes.stroke "#000"
            , Svg.Attributes.d "M34.22 112.47c3.31-3.31 12-11.78 16.37-15.78.91.78 18.79 18.07 19.03 18.31.38-.31 70.16-68.97 70.41-69.09.35.12 16.56 15.31 16.44 15.37-.17.25-86.73 86.78-86.8 86.9l-35.45-35.71zM25.91.06L69 .15h93C181.59.03 189.97 8.41 190 28v134c-.03 19.59-8.41 27.97-28 28H28c-19.59-.03-27.97-8.41-28-28V26C.17 12.01 7.61.09 25.91.06zM169 19H19v150h150V19z"
            ]
            []
        ]
        |> html
        |> el [ alignTop ]


checkboxEmpty : Element msg
checkboxEmpty =
    Svg.svg
        [ Svg.Attributes.width "60.768"
        , Svg.Attributes.height "60.768"
        , Svg.Attributes.viewBox "0 0 190 190"
        , Svg.Attributes.width "20px"
        , Svg.Attributes.height "20px"
        ]
        [ Svg.path
            [ Svg.Attributes.fill "currentColor"
            , Svg.Attributes.stroke "#000"
            , Svg.Attributes.d "M25.91.06L69 .15h93C181.59.03 189.97 8.41 190 28v134c-.03 19.59-8.41 27.97-28 28H28c-19.59-.03-27.97-8.41-28-28V26C.17 12.01 7.61.09 25.91.06zM169 19H19v150h150V19z"
            ]
            []
        ]
        |> html
        |> el [ alignTop ]


radioGroup : Theme -> (a -> HtmlId) -> (a -> msg) -> Nonempty a -> Maybe a -> (a -> String) -> Maybe String -> Element msg
radioGroup theme htmlId onSelect options selected optionToLabel maybeError =
    let
        optionsView =
            List.Nonempty.map
                (\value ->
                    Input.button
                        [ width fill
                        , paddingXY 0 6
                        , htmlId value |> Dom.idToAttribute |> htmlAttribute
                        ]
                        { onPress = Just (onSelect value)
                        , label =
                            row
                                []
                                [ if Just value == selected then
                                    checkboxChecked

                                  else
                                    checkboxEmpty
                                , optionToLabel value
                                    |> text
                                    |> List.singleton
                                    |> paragraph [ paddingXY 8 0 ]
                                ]
                        }
                )
                options
                |> List.Nonempty.toList
    in
    optionsView
        ++ [ Maybe.map (error theme) maybeError |> Maybe.withDefault none ]
        |> column []


inputBackground : Theme -> Bool -> Attr decorative msg
inputBackground theme hasError =
    Background.color <|
        if hasError then
            theme.errorBackground

        else
            rgba255 0 0 0 0


contentWidth : Attribute msg
contentWidth =
    width (maximum 800 fill)


inputBorder : Theme -> Bool -> Attr decorative msg
inputBorder theme hasError =
    Border.color <|
        if hasError then
            theme.error

        else
            theme.darkGrey


inputBorderWidth : Bool -> Attribute msg
inputBorderWidth hasError =
    Border.width <|
        if hasError then
            2

        else
            1


textInput : Theme -> HtmlId -> (String -> msg) -> String -> String -> Maybe String -> Element msg
textInput theme htmlId onChange text labelText maybeError =
    column
        [ width fill
        , Border.rounded 4
        ]
        [ Input.text
            [ width fill
            , Dom.idToAttribute htmlId |> htmlAttribute
            , inputBorder theme (maybeError /= Nothing)
            , Background.color theme.background
            ]
            { text = text
            , onChange = onChange
            , placeholder = Nothing
            , label = formLabelAbove theme labelText
            }
        , Maybe.map (error theme) maybeError |> Maybe.withDefault none
        ]


multiline : Theme -> HtmlId -> (String -> msg) -> String -> String -> Maybe String -> Element msg
multiline theme htmlId onChange text labelText maybeError =
    column
        [ width fill
        , Border.rounded 4
        ]
        [ Input.multiline
            [ width fill
            , height (px 200)
            , Dom.idToAttribute htmlId |> htmlAttribute
            , inputBorder theme (maybeError /= Nothing)
            , inputBorderWidth (maybeError /= Nothing)
            , Background.color theme.background
            ]
            { text = text
            , onChange = onChange
            , placeholder = Nothing
            , label = formLabelAbove theme labelText
            , spellcheck = True
            }
        , Maybe.map (error theme) maybeError |> Maybe.withDefault none
        ]


numberInput : Theme -> HtmlId -> (String -> msg) -> String -> String -> Maybe String -> Element msg
numberInput theme htmlId onChange value labelText maybeError =
    column
        [ spacing 4
        ]
        [ formLabelAboveEl theme labelText
        , Html.input
            ([ Html.Attributes.type_ "number"
             , Html.Events.onInput onChange
             , Dom.idToAttribute htmlId
             , Html.Attributes.value value
             , Html.Attributes.style "line-height" "38px"
             , Html.Attributes.style "text-align" "right"
             , Html.Attributes.style "padding-right" "4px"
             ]
                ++ htmlInputStyle theme
            )
            []
            |> html
            |> el []
        , maybeError |> Maybe.map (error theme) |> Maybe.withDefault none
        ]


dateTimeInput :
    Theme
    ->
        { dateInputId : HtmlId
        , timeInputId : HtmlId
        , dateChanged : String -> msg
        , timeChanged : String -> msg
        , labelText : String
        , minTime : Time.Posix
        , timezone : Time.Zone
        , dateText : String
        , timeText : String
        , isDisabled : Bool
        , maybeError : Maybe String
        }
    -> Element msg
dateTimeInput theme { dateInputId, timeInputId, dateChanged, timeChanged, labelText, minTime, timezone, dateText, timeText, isDisabled, maybeError } =
    column
        [ spacing 4 ]
        [ formLabelAboveEl theme labelText
        , wrappedRow [ spacing 8 ]
            [ dateInput theme dateInputId dateChanged (Date.fromPosix timezone minTime) dateText isDisabled
            , timeInput theme timeInputId timeChanged timeText isDisabled
            ]
        , maybeError |> Maybe.map (error theme) |> Maybe.withDefault none
        ]


timeInput : Theme -> HtmlId -> (String -> msg) -> String -> Bool -> Element msg
timeInput theme htmlId onChange time isDisabled =
    Html.input
        ([ Html.Attributes.type_ "time"
         , Html.Events.onInput onChange
         , Html.Attributes.value time
         , Html.Attributes.style "padding" "5px"
         , Dom.idToAttribute htmlId
         , Html.Attributes.disabled isDisabled
         ]
            ++ htmlInputStyle theme
        )
        []
        |> html
        |> el []


timeToString : Time.Zone -> Time.Posix -> String
timeToString timezone time =
    String.fromInt (Time.toHour timezone time)
        ++ ":"
        ++ String.padLeft 2 '0' (String.fromInt (Time.toMinute timezone time))


dateInput : Theme -> HtmlId -> (String -> msg) -> Date -> String -> Bool -> Element msg
dateInput theme htmlId onChange minDateTime date isDisabled =
    Html.input
        ([ Html.Attributes.type_ "date"
         , Html.Attributes.min (datestamp minDateTime)
         , Html.Events.onInput onChange
         , Html.Attributes.value date
         , Html.Attributes.style "padding" "5px"
         , Dom.idToAttribute htmlId
         , Html.Attributes.disabled isDisabled
         ]
            ++ htmlInputStyle theme
        )
        []
        |> html
        |> el []


datetimeToString : Time.Zone -> Time.Posix -> String
datetimeToString timezone time =
    let
        offset =
            toFloat (Time.toOffset timezone time) / 60
    in
    (time |> Date.fromPosix timezone |> Date.format "MMMM ddd")
        ++ ", "
        ++ timeToString timezone time
        ++ (if offset >= 0 then
                Time.removeTrailing0s 1 offset |> (++) " GMT+"

            else
                Time.removeTrailing0s 1 offset |> (++) " GMT"
           )


datestamp : Date -> String
datestamp date =
    String.fromInt (Date.year date)
        ++ "-"
        ++ String.padLeft 2 '0' (String.fromInt (Date.monthNumber date))
        ++ "-"
        ++ String.padLeft 2 '0' (String.fromInt (Date.day date))


{-| Timestamp used by time input field.
-}
timestamp : Int -> Int -> String
timestamp hour minute =
    String.padLeft 2 '0' (String.fromInt hour) ++ ":" ++ String.padLeft 2 '0' (String.fromInt minute)


formLabelAbove : Theme -> String -> Input.Label msg
formLabelAbove theme labelText =
    Input.labelAbove
        [ paddingEach { top = 0, right = 0, bottom = 5, left = 0 }
        , Font.medium
        , Font.size 13
        , Font.color theme.textInputHeading
        ]
        (paragraph [] [ text labelText ])


formLabelAboveEl : Theme -> String -> Element msg
formLabelAboveEl theme labelText =
    el
        [ paddingEach { top = 0, right = 0, bottom = 5, left = 0 }
        , Font.medium
        , Font.size 13
        , Font.color theme.textInputHeading
        ]
        (paragraph [] [ text labelText ])


columnCard : Theme -> List (Element msg) -> Element msg
columnCard theme children =
    column
        (width fill
            :: spacing 30
            :: cardAttributes theme
        )
        children


cardAttributes : Theme -> List (Attribute msg)
cardAttributes theme =
    [ Border.rounded 4
    , padding 15
    , Border.width 1
    , Border.color theme.grey
    , Border.shadow { offset = ( 0, 3 ), size = -1, blur = 3, color = theme.grey }
    ]


loadingView : Texts -> Element msg
loadingView texts =
    el
        [ Font.size 20
        , centerX
        , centerY
        , htmlAttribute (Html.Attributes.style "animation-name" "fade-in")
        , htmlAttribute (Html.Attributes.style "animation-duration" "1s")
        ]
    <|
        text <|
            texts.loading


loadingError : Theme -> String -> Element msg
loadingError theme text_ =
    el
        [ Font.size 20
        , centerX
        , centerY
        , Font.color theme.error
        ]
    <|
        text text_


htmlInputStyle : Theme -> List (Html.Attribute msg)
htmlInputStyle theme =
    [ Html.Attributes.style "border-color" (Colors.toCssString theme.darkGrey)
    , Html.Attributes.style "border-width" "1px"
    , Html.Attributes.style "border-style" "solid"
    , Html.Attributes.style "border-radius" "4px"
    , Html.Attributes.style "background-color" (Colors.toCssString theme.background)
    , Html.Attributes.style "color" (Colors.toCssString theme.defaultText)
    ]


attributeNone : Attribute msg
attributeNone =
    htmlAttribute <| Html.Attributes.style "none" "none"


overlayEl : Element msg -> Element msg
overlayEl =
    el
        [ width fill
        , height fill
        , htmlAttribute <| Html.Attributes.style "overflow-y" "auto"
        , htmlAttribute <| Html.Attributes.style "position" "fixed"
        , htmlAttribute <| Html.Attributes.style "top" "0"
        , htmlAttribute <| Html.Attributes.style "right" "0"
        , htmlAttribute <| Html.Attributes.style "bottom" "0"
        , htmlAttribute <| Html.Attributes.style "left" "0"
        ]


greedyOnClick : msg -> Attribute msg
greedyOnClick msg =
    htmlAttribute <|
        Html.Events.custom "click" <|
            Json.Decode.succeed { message = msg, preventDefault = True, stopPropagation = True }
