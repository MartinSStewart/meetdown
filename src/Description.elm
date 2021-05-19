module Description exposing (Description, Error(..), empty, fromString, maxLength, toString)


type Description
    = Description String


type Error
    = DescriptionTooLong


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


empty : Description
empty =
    Description ""
