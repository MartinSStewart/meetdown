module Untrusted exposing (Untrusted, untrust, validateEmail)

import EmailAddress exposing (EmailAddress)


type Untrusted a
    = Untrusted a


validateEmail : Untrusted EmailAddress -> Result String EmailAddress
validateEmail (Untrusted email) =
    let
        emailText =
            EmailAddress.toString email
    in
    EmailAddress.fromString emailText |> Result.fromMaybe emailText


untrust : a -> Untrusted a
untrust =
    Untrusted
