module Email.Html exposing
    ( a, b, br, div, font, h1, h2, h3, h4, h5, h6, hr, img, label, li, node, ol, p, span, strong, table, td, text, th, tr, u, ul, Attribute, Html
    , inlineGifImg, inlineJpgImg, inlinePngImg
    , toHtml, toString
    )

{-| Only html tags that are supported by major all email clients are listed here.
If you need something not that's included (and potentially not universally supported) use [`node`](#node).

These sources were used to determine what should be included:
<https://www.campaignmonitor.com/css/color-background/background/>
<https://www.pinpointe.com/blog/email-campaign-html-and-css-support>
<https://www.caniemail.com/>

Open an issue on github if something is missing or incorrectly included.


# Html tags

@docs a, b, br, div, font, h1, h2, h3, h4, h5, h6, hr, img, label, li, node, ol, p, span, strong, table, td, text, th, tr, u, ul, Attribute, Html


# Inline images

@docs inlineGifImg, inlineJpgImg, inlinePngImg


# Convert

@docs toHtml, toString

-}

import Bytes exposing (Bytes)
import Html
import Internal


{-| -}
type alias Html =
    Internal.Html


{-| -}
type alias Attribute =
    Internal.Attribute


{-| Convert a [`Email.Html.Html`](#Html) into normal a [`Html`](https://package.elm-lang.org/packages/elm/html/latest/Html). Useful if you want to preview your email content.
-}
toHtml : Html -> Html.Html msg
toHtml =
    Internal.toHtml


{-| Convert a [`Email.Html.Html`](#Html) into a String and a list of images. Useful if you want to use [`Email.Html.Html`](#Html) rendered values in other places.
-}
toString : Html -> ( String, List ( String, { content : Bytes, imageType : Internal.ImageType } ) )
toString =
    Internal.toString


{-| This allows you to create html tags not included in this module (at the risk of it not rendering correctly in some email clients).
-}
node : String -> List Attribute -> List Html -> Html
node =
    Internal.Node


{-| -}
div : List Attribute -> List Html -> Html
div =
    Internal.Node "div"


{-| -}
table : List Attribute -> List Html -> Html
table =
    Internal.Node "table"


{-| -}
tr : List Attribute -> List Html -> Html
tr =
    Internal.Node "tr"


{-| -}
td : List Attribute -> List Html -> Html
td =
    Internal.Node "tr"


{-| -}
th : List Attribute -> List Html -> Html
th =
    Internal.Node "th"


{-| -}
br : List Attribute -> List Html -> Html
br =
    Internal.Node "br"


{-| -}
hr : List Attribute -> List Html -> Html
hr =
    Internal.Node "hr"


{-| -}
a : List Attribute -> List Html -> Html
a =
    Internal.Node "a"


{-| -}
b : List Attribute -> List Html -> Html
b =
    Internal.Node "b"


{-| -}
font : List Attribute -> List Html -> Html
font =
    Internal.Node "font"


{-| -}
h1 : List Attribute -> List Html -> Html
h1 =
    Internal.Node "h1"


{-| -}
h2 : List Attribute -> List Html -> Html
h2 =
    Internal.Node "h2"


{-| -}
h3 : List Attribute -> List Html -> Html
h3 =
    Internal.Node "h3"


{-| -}
h4 : List Attribute -> List Html -> Html
h4 =
    Internal.Node "h4"


{-| -}
h5 : List Attribute -> List Html -> Html
h5 =
    Internal.Node "h5"


{-| -}
h6 : List Attribute -> List Html -> Html
h6 =
    Internal.Node "h6"


{-| -}
img : List Attribute -> List Html -> Html
img =
    Internal.Node "img"


{-| -}
label : List Attribute -> List Html -> Html
label =
    Internal.Node "label"


{-| -}
li : List Attribute -> List Html -> Html
li =
    Internal.Node "li"


{-| -}
ol : List Attribute -> List Html -> Html
ol =
    Internal.Node "ol"


{-| -}
p : List Attribute -> List Html -> Html
p =
    Internal.Node "p"


{-| -}
span : List Attribute -> List Html -> Html
span =
    Internal.Node "span"


{-| -}
strong : List Attribute -> List Html -> Html
strong =
    Internal.Node "strong"


{-| -}
u : List Attribute -> List Html -> Html
u =
    Internal.Node "u"


{-| -}
ul : List Attribute -> List Html -> Html
ul =
    Internal.Node "ul"


{-| If you want to embed a png image within the email body, use this function.
The normal approach of using a base64 string as the image src doesn't always work with emails.
-}
inlinePngImg : Bytes -> List Attribute -> List Html -> Html
inlinePngImg content =
    { content = content
    , imageType = Internal.Png
    }
        |> Internal.InlineImage


{-| If you want to embed a jpg image within the email body, use this function.
The normal approach of using a base64 string as the image src doesn't always with emails.
-}
inlineJpgImg : Bytes -> List Attribute -> List Html -> Html
inlineJpgImg content =
    { content = content
    , imageType = Internal.Jpeg
    }
        |> Internal.InlineImage


{-| If you want to embed a gif within the email body, use this function.
The normal approach of using a base64 string as the image src doesn't always with emails.

Note that [some email clients](https://www.caniemail.com/search/?s=gif) won't animate the gif.

-}
inlineGifImg : Bytes -> List Attribute -> List Html -> Html
inlineGifImg content =
    { content = content
    , imageType = Internal.Gif
    }
        |> Internal.InlineImage


{-| -}
text : String -> Internal.Html
text =
    Internal.TextNode
