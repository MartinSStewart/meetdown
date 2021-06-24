module Description exposing (Description(..), Error(..), empty, errorToString, fromString, maxLength, toParagraph, toString)

import Element exposing (Element)
import Element.Font
import MarkdownThemed


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


toParagraph : Bool -> Description -> Element msg
toParagraph searchPreview description =
    if toString description == "" then
        Element.paragraph [ Element.Font.italic ] [ Element.text "No description" ]

    else
        MarkdownThemed.renderMinimal searchPreview (toString description)


empty : Description
empty =
    Description ""
