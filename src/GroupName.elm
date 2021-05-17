module GroupName exposing (Error(..), GroupName, fromString, maxLength, minLength, namesMatch, toString)


type GroupName
    = GroupName String


type Error
    = GroupNameTooShort
    | GroupNameTooLong


minLength : number
minLength =
    4


maxLength : number
maxLength =
    50


fromString : String -> Result Error GroupName
fromString text =
    let
        trimmed =
            String.trim text
    in
    if String.length trimmed < minLength then
        Err GroupNameTooShort

    else if String.length trimmed > maxLength then
        Err GroupNameTooLong

    else
        Ok (GroupName trimmed)


toString : GroupName -> String
toString (GroupName groupName) =
    groupName


namesMatch : GroupName -> GroupName -> Bool
namesMatch (GroupName name0) (GroupName name1) =
    String.toLower name0 == String.toLower name1
