module EventName exposing (Error(..), EventName(..), errorToString, fromString, toString)

import UserConfig exposing (Texts)


type EventName
    = EventName String


type Error
    = EventNameTooShort
    | EventNameTooLong


errorToString : Texts -> Error -> String
errorToString texts error =
    case error of
        EventNameTooShort ->
            texts.nameMustBeAtLeast minLength

        EventNameTooLong ->
            texts.nameMustBeAtMost maxLength


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
