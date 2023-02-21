module Address exposing (Address(..), Error(..), errorToString, fromString, toString)

import UserConfig exposing (Texts)


type Address
    = Address String


type Error
    = AddressTooShort
    | AddressTooLong


minLength : number
minLength =
    4


maxLength : number
maxLength =
    200


errorToString : Texts -> String -> Error -> String
errorToString texts originalAddress error =
    let
        trimmed =
            String.trim originalAddress
    in
    case error of
        AddressTooShort ->
            texts.addressTooShort (String.length trimmed) minLength

        AddressTooLong ->
            texts.addressTooLong (String.length trimmed) maxLength


fromString : String -> Result Error Address
fromString text =
    let
        trimmed =
            String.trim text
    in
    if String.length trimmed < minLength then
        Err AddressTooShort

    else if String.length trimmed > maxLength then
        Err AddressTooLong

    else
        Ok (Address trimmed)


toString : Address -> String
toString (Address groupName) =
    groupName
