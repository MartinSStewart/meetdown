module UserConfig exposing (..)

import Colors exposing (fromHex)
import Element exposing (Color)


type alias Texts =
    { welcomePage : String
    , title : String
    , daysUntilEvent : Int -> String
    }


type alias UserConfig =
    { theme : Theme
    , texts : Texts
    }


type alias Theme =
    { defaultText : Color
    , mutedText : Color
    , error : Color
    , submit : Color
    , link : Color
    , errorBackground : Color
    , lightGrey : Color
    , grey : Color
    , textInputHeading : Color
    , darkGrey : Color
    , invertedText : Color
    , background : Color
    , heroSvg : String
    }


darkTheme : Theme
darkTheme =
    { defaultText = fromHex "#e8ecf1"
    , mutedText = fromHex "#c7ccd3"
    , error = fromHex "#f1484e"
    , submit = fromHex "#54c0ad"
    , link = fromHex "#5aaff5"
    , errorBackground = Element.rgb 0.349 0.2745 0.2745
    , lightGrey = fromHex "#4c4d4d"
    , grey = fromHex "#6e7072"
    , textInputHeading = fromHex "#8db8ef"
    , darkGrey = fromHex "#7e858d"
    , invertedText = fromHex "#151515"
    , background = fromHex "#252525"
    , heroSvg = "/homepage-hero-dark.svg"
    }


lightTheme : Theme
lightTheme =
    { defaultText = fromHex "#022047"
    , mutedText = fromHex "#4A5E7A"
    , error = fromHex "#F8777B"
    , submit = fromHex "#55CCB6"
    , link = fromHex "#509CDB"
    , errorBackground = Element.rgb 1 0.9059 0.9059
    , lightGrey = fromHex "#f4f6f8"
    , grey = fromHex "#E0E4E8"
    , textInputHeading = fromHex "#4A5E7A"
    , darkGrey = fromHex "#AEB7C4"
    , invertedText = fromHex "#FFF"
    , background = fromHex "#FFF"
    , heroSvg = "/homepage-hero.svg"
    }


default : UserConfig
default =
    { theme = lightTheme
    , texts = englishTexts
    }


englishTexts : Texts
englishTexts =
    { welcomePage = "Welcome to the event!"
    , title = "Event"
    , daysUntilEvent = \days -> "Days until event: " ++ String.fromInt days
    }


frenchTexts : Texts
frenchTexts =
    { welcomePage = "Bienvenue à l'événement!"
    , title = "Événement"
    , daysUntilEvent = \days -> "Jours jusqu'à l'événement: " ++ String.fromInt days
    }
