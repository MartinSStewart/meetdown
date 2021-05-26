module EventName exposing (Error(..), EventName, fromString, maxLength, minLength, toString)


type EventName
    = EventName String


type Error
    = EventNameTooShort
    | EventNameTooLong


minLength : number
minLength =
    4


maxLength : number
maxLength =
    50


fromString : String -> Result Error EventName
fromString text =
    let
        trimmed =
            String.trim text
    in
    if String.length trimmed < minLength then
        Err EventNameTooShort

    else if String.length trimmed > maxLength then
        Err EventNameTooLong

    else
        Ok (EventName trimmed)


toString : EventName -> String
toString (EventName groupName) =
    groupName
