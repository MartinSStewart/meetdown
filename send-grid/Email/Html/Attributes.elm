module Email.Html.Attributes exposing (alt, attribute, backgroundColor, border, borderBottom, borderBottomColor, borderBottomStyle, borderBottomWidth, borderColor, borderLeft, borderLeftColor, borderLeftStyle, borderLeftWidth, borderRadius, borderRight, borderRightColor, borderRightStyle, borderRightWidth, borderStyle, borderTop, borderTopColor, borderWidth, color, fontFamily, fontSize, fontStyle, fontVariant, height, href, letterSpacing, lineHeight, padding, paddingBottom, paddingLeft, paddingRight, paddingTop, src, style, textAlign, verticalAlign, width)

{-| Only html attributes that are supported by all major email clients are listed here.
If you need something not that's included (and potentially not universally supported) use [`attribute`](#attribute) or [`style`](#style).

These sources were used to determine what should be included:
<https://www.campaignmonitor.com/css/color-background/background/>
<https://www.pinpointe.com/blog/email-campaign-html-and-css-support>
<https://www.caniemail.com/>

Open an issue on github if something is missing or incorrectly included.


# Attributes and styles

@docs alt, attribute, backgroundColor, border, borderBottom, borderBottomColor, borderBottomStyle, borderBottomWidth, borderColor, borderLeft, borderLeftColor, borderLeftStyle, borderLeftWidth, borderRadius, borderRight, borderRightColor, borderRightStyle, borderRightWidth, borderStyle, borderTop, borderTopColor, borderWidth, color, fontFamily, fontSize, fontStyle, fontVariant, height, href, letterSpacing, lineHeight, padding, paddingBottom, paddingLeft, paddingRight, paddingTop, src, style, textAlign, verticalAlign, width

-}

import Internal exposing (Attribute(..))


{-| Use this if there's a style you want to add that isn't present in this module.
Note that there's a risk that it isn't supported by some email clients.
-}
style : String -> String -> Attribute
style =
    StyleAttribute


{-| Use this if there's a attribute you want to add that isn't present in this module.
Note that there's a risk that it isn't supported by some email clients.
-}
attribute : String -> String -> Attribute
attribute =
    Attribute


{-| -}
backgroundColor : String -> Attribute
backgroundColor =
    StyleAttribute "background-color"


{-| -}
border : String -> Attribute
border =
    StyleAttribute "border"


{-| -}
borderRadius : String -> Attribute
borderRadius =
    StyleAttribute "border-radius"


{-| -}
borderBottom : String -> Attribute
borderBottom =
    StyleAttribute "border-bottom"


{-| -}
borderBottomColor : String -> Attribute
borderBottomColor =
    StyleAttribute "border-bottom-color"


{-| -}
borderBottomStyle : String -> Attribute
borderBottomStyle =
    StyleAttribute "border-bottom-style"


{-| -}
borderBottomWidth : String -> Attribute
borderBottomWidth =
    StyleAttribute "border-bottom-width"


{-| -}
borderColor : String -> Attribute
borderColor =
    StyleAttribute "border-color"


{-| -}
borderLeft : String -> Attribute
borderLeft =
    StyleAttribute "border-left"


{-| -}
borderLeftColor : String -> Attribute
borderLeftColor =
    StyleAttribute "border-left-color"


{-| -}
borderLeftStyle : String -> Attribute
borderLeftStyle =
    StyleAttribute "border-left-style"


{-| -}
borderLeftWidth : String -> Attribute
borderLeftWidth =
    StyleAttribute "border-left-width"


{-| -}
borderRight : String -> Attribute
borderRight =
    StyleAttribute "border-right"


{-| -}
borderRightColor : String -> Attribute
borderRightColor =
    StyleAttribute "border-right-color"


{-| -}
borderRightStyle : String -> Attribute
borderRightStyle =
    StyleAttribute "border-right-style"


{-| -}
borderRightWidth : String -> Attribute
borderRightWidth =
    StyleAttribute "border-right-width"


{-| -}
borderStyle : String -> Attribute
borderStyle =
    StyleAttribute "border-style"


{-| -}
borderTop : String -> Attribute
borderTop =
    StyleAttribute "border-top"


{-| -}
borderTopColor : String -> Attribute
borderTopColor =
    StyleAttribute "border-top-color"


{-| -}
borderWidth : String -> Attribute
borderWidth =
    StyleAttribute "border-width"


{-| -}
color : String -> Attribute
color =
    StyleAttribute "color"


{-| -}
width : String -> Attribute
width =
    StyleAttribute "width"


{-| -}
maxWidth : String -> Attribute
maxWidth =
    StyleAttribute "max-width"


{-| -}
minWidth : String -> Attribute
minWidth =
    StyleAttribute "min-width"


{-| -}
height : String -> Attribute
height =
    StyleAttribute "height"


{-| -}
padding : String -> Attribute
padding =
    StyleAttribute "padding"


{-| -}
paddingLeft : String -> Attribute
paddingLeft =
    StyleAttribute "padding-left"


{-| -}
paddingRight : String -> Attribute
paddingRight =
    StyleAttribute "padding-right"


{-| -}
paddingBottom : String -> Attribute
paddingBottom =
    StyleAttribute "padding-bottom"


{-| -}
paddingTop : String -> Attribute
paddingTop =
    StyleAttribute "padding-top"


{-| -}
lineHeight : String -> Attribute
lineHeight =
    StyleAttribute "line-height"


{-| -}
fontSize : String -> Attribute
fontSize =
    StyleAttribute "font-size"


{-| -}
fontFamily : String -> Attribute
fontFamily =
    StyleAttribute "font-family"


{-| -}
fontStyle : String -> Attribute
fontStyle =
    StyleAttribute "font-style"


{-| -}
fontVariant : String -> Attribute
fontVariant =
    StyleAttribute "font-variant"


{-| -}
letterSpacing : String -> Attribute
letterSpacing =
    StyleAttribute "letter-spacing"


{-| -}
textAlign : String -> Attribute
textAlign =
    StyleAttribute "text-align"


{-| -}
src : String -> Attribute
src =
    Attribute "src"


{-| -}
alt : String -> Attribute
alt =
    Attribute "alt"


{-| -}
href : String -> Attribute
href =
    Attribute "href"


{-| -}
verticalAlign : String -> Attribute
verticalAlign =
    Attribute "vertical-align"
