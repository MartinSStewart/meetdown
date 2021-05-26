module Address exposing (Address, Error(..), fromString, maxLength, minLength, toString)


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
