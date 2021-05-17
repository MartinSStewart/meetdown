module GroupName exposing (Error(..), GroupName, fromString, toString)


type GroupName
    = GroupName String


type Error
    = GroupNameTooShort
    | GroupNameTooLong


fromString : String -> Result Error GroupName
fromString text =
    if String.length text < 4 then
        Err GroupNameTooShort

    else if String.length text > 50 then
        Err GroupNameTooLong

    else
        Ok (GroupName text)


toString : GroupName -> String
toString (GroupName groupName) =
    groupName
