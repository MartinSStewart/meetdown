module GroupDescription exposing (Error(..), GroupDescription, fromString, maxLength, toString)


type GroupDescription
    = GroupDescription String


type Error
    = GroupDescriptionTooLong


maxLength : number
maxLength =
    3000


fromString : String -> Result Error GroupDescription
fromString text =
    let
        trimmed =
            String.trim text
    in
    if String.length trimmed > maxLength then
        Err GroupDescriptionTooLong

    else
        Ok (GroupDescription trimmed)


toString : GroupDescription -> String
toString (GroupDescription description) =
    description
