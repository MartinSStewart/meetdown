module Colors exposing (..)

import Color
import Color.Convert exposing (hexToColor)
import Element exposing (Color)


type alias UserConfig =
    { defaultText : Color
    , mutedText : Color
    , error : Color
    , submit : Color
    , link : Color
    , errorBackground : Color
    , lightGrey : Color
    , grey : Color
    , blueGrey : Color
    , darkGrey : Color
    , invertedText : Color
    , background : Color
    }


lightTheme : UserConfig
lightTheme =
    { defaultText = fromHex "#022047"
    , mutedText = fromHex "#4A5E7A"
    , error = fromHex "#F8777B"
    , submit = fromHex "#55CCB6"
    , link = fromHex "#509CDB"
    , errorBackground = Element.rgb 1 0.9059 0.9059
    , lightGrey = fromHex "#f4f6f8"
    , grey = fromHex "#E0E4E8"
    , blueGrey = fromHex "#4A5E7A"
    , darkGrey = fromHex "#AEB7C4"
    , invertedText = fromHex "#FFF"
    , background = fromHex "#FFF"
    }


darkTheme : UserConfig
darkTheme =
    { defaultText = fromHex "#d5d9de"
    , mutedText = fromHex "#c7ccd3"
    , error = fromHex "#7c191d"
    , submit = fromHex "#3e9182"
    , link = fromHex "#396f9b"
    , errorBackground = Element.rgb 0.349 0.2745 0.2745
    , lightGrey = fromHex "#4c4d4d"
    , grey = fromHex "#6e7072"
    , blueGrey = fromHex "#394a60"
    , darkGrey = fromHex "#7e858d"
    , invertedText = fromHex "#1a1a1a"
    , background = fromHex "#1a1a1a"
    }


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
