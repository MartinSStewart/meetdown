module Ui exposing (button, css, dangerButton, emailAddressText, error, filler, formError, headerButton, headerLink, inputBackground, inputFocusClass, linkColor, multiline, onEnter, radioGroup, routeLink, section, submitButton, textInput, title)

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


css : Html msg
css =
    Html.node "style"
        []
        [ Html.text """


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
                    if code == 13 then
                        Json.Decode.succeed ( msg, True )

                    else
                        Json.Decode.fail "Not the enter key"
                )
        )
        |> Element.htmlAttribute


inputFocusClass : Element.Attribute msg
inputFocusClass =
    Element.htmlAttribute <| Html.Attributes.class "linkFocus"


headerButton : { onPress : msg, label : String } -> Element msg
headerButton { onPress, label } =
    Element.Input.button
        [ Element.mouseOver [ Element.Background.color <| Element.rgba 1 1 1 0.5 ]
        , Element.paddingXY 16 8
        , Element.Font.center
        , inputFocusClass
        ]
        { onPress = Just onPress
        , label = Element.text label
        }


headerLink : { route : Route, label : String } -> Element msg
headerLink { route, label } =
    Element.link
        [ Element.mouseOver [ Element.Background.color <| Element.rgba 1 1 1 0.5 ]
        , Element.paddingXY 16 8
        , Element.Font.center
        , inputFocusClass
        ]
        { url = Route.encode route
        , label = Element.text label
        }


emailAddressText : EmailAddress -> Element msg
emailAddressText emailAddress =
    Element.el
        [ Element.Font.color <| Element.rgb 0.1 0.1 1 ]
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


button : { onPress : msg, label : String } -> Element msg
button { onPress, label } =
    Element.Input.button
        [ Element.Background.color <| Element.rgb 0.9 0.9 0.9
        , Element.Border.width 2
        , Element.Border.color <| Element.rgb 0.3 0.3 0.3
        , Element.padding 8
        , Element.Border.rounded 4
        , Element.Font.center
        , Element.width (Element.minimum 150 Element.shrink)
        , inputFocusClass
        ]
        { onPress = Just onPress
        , label = Element.text label
        }


linkColor : Element.Color
linkColor =
    Element.rgb 0.2 0.2 1


submitButton : Bool -> { onPress : msg, label : String } -> Element msg
submitButton isSubmitting { onPress, label } =
    Element.Input.button
        [ Element.Background.color <| Element.rgb 0.1 0.6 0.25
        , Element.padding 10
        , Element.Border.rounded 4
        , Element.Font.center
        , Element.Font.color <| Element.rgb 1 1 1
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


dangerButton : { onPress : msg, label : String } -> Element msg
dangerButton { onPress, label } =
    Element.Input.button
        [ Element.Background.color <| Element.rgb 0.9 0 0
        , Element.padding 10
        , Element.Border.rounded 4
        , Element.Font.center
        , Element.Font.color <| Element.rgb 1 1 1
        , inputFocusClass
        ]
        { onPress = Just onPress
        , label = Element.text label
        }


filler : Element.Length -> Element msg
filler length =
    Element.el [ Element.height length ] Element.none


title : String -> Element msg
title text =
    Element.paragraph [ Element.Font.size 32, Element.Region.heading 1 ] [ Element.text text ]


error : String -> Element msg
error errorMessage =
    Element.paragraph
        [ Element.paddingEach { left = 4, right = 4, top = 4, bottom = 0 }
        , Element.Font.color <| Element.rgb 0.9 0.2 0.2
        , Element.Font.size 16
        ]
        [ Element.text errorMessage ]


formError : String -> Element msg
formError errorMessage =
    Element.paragraph
        [ Element.Font.color <| Element.rgb 0.9 0.2 0.2
        ]
        [ Element.text errorMessage ]


radioGroup : (a -> msg) -> Nonempty a -> Maybe a -> (a -> String) -> Maybe String -> Element msg
radioGroup onSelect options selected optionToLabel maybeError =
    let
        optionsView =
            List.Nonempty.map
                (\value ->
                    Element.Input.button
                        [ Element.width Element.fill
                        , Element.paddingEach { left = 32, right = 8, top = 8, bottom = 8 }
                        , inputFocusClass
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
            Element.rgb 1 0.9059 0.9059

        else
            Element.rgb 0.94 0.94 0.94


textInput : (String -> msg) -> String -> String -> Maybe String -> Element msg
textInput onChange text labelText maybeError =
    Element.column
        [ Element.width Element.fill
        , inputBackground (maybeError /= Nothing)
        , Element.paddingEach { left = 8, right = 8, top = 8, bottom = 8 }
        , Element.Border.rounded 4
        ]
        [ Element.Input.text
            [ Element.width Element.fill ]
            { text = text
            , onChange = onChange
            , placeholder = Nothing
            , label =
                Element.Input.labelAbove
                    [ Element.paddingXY 4 0 ]
                    (Element.paragraph [] [ Element.text labelText ])
            }
        , Maybe.map error maybeError |> Maybe.withDefault Element.none
        ]


multiline : (String -> msg) -> String -> String -> Maybe String -> Element msg
multiline onChange text labelText maybeError =
    Element.column
        [ Element.width Element.fill
        , inputBackground (maybeError /= Nothing)
        , Element.paddingEach { left = 8, right = 8, top = 8, bottom = 8 }
        , Element.Border.rounded 4
        ]
        [ Element.Input.multiline
            [ Element.width Element.fill, Element.height (Element.px 200) ]
            { text = text
            , onChange = onChange
            , placeholder = Nothing
            , label =
                Element.Input.labelAbove
                    [ Element.paddingXY 4 0 ]
                    (Element.paragraph [] [ Element.text labelText ])
            , spellcheck = True
            }
        , Maybe.map error maybeError |> Maybe.withDefault Element.none
        ]
