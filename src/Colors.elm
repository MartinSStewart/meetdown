module Colors exposing (..)

import Color
import Color.Convert exposing (hexToColor)
import Element exposing (Color)


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


toCssString : Color -> String
toCssString =
    Element.toRgb >> Color.fromRgba >> Color.toCssString
