module Ui exposing
    ( button
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

import Colors exposing (UserConfig)
import Date exposing (Date)
import Effect.Browser.Dom as Dom exposing (HtmlId)
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
import Json.Decode
import List.Nonempty exposing (Nonempty)
import Route exposing (Route)
import Svg
import Svg.Attributes
import Time
import Time.Extra as Time
import TimeExtra as Time


css : UserConfig -> Html msg
css userConfig =
    Html.node "style"
        []
        [ """
          @import url('https://rsms.me/inter/inter.css');
          html { font-family: 'Inter', sans-serif; scrollbar-gutter: stable; background-color: """
            ++ Colors.toCssString userConfig.background
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


pageContentAttributes : List (Element.Attribute msg)
pageContentAttributes =
    [ Element.padding 8
    , Element.centerX
    , Element.width (Element.maximum 800 Element.fill)
    , Element.spacing 20
    ]


inputFocusClass : Element.Attribute msg
inputFocusClass =
    Element.htmlAttribute <| Html.Attributes.class "linkFocus"


horizontalLine : UserConfig -> Element msg
horizontalLine userConfig =
    Element.el
        [ Element.width Element.fill
        , Element.height (Element.px 1)
        , Element.Background.color userConfig.darkGrey
        ]
        Element.none


headerButton : Bool -> HtmlId -> { onPress : msg, label : String } -> Element msg
headerButton isMobile_ htmlId { onPress, label } =
    Element.Input.button
        [ Element.mouseOver [ Element.Background.color <| Element.rgba 1 1 1 0.5 ]
        , if isMobile_ then
            Element.padding 6

          else
            Element.padding 8
        , Element.Font.center
        , inputFocusClass
        , Dom.idToAttribute htmlId |> Element.htmlAttribute
        , if isMobile_ then
            Element.Font.size 13

          else
            Element.Font.size 16
        ]
        { onPress = Just onPress
        , label = Element.text label
        }


headerLink : UserConfig -> Bool -> Bool -> { route : Route, label : String } -> Element msg
headerLink userConfig isMobile_ isSelected { route, label } =
    Element.link
        [ Element.mouseOver [ Element.Background.color <| Element.rgba 1 1 1 0.5 ]
        , Element.below <|
            if isSelected then
                Element.el
                    [ Element.paddingXY 4 0, Element.width Element.fill ]
                    (Element.el
                        [ Element.Background.color userConfig.submit
                        , Element.width Element.fill
                        , Element.height (Element.px 2)
                        ]
                        Element.none
                    )

            else
                Element.none
        , if isMobile_ then
            Element.padding 6

          else
            Element.padding 8
        , Element.Font.center
        , if isMobile_ then
            Element.Font.size 13

          else
            Element.Font.size 16
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


routeLink : UserConfig -> Route -> String -> Element msg
routeLink userConfig route label =
    Element.link
        [ Element.Font.color userConfig.link, inputFocusClass, Element.Font.underline ]
        { url = Route.encode route, label = Element.text label }


routeLinkNewTab : UserConfig -> Route -> String -> Element msg
routeLinkNewTab userConfig route label =
    Element.newTabLink
        [ Element.Font.color userConfig.link, inputFocusClass, Element.Font.underline ]
        { url = "https://meetdown.app" ++ Route.encode route, label = Element.text label }


externalLink : UserConfig -> String -> String -> Element msg
externalLink userConfig url label =
    Element.newTabLink
        [ Element.Font.color userConfig.link, inputFocusClass, Element.Font.underline ]
        { url = url, label = Element.text label }


mailToLink : UserConfig -> String -> Maybe String -> Element msg
mailToLink userConfig emailAddress maybeSubject =
    Element.link
        [ Element.Font.color userConfig.link, inputFocusClass ]
        { url =
            "mailto:"
                ++ emailAddress
                ++ (case maybeSubject of
                        Just subject ->
                            "?subject=" ++ subject

                        Nothing ->
                            ""
                   )
        , label = Element.text emailAddress
        }


section : UserConfig -> String -> Element msg -> Element msg
section userConfig sectionTitle content =
    Element.column
        [ Element.spacing 8
        , Element.Border.rounded 4
        , inputBackground userConfig False
        , Element.alignTop
        ]
        [ Element.paragraph [ Element.Font.bold ] [ Element.text sectionTitle ]
        , content
        ]


button : UserConfig -> HtmlId -> { onPress : msg, label : String } -> Element msg
button userConfig htmlId { onPress, label } =
    Element.Input.button
        [ Element.Border.width 2
        , Element.Border.color userConfig.grey
        , Element.padding 8
        , Element.Border.rounded 4
        , Element.Font.center
        , Element.Font.color userConfig.mutedText
        , Element.width (Element.minimum 150 Element.fill)
        , Dom.idToAttribute htmlId |> Element.htmlAttribute
        ]
        { onPress = Just onPress
        , label = Element.text label
        }


linkButton : UserConfig -> { route : Route, label : String } -> Element msg
linkButton userConfig { route, label } =
    Element.link
        [ Element.Border.width 2
        , Element.Border.color userConfig.grey
        , Element.padding 8
        , Element.Border.rounded 4
        , Element.Font.center
        , Element.Font.color userConfig.mutedText
        , Element.width (Element.minimum 150 Element.fill)
        ]
        { url = Route.encode route
        , label = Element.text label
        }


submitButton : UserConfig -> HtmlId -> Bool -> { onPress : msg, label : String } -> Element msg
submitButton userConfig htmlId isSubmitting { onPress, label } =
    Element.Input.button
        [ Element.Background.color userConfig.submit
        , Element.padding 10
        , Element.Border.rounded 4
        , Element.Font.center
        , Element.Font.color userConfig.invertedText
        , Dom.idToAttribute htmlId |> Element.htmlAttribute
        , Element.width Element.fill
        , Element.Font.medium
        ]
        { onPress = Just onPress
        , label = labelWithHourglass isSubmitting label
        }


smallSubmitButton : HtmlId -> Bool -> { onPress : msg, label : String } -> Element msg
smallSubmitButton htmlId isSubmitting { onPress, label } =
    Element.Input.button
        [ Element.Background.color <| Element.rgb 0.1 0.6 0.25
        , Element.paddingXY 8 4
        , Element.Border.rounded 4
        , Element.Font.center
        , Element.Font.color <| Element.rgb 1 1 1
        , Dom.idToAttribute htmlId |> Element.htmlAttribute
        ]
        { onPress = Just onPress
        , label = labelWithHourglass isSubmitting label
        }


dangerButton : UserConfig -> HtmlId -> Bool -> { onPress : msg, label : String } -> Element msg
dangerButton userConfig htmlId isSubmitting { onPress, label } =
    Element.Input.button
        [ Element.Background.color userConfig.error
        , Element.padding 10
        , Element.Border.rounded 4
        , Element.Font.center
        , Element.Font.color userConfig.invertedText
        , Dom.idToAttribute htmlId |> Element.htmlAttribute
        ]
        { onPress = Just onPress
        , label = labelWithHourglass isSubmitting label
        }


labelWithHourglass : Bool -> String -> Element msg
labelWithHourglass isSubmitting label =
    Element.el
        [ Element.width Element.fill
        , Element.paddingXY 30 0
        , if isSubmitting then
            Element.inFront (Element.el [] (Element.text "⌛"))

          else
            Element.inFront Element.none
        ]
        (Element.text label)


titleFontSize : Element.Attr decorative msg
titleFontSize =
    Element.Font.size 28


defaultFont : Element.Attribute msg
defaultFont =
    Element.Font.family [ Element.Font.typeface "Inter" ]


defaultFontColor : UserConfig -> Element.Attr decorative msg
defaultFontColor userConfig =
    Element.Font.color userConfig.defaultText


defaultFontSize : Element.Attr decorative msg
defaultFontSize =
    Element.Font.size 16


title : String -> Element msg
title text =
    Element.paragraph [ titleFontSize, Element.Region.heading 1 ] [ Element.text text ]


error : UserConfig -> String -> Element msg
error userConfig errorMessage =
    Element.paragraph
        [ Element.paddingEach { left = 4, right = 4, top = 4, bottom = 0 }
        , Element.Font.color userConfig.error
        , Element.Font.size 14
        , Element.Font.medium
        ]
        [ Element.text errorMessage ]


formError : UserConfig -> String -> Element msg
formError userConfig errorMessage =
    Element.paragraph
        [ Element.Font.color userConfig.error ]
        [ Element.text errorMessage ]


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
        |> Element.html
        |> Element.el [ Element.alignTop ]


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
        |> Element.html
        |> Element.el [ Element.alignTop ]


radioGroup : UserConfig -> (a -> HtmlId) -> (a -> msg) -> Nonempty a -> Maybe a -> (a -> String) -> Maybe String -> Element msg
radioGroup userConfig htmlId onSelect options selected optionToLabel maybeError =
    let
        optionsView =
            List.Nonempty.map
                (\value ->
                    Element.Input.button
                        [ Element.width Element.fill
                        , Element.paddingXY 0 6
                        , htmlId value |> Dom.idToAttribute |> Element.htmlAttribute
                        ]
                        { onPress = Just (onSelect value)
                        , label =
                            Element.row
                                []
                                [ if Just value == selected then
                                    checkboxChecked

                                  else
                                    checkboxEmpty
                                , optionToLabel value
                                    |> Element.text
                                    |> List.singleton
                                    |> Element.paragraph [ Element.paddingXY 8 0 ]
                                ]
                        }
                )
                options
                |> List.Nonempty.toList
    in
    optionsView
        ++ [ Maybe.map (error userConfig) maybeError |> Maybe.withDefault Element.none ]
        |> Element.column []


inputBackground : UserConfig -> Bool -> Element.Attr decorative msg
inputBackground userConfig hasError =
    Element.Background.color <|
        if hasError then
            userConfig.errorBackground

        else
            Element.rgba255 0 0 0 0


contentWidth : Element.Attribute msg
contentWidth =
    Element.width (Element.maximum 800 Element.fill)


inputBorder : UserConfig -> Bool -> Element.Attr decorative msg
inputBorder userConfig hasError =
    Element.Border.color <|
        if hasError then
            userConfig.error

        else
            userConfig.darkGrey


inputBorderWidth : Bool -> Element.Attribute msg
inputBorderWidth hasError =
    Element.Border.width <|
        if hasError then
            2

        else
            1


textInput : UserConfig -> HtmlId -> (String -> msg) -> String -> String -> Maybe String -> Element msg
textInput userConfig htmlId onChange text labelText maybeError =
    Element.column
        [ Element.width Element.fill
        , Element.Border.rounded 4
        ]
        [ Element.Input.text
            [ Element.width Element.fill
            , Dom.idToAttribute htmlId |> Element.htmlAttribute
            , inputBorder userConfig (maybeError /= Nothing)
            , Element.Background.color userConfig.background
            ]
            { text = text
            , onChange = onChange
            , placeholder = Nothing
            , label = formLabelAbove userConfig labelText
            }
        , Maybe.map (error userConfig) maybeError |> Maybe.withDefault Element.none
        ]


multiline : UserConfig -> HtmlId -> (String -> msg) -> String -> String -> Maybe String -> Element msg
multiline userConfig htmlId onChange text labelText maybeError =
    Element.column
        [ Element.width Element.fill
        , Element.Border.rounded 4
        ]
        [ Element.Input.multiline
            [ Element.width Element.fill
            , Element.height (Element.px 200)
            , Dom.idToAttribute htmlId |> Element.htmlAttribute
            , inputBorder userConfig (maybeError /= Nothing)
            , inputBorderWidth (maybeError /= Nothing)
            , Element.Background.color userConfig.background
            ]
            { text = text
            , onChange = onChange
            , placeholder = Nothing
            , label = formLabelAbove userConfig labelText
            , spellcheck = True
            }
        , Maybe.map (error userConfig) maybeError |> Maybe.withDefault Element.none
        ]


numberInput : UserConfig -> HtmlId -> (String -> msg) -> String -> String -> Maybe String -> Element msg
numberInput userConfig htmlId onChange value labelText maybeError =
    Element.column
        [ Element.spacing 4
        ]
        [ formLabelAboveEl userConfig labelText
        , Html.input
            ([ Html.Attributes.type_ "number"
             , Html.Events.onInput onChange
             , Dom.idToAttribute htmlId
             , Html.Attributes.value value
             , Html.Attributes.style "line-height" "38px"
             , Html.Attributes.style "text-align" "right"
             , Html.Attributes.style "padding-right" "4px"
             ]
                ++ htmlInputStyle userConfig
            )
            []
            |> Element.html
            |> Element.el []
        , maybeError |> Maybe.map (error userConfig) |> Maybe.withDefault Element.none
        ]


dateTimeInput :
    UserConfig
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
dateTimeInput userConfig { dateInputId, timeInputId, dateChanged, timeChanged, labelText, minTime, timezone, dateText, timeText, isDisabled, maybeError } =
    Element.column
        [ Element.spacing 4 ]
        [ formLabelAboveEl userConfig labelText
        , Element.wrappedRow [ Element.spacing 8 ]
            [ dateInput userConfig dateInputId dateChanged (Date.fromPosix timezone minTime) dateText isDisabled
            , timeInput userConfig timeInputId timeChanged timeText isDisabled
            ]
        , maybeError |> Maybe.map (error userConfig) |> Maybe.withDefault Element.none
        ]


timeInput : UserConfig -> HtmlId -> (String -> msg) -> String -> Bool -> Element msg
timeInput userConfig htmlId onChange time isDisabled =
    Html.input
        ([ Html.Attributes.type_ "time"
         , Html.Events.onInput onChange
         , Html.Attributes.value time
         , Html.Attributes.style "padding" "5px"
         , Dom.idToAttribute htmlId
         , Html.Attributes.disabled isDisabled
         ]
            ++ htmlInputStyle userConfig
        )
        []
        |> Element.html
        |> Element.el []


timeToString : Time.Zone -> Time.Posix -> String
timeToString timezone time =
    String.fromInt (Time.toHour timezone time)
        ++ ":"
        ++ String.padLeft 2 '0' (String.fromInt (Time.toMinute timezone time))


dateInput : UserConfig -> HtmlId -> (String -> msg) -> Date -> String -> Bool -> Element msg
dateInput userConfig htmlId onChange minDateTime date isDisabled =
    Html.input
        ([ Html.Attributes.type_ "date"
         , Html.Attributes.min (datestamp minDateTime)
         , Html.Events.onInput onChange
         , Html.Attributes.value date
         , Html.Attributes.style "padding" "5px"
         , Dom.idToAttribute htmlId
         , Html.Attributes.disabled isDisabled
         ]
            ++ htmlInputStyle userConfig
        )
        []
        |> Element.html
        |> Element.el []


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


formLabelAbove : UserConfig -> String -> Element.Input.Label msg
formLabelAbove userConfig labelText =
    Element.Input.labelAbove
        [ Element.paddingEach { top = 0, right = 0, bottom = 5, left = 0 }
        , Element.Font.medium
        , Element.Font.size 13
        , Element.Font.color userConfig.textInputHeading
        ]
        (Element.paragraph [] [ Element.text labelText ])


formLabelAboveEl : UserConfig -> String -> Element msg
formLabelAboveEl userConfig labelText =
    Element.el
        [ Element.paddingEach { top = 0, right = 0, bottom = 5, left = 0 }
        , Element.Font.medium
        , Element.Font.size 13
        , Element.Font.color userConfig.textInputHeading
        ]
        (Element.paragraph [] [ Element.text labelText ])


columnCard : UserConfig -> List (Element msg) -> Element msg
columnCard userConfig children =
    Element.column
        (Element.width Element.fill
            :: Element.spacing 30
            :: cardAttributes userConfig
        )
        children


cardAttributes : UserConfig -> List (Element.Attribute msg)
cardAttributes userConfig =
    [ Element.Border.rounded 4
    , Element.padding 15
    , Element.Border.width 1
    , Element.Border.color userConfig.grey
    , Element.Border.shadow { offset = ( 0, 3 ), size = -1, blur = 3, color = userConfig.grey }
    ]


loadingView : Element msg
loadingView =
    Element.el
        [ Element.Font.size 20
        , Element.centerX
        , Element.centerY
        , Element.htmlAttribute (Html.Attributes.style "animation-name" "fade-in")
        , Element.htmlAttribute (Html.Attributes.style "animation-duration" "1s")
        ]
        (Element.text "Loading")


loadingError : UserConfig -> String -> Element msg
loadingError userConfig text =
    Element.el
        [ Element.Font.size 20
        , Element.centerX
        , Element.centerY
        , Element.Font.color userConfig.error
        ]
        (Element.text text)


htmlInputStyle : UserConfig -> List (Html.Attribute msg)
htmlInputStyle userConfig =
    [ Html.Attributes.style "border-color" (Colors.toCssString userConfig.darkGrey)
    , Html.Attributes.style "border-width" "1px"
    , Html.Attributes.style "border-style" "solid"
    , Html.Attributes.style "border-radius" "4px"
    , Html.Attributes.style "background-color" (Colors.toCssString userConfig.background)
    , Html.Attributes.style "color" (Colors.toCssString userConfig.defaultText)
    ]
