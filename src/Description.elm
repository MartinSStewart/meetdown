module Description exposing (Description(..), Error(..), empty, errorToString, fromString, maxLength, toParagraph, toString)

import Element exposing (Element)
import MarkdownThemed
import UserConfig exposing (UserConfig)


type Description
    = Description String


type Error
    = DescriptionTooLong


errorToString : String -> Error -> String
errorToString originalDescription error =
    let
        trimmed =
            String.trim originalDescription
    in
    case error of
        DescriptionTooLong ->
            "Description is "
                ++ String.fromInt (String.length trimmed)
                ++ " characters long. Keep it under "
                ++ String.fromInt maxLength
                ++ "."


maxLength : number
maxLength =
    3000


fromString : String -> Result Error Description
fromString text =
    let
        trimmed =
            String.trim text
    in
    if String.length trimmed > maxLength then
        Err DescriptionTooLong

    else
        Ok (Description trimmed)


toString : Description -> String
toString (Description description) =
    description


toParagraph : UserConfig -> Bool -> Description -> Element msg
toParagraph userConfig searchPreview description =
    if toString description == "" then
        MarkdownThemed.renderMinimal userConfig.theme searchPreview "_No description_"

    else
        MarkdownThemed.renderMinimal userConfig.theme searchPreview (toString description)


empty : Description
empty =
    Description ""
