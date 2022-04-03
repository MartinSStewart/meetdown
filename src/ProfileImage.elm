module ProfileImage exposing (ProfileImage(..), customImage, defaultImage, defaultSize, getCustomImageUrl, image, smallImage)

import Colors exposing (..)
import Element exposing (Element)
import Element.Background
import Element.Border
import Pixels exposing (Pixels)
import Quantity exposing (Quantity)
import Ui


type ProfileImage
    = DefaultImage
    | CustomImage String


type Error
    = InvalidDataUrlPrefix
    | StringIsTooLong


defaultImage : ProfileImage
defaultImage =
    DefaultImage


customImage : String -> Result Error ProfileImage
customImage data =
    if String.length data > 100000 then
        Err StringIsTooLong

    else if String.startsWith "data:image/png;base64," data |> not then
        Err InvalidDataUrlPrefix

    else
        CustomImage data |> Ok


defaultSize : Quantity Int Pixels
defaultSize =
    Pixels.pixels 128


getCustomImageUrl : ProfileImage -> Maybe String
getCustomImageUrl profileImage =
    case profileImage of
        DefaultImage ->
            Nothing

        CustomImage dataUrl ->
            Just dataUrl


image : Quantity Int Pixels -> ProfileImage -> Element msg
image size profileImage =
    Element.image
        [ Element.width (Element.px (Pixels.inPixels size))
        , Element.height (Element.px (Pixels.inPixels size))
        , Element.Border.rounded 9999
        , Element.clip
        , Ui.inputBackground False
        ]
        { src =
            case profileImage of
                DefaultImage ->
                    "/anonymous.png"

                CustomImage dataUrl ->
                    dataUrl
        , description = "Profile image"
        }


smallImage : ProfileImage -> Element msg
smallImage profileImage =
    Element.image
        [ Element.width (Element.px <| Pixels.inPixels defaultSize // 2)
        , Element.height (Element.px <| Pixels.inPixels defaultSize // 2)
        , Element.Border.rounded 9999
        , Element.clip
        , Element.Background.color grey
        ]
        { src =
            case profileImage of
                DefaultImage ->
                    "/anonymous.png"

                CustomImage dataUrl ->
                    dataUrl
        , description = "Profile image"
        }
