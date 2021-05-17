module Ui exposing (button, buttonAttributes, error, header, headerButtonAttributes, radioGroup)

import Element exposing (Element)
import Element.Background
import Element.Border
import Element.Font
import Element.Input
import List.Nonempty exposing (Nonempty)


headerButtonAttributes : List (Element.Attribute msg)
headerButtonAttributes =
    [ Element.mouseOver [ Element.Background.color <| Element.rgba 1 1 1 0.5 ]
    , Element.padding 8
    ]


buttonAttributes : List (Element.Attr () msg)
buttonAttributes =
    [ Element.Background.color <| Element.rgb 0.9 0.9 0.9
    , Element.Border.width 2
    , Element.Border.color <| Element.rgb 0.3 0.3 0.3
    , Element.padding 8
    , Element.Border.rounded 4
    ]


button : List (Element.Attribute msg) -> { onPress : msg, label : Element msg } -> Element msg
button attributes { onPress, label } =
    Element.Input.button
        attributes
        { onPress = Just onPress
        , label = label
        }


header : String -> Element msg
header text =
    Element.paragraph [ Element.Font.size 24 ] [ Element.text text ]


error : String -> Element msg
error errorMessage =
    Element.paragraph [ Element.Font.color <| Element.rgb 0.9 0.2 0.2 ] [ Element.text errorMessage ]


radioGroup : (a -> msg) -> Nonempty a -> Maybe a -> (a -> String) -> Element msg
radioGroup onSelect options selected optionToLabel =
    List.Nonempty.map
        (\value ->
            Element.Input.button
                [ Element.width Element.fill, Element.paddingEach { left = 32, right = 8, top = 8, bottom = 8 } ]
                { onPress = Just (onSelect value)
                , label =
                    optionToLabel value
                        |> Element.text
                        |> Element.el
                            [ if Just value == selected then
                                Element.onLeft <| Element.text "✅"

                              else
                                Element.onLeft <| Element.text "☐"
                            ]
                }
        )
        options
        |> List.Nonempty.toList
        |> Element.column
            []
