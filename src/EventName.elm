module EventName exposing (Error(..), EventName(..), errorToString, fromString, maxLength, minLength, toString)


type EventName
    = EventName String


type Error
    = EventNameTooShort
    | EventNameTooLong


errorToString : String -> Error -> String
errorToString originalAddress error =
    let
        trimmed =
            String.trim originalAddress
    in
    case error of
        EventNameTooShort ->
            "Name is "
                ++ String.fromInt (String.length trimmed)
                ++ " characters long. It needs to be at least "
                ++ String.fromInt minLength
                ++ "."

        EventNameTooLong ->
            "Name is "
                ++ String.fromInt (String.length trimmed)
                ++ " characters long. Keep it under "
                ++ String.fromInt maxLength
                ++ "."


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
