module Ui exposing (button, error, formBackground, formError, headerButton, headerButtonAttributes, headerLink, inputBackground, multiline, radioGroup, submitButton, textInput, title)

import Element exposing (Element)
import Element.Background
import Element.Border
import Element.Font
import Element.Input
import List.Nonempty exposing (Nonempty)
import Route exposing (Route)


headerButtonAttributes : List (Element.Attribute msg)
headerButtonAttributes =
    [ Element.mouseOver [ Element.Background.color <| Element.rgba 1 1 1 0.5 ]
    , Element.padding 8
    ]


headerButton : { onPress : msg, label : String } -> Element msg
headerButton { onPress, label } =
    Element.Input.button
        [ Element.mouseOver [ Element.Background.color <| Element.rgba 1 1 1 0.5 ]
        , Element.paddingXY 16 8
        , Element.Font.center
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
        ]
        { url = Route.encode route Nothing
        , label = Element.text label
        }


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
        ]
        { onPress = Just onPress
        , label = Element.text label
        }


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


title : String -> Element msg
title text =
    Element.paragraph [ Element.Font.size 24 ] [ Element.text text ]


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
                        [ Element.width Element.fill, Element.paddingEach { left = 32, right = 8, top = 8, bottom = 8 } ]
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


formBackground : Element.Attr decorative msg
formBackground =
    Element.Background.color <| Element.rgb 1 1 1


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
