module Colors exposing (..)

import Color
import Color.Convert exposing (hexToColor)
import Element exposing (..)


readingBlack =
    fromHex "#022047"


readingMuted =
    fromHex "#4A5E7A"


red =
    fromHex "#F8777B"


green =
    fromHex "#55CCB6"


blue =
    fromHex "#509CDB"


redLight =
    Element.rgb 1 0.9059 0.9059


lightGrey =
    fromHex "#f4f6f8"


grey =
    fromHex "#E0E4E8"


blueGrey =
    fromHex "#4A5E7A"


darkGrey =
    fromHex "#AEB7C4"


black =
    fromHex "#000"


white =
    fromHex "#FFF"


transparent =
    rgba255 0 0 0 0


fromHex : String -> Color
fromHex str =
    case hexToColor str of
        Ok col ->
            let
                x =
                    Color.toRgba col
            in
            Element.rgba x.red x.green x.blue x.alpha

        Err _ ->
            Element.rgb 255 0 0


toCssString =
    Element.toRgb >> Color.fromRgba >> Color.toCssString
