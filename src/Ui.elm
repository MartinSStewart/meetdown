module Ui exposing
    ( button
    , cardAttributes
    , columnCard
    , contentWidth
    , css
    , dangerButton
    , dateTimeInput
    , datestamp
    , defaultFont
    , defaultFontColor
    , defaultFontSize
    , emailAddressText
    , enterKeyCode
    , error
    , filler
    , formError
    , formLabelAbove
    , headerButton
    , headerLink
    , hr
    , inputBackground
    , inputBorder
    , inputBorderWidth
    , inputFocusClass
    , linkColor
    , multiline
    , numberInput
    , onEnter
    , radioGroup
    , routeLink
    , section
    , submitButton
    , textInput
    , timeToString
    , title
    , titleFontSize
    )

import Colors exposing (..)
import Date exposing (Date)
import Element exposing (Element)
import Element.Background
import Element.Border
import Element.Font
import Element.Input
import Element.Region
import EmailAddress exposing (EmailAddress)
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Id exposing (ButtonId(..), DateInputId(..), HtmlId, NumberInputId(..), RadioButtonId(..), TextInputId(..), TimeInputId(..))
import Json.Decode
import List.Nonempty exposing (Nonempty)
import Route exposing (Route)
import Time


css : Html msg
css =
    Html.node "style"
        []
        [ Html.text """
          @import url('https://rsms.me/inter/inter.css');
          html { font-family: 'Inter', sans-serif; }
          @supports (font-variation-settings: normal) {
            html { font-family: 'Inter var', sans-serif; }
          }

          .linkFocus:focus {
              outline: solid #9bcbff !important;
          }
        """
        ]


onEnter : msg -> Element.Attribute msg
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
        |> Element.htmlAttribute


enterKeyCode =
    13


inputFocusClass : Element.Attribute msg
inputFocusClass =
    Element.htmlAttribute <| Html.Attributes.class "linkFocus"


headerButton : HtmlId ButtonId -> { onPress : msg, label : String } -> Element msg
headerButton htmlId { onPress, label } =
    Element.Input.button
        [ Element.mouseOver [ Element.Background.color <| Element.rgba 1 1 1 0.5 ]
        , Element.paddingXY 8 8
        , Element.Font.center
        , inputFocusClass
        , Id.htmlIdToString htmlId |> Html.Attributes.id |> Element.htmlAttribute
        ]
        { onPress = Just onPress
        , label = Element.text label
        }


headerLink : Bool -> { route : Route, label : String } -> Element msg
headerLink isSelected { route, label } =
    Element.link
        [ Element.mouseOver [ Element.Background.color <| Element.rgba 1 1 1 0.5 ]
        , if isSelected then
            Element.Background.color <| Element.rgba 1 1 1 0.5

          else
            Element.Background.color <| Element.rgba 1 1 1 0
        , Element.paddingXY 8 8
        , Element.Font.center
        , inputFocusClass
        ]
        { url = Route.encode route
        , label = Element.text label
        }


emailAddressText : EmailAddress -> Element msg
emailAddressText emailAddress =
    Element.el
        [ Element.Font.bold ]
        (Element.text (EmailAddress.toString emailAddress))


routeLink : Route -> String -> Element msg
routeLink route label =
    Element.link
        [ Element.Font.color linkColor, inputFocusClass ]
        { url = Route.encode route, label = Element.text label }


section : String -> Element msg -> Element msg
section sectionTitle content =
    Element.column
        [ Element.spacing 8
        , Element.padding 8
        , Element.Border.rounded 4
        , inputBackground False
        ]
        [ Element.paragraph [ Element.Font.bold ] [ Element.text sectionTitle ]
        , content
        ]


button : HtmlId ButtonId -> { onPress : msg, label : String } -> Element msg
button htmlId { onPress, label } =
    Element.Input.button
        [ Element.Border.width 2
        , Element.Border.color grey
        , Element.padding 8
        , Element.Border.rounded 4
        , Element.Font.center
        , Element.Font.color readingMuted
        , Element.width (Element.minimum 150 Element.shrink)
        , Id.htmlIdToString htmlId |> Html.Attributes.id |> Element.htmlAttribute
        ]
        { onPress = Just onPress
        , label = Element.text label
        }


linkColor : Element.Color
linkColor =
    Element.rgb 0.2 0.2 1


submitButton : HtmlId ButtonId -> Bool -> { onPress : msg, label : String } -> Element msg
submitButton htmlId isSubmitting { onPress, label } =
    Element.Input.button
        [ Element.Background.color <| Element.rgb 0.1 0.6 0.25
        , Element.padding 10
        , Element.Border.rounded 4
        , Element.Font.center
        , Element.Font.color <| Element.rgb 1 1 1
        , Id.htmlIdToString htmlId |> Html.Attributes.id |> Element.htmlAttribute
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


dangerButton : HtmlId ButtonId -> { onPress : msg, label : String } -> Element msg
dangerButton htmlId { onPress, label } =
    Element.Input.button
        [ Element.Background.color <| Element.rgb 0.9 0 0
        , Element.padding 10
        , Element.Border.rounded 4
        , Element.Font.center
        , Element.Font.color <| Element.rgb 1 1 1
        , Id.htmlIdToString htmlId |> Html.Attributes.id |> Element.htmlAttribute
        ]
        { onPress = Just onPress
        , label = Element.text label
        }


filler : Element.Length -> Element msg
filler length =
    Element.el [ Element.height length ] Element.none


titleFontSize : Element.Attr decorative msg
titleFontSize =
    Element.Font.size 28


defaultFont : Element.Attribute msg
defaultFont =
    Element.Font.family [ Element.Font.typeface "Inter" ]


defaultFontColor : Element.Attr decorative msg
defaultFontColor =
    Element.Font.color readingBlack


defaultFontSize : Element.Attr decorative msg
defaultFontSize =
    Element.Font.size 16


title : String -> Element msg
title text =
    Element.paragraph [ titleFontSize, Element.Region.heading 1 ] [ Element.text text ]


hr : Element msg
hr =
    Element.el
        [ Element.padding 8, Element.width Element.fill ]
        (Element.el
            [ Element.width Element.fill
            , Element.height (Element.px 2)
            , Element.Background.color <| Element.rgb 0.4 0.4 0.4
            ]
            Element.none
        )


error : String -> Element msg
error errorMessage =
    Element.paragraph
        [ Element.paddingEach { left = 4, right = 4, top = 4, bottom = 0 }
        , Element.Font.color <| Element.rgb 0.9 0.2 0.2
        , Element.Font.size 14
        , Element.Font.medium
        ]
        [ Element.text errorMessage ]


formError : String -> Element msg
formError errorMessage =
    Element.paragraph
        [ Element.Font.color <| Element.rgb 0.9 0.2 0.2
        ]
        [ Element.text errorMessage ]


radioGroup : (a -> HtmlId RadioButtonId) -> (a -> msg) -> Nonempty a -> Maybe a -> (a -> String) -> Maybe String -> Element msg
radioGroup htmlId onSelect options selected optionToLabel maybeError =
    let
        optionsView =
            List.Nonempty.map
                (\value ->
                    Element.Input.button
                        [ Element.width Element.fill
                        , Element.paddingEach { left = 32, right = 8, top = 8, bottom = 8 }
                        , htmlId value |> Id.htmlIdToString |> Html.Attributes.id |> Element.htmlAttribute
                        ]
                        { onPress = Just (onSelect value)
                        , label =
                            optionToLabel value
                                |> Element.text
                                |> List.singleton
                                |> Element.paragraph
                                    [ if Just value == selected then
                                        Element.onLeft <| Element.text "✅"

                                      else
                                        Element.onLeft <| Element.text "☐"
                                    , Element.paddingXY 8 0
                                    ]
                        }
                )
                options
                |> List.Nonempty.toList
    in
    optionsView
        ++ [ Maybe.map error maybeError |> Maybe.withDefault Element.none ]
        |> Element.column
            [ inputBackground (maybeError /= Nothing)
            , Element.Border.rounded 4
            , Element.padding 8
            ]


inputBackground : Bool -> Element.Attr decorative msg
inputBackground hasError =
    Element.Background.color <|
        if hasError then
            redLight

        else
            transparent


contentWidth : Element.Attribute msg
contentWidth =
    Element.width (Element.maximum 800 Element.fill)


inputBorder : Bool -> Element.Attr decorative msg
inputBorder hasError =
    Element.Border.color <|
        if hasError then
            red

        else
            grey


inputBorderWidth : Bool -> Element.Attribute msg
inputBorderWidth hasError =
    Element.Border.width <|
        if hasError then
            2

        else
            1


textInput : HtmlId TextInputId -> (String -> msg) -> String -> String -> Maybe String -> Element msg
textInput htmlId onChange text labelText maybeError =
    Element.column
        [ Element.width Element.fill
        , Element.Border.rounded 4
        ]
        [ Element.Input.text
            [ Element.width Element.fill
            , Id.htmlIdToString htmlId |> Html.Attributes.id |> Element.htmlAttribute
            , inputBorder (maybeError /= Nothing)
            ]
            { text = text
            , onChange = onChange
            , placeholder = Nothing
            , label = formLabelAbove labelText
            }
        , Maybe.map error maybeError |> Maybe.withDefault Element.none
        ]


multiline : HtmlId TextInputId -> (String -> msg) -> String -> String -> Maybe String -> Element msg
multiline htmlId onChange text labelText maybeError =
    Element.column
        [ Element.width Element.fill
        , Element.Border.rounded 4
        ]
        [ Element.Input.multiline
            [ Element.width Element.fill
            , Element.height (Element.px 200)
            , Id.htmlIdToString htmlId |> Html.Attributes.id |> Element.htmlAttribute
            , inputBorder (maybeError /= Nothing)
            , inputBorderWidth (maybeError /= Nothing)
            ]
            { text = text
            , onChange = onChange
            , placeholder = Nothing
            , label = formLabelAbove labelText
            , spellcheck = True
            }
        , Maybe.map error maybeError |> Maybe.withDefault Element.none
        ]


numberInput : HtmlId NumberInputId -> (String -> msg) -> String -> String -> Maybe String -> Element msg
numberInput htmlId onChange value labelText maybeError =
    Element.column
        [ inputBackground (maybeError /= Nothing)
        , Element.padding 8
        , Element.Border.rounded 4
        ]
        [ Element.paragraph
            [ Element.paddingEach { left = 4, right = 4, top = 0, bottom = 4 } ]
            [ Element.text labelText ]
        , Html.input
            [ Html.Attributes.type_ "number"
            , Html.Events.onInput onChange
            , Id.htmlIdToString htmlId |> Html.Attributes.id
            , Html.Attributes.value value
            , Html.Attributes.style "line-height" "38px"
            ]
            []
            |> Element.html
            |> Element.el []
        , maybeError |> Maybe.map error |> Maybe.withDefault Element.none
        ]


dateTimeInput :
    { dateInputId : HtmlId DateInputId
    , timeInputId : HtmlId TimeInputId
    , dateChanged : String -> msg
    , timeChanged : String -> msg
    , labelText : String
    , minTime : Time.Posix
    , timezone : Time.Zone
    , dateText : String
    , timeText : String
    , maybeError : Maybe String
    }
    -> Element msg
dateTimeInput { dateInputId, timeInputId, dateChanged, timeChanged, labelText, minTime, timezone, dateText, timeText, maybeError } =
    Element.column
        [ inputBackground (maybeError /= Nothing)
        , Element.padding 8
        , Element.Border.rounded 4
        ]
        [ Element.paragraph
            [ Element.paddingEach { left = 4, right = 4, top = 0, bottom = 4 } ]
            [ Element.text labelText ]
        , Element.row [ Element.spacing 8 ]
            [ dateInput dateInputId dateChanged (Date.fromPosix timezone minTime) dateText
            , timeInput timeInputId timeChanged timeText
            ]
        , maybeError |> Maybe.map error |> Maybe.withDefault Element.none
        ]


timeInput : HtmlId TimeInputId -> (String -> msg) -> String -> Element msg
timeInput htmlId onChange time =
    Html.input
        [ Html.Attributes.type_ "time"
        , Html.Events.onInput onChange
        , Html.Attributes.value time
        , Html.Attributes.style "padding" "0"
        , Id.htmlIdToString htmlId |> Html.Attributes.id
        ]
        []
        |> Element.html
        |> Element.el []


timeToString : Time.Zone -> Time.Posix -> String
timeToString timezone time =
    String.fromInt (Time.toHour timezone time)
        ++ ":"
        ++ String.padLeft 2 '0' (String.fromInt (Time.toMinute timezone time))


dateInput : HtmlId DateInputId -> (String -> msg) -> Date -> String -> Element msg
dateInput htmlId onChange minDateTime date =
    Html.input
        [ Html.Attributes.type_ "date"
        , Html.Attributes.min (datestamp minDateTime)
        , Html.Events.onInput onChange
        , Html.Attributes.value date
        , Html.Attributes.style "padding" "0"
        , Id.htmlIdToString htmlId |> Html.Attributes.id
        ]
        []
        |> Element.html
        |> Element.el []


datestamp : Date -> String
datestamp date =
    String.fromInt (Date.year date)
        ++ "-"
        ++ String.padLeft 2 '0' (String.fromInt (Date.monthNumber date))
        ++ "-"
        ++ String.padLeft 2 '0' (String.fromInt (Date.day date))


formLabelAbove : String -> Element.Input.Label msg
formLabelAbove labelText =
    Element.Input.labelAbove
        [ Element.paddingEach { top = 0, right = 0, bottom = 5, left = 0 }
        , Element.Font.medium
        , Element.Font.size 13
        , Element.Font.color blueGrey
        ]
        (Element.paragraph [] [ Element.text labelText ])


columnCard : List (Element msg) -> Element msg
columnCard children =
    Element.column
        (Element.width Element.fill
            :: Element.spacing 30
            :: cardAttributes
        )
        children


cardAttributes : List (Element.Attribute msg)
cardAttributes =
    [ Element.Border.rounded 4
    , Element.padding 15
    , Element.Border.width 1
    , Element.Border.color grey
    , Element.Border.shadow { offset = ( 0, 3 ), size = -1, blur = 3, color = grey }
    ]
