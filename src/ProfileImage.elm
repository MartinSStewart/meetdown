module ProfileImage exposing (ProfileImage, customImage, defaultImage, getCustomImageUrl, image)

import Element exposing (Element)
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


size : number
size =
    128


getCustomImageUrl : ProfileImage -> Maybe String
getCustomImageUrl profileImage =
    case profileImage of
        DefaultImage ->
            Nothing

        CustomImage dataUrl ->
            Just dataUrl


image : ProfileImage -> Element msg
image profileImage =
    Element.image
        [ Element.width (Element.px size)
        , Element.height (Element.px size)
        , Ui.inputBackground False
        ]
        { src =
            case profileImage of
                DefaultImage ->
                    "./default-profile.png"

                CustomImage dataUrl ->
                    dataUrl
        , description = "Your profile image"
        }
