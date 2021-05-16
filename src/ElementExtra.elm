module ElementExtra exposing (button, nonemptyText)

import Element exposing (Element)
import Element.Input
import String.Nonempty exposing (NonemptyString)


nonemptyText : NonemptyString -> Element msg
nonemptyText =
    String.Nonempty.toString >> Element.text


button : List (Element.Attribute msg) -> { onPress : msg, label : Element msg } -> Element msg
button attributes { onPress, label } =
    Element.Input.button
        attributes
        { onPress = Just onPress
        , label = label
        }
