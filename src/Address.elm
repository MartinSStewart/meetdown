module Address exposing (Address(..), Error(..), errorToString, fromString, toString)


type Address
    = Address String


type Error
    = AddressTooShort
    | AddressTooLong


errorToString : String -> Error -> String
errorToString originalAddress error =
    let
        trimmed =
            String.trim originalAddress
    in
    case error of
        AddressTooShort ->
            "Address is "
                ++ String.fromInt (String.length trimmed)
                ++ " characters long. It needs to be at least "
                ++ String.fromInt minLength
                ++ "."

        AddressTooLong ->
            "Address is "
                ++ String.fromInt (String.length trimmed)
                ++ " characters long. Keep it under "
                ++ String.fromInt maxLength
                ++ "."


minLength : number
minLength =
    4


maxLength : number
maxLength =
    200


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
