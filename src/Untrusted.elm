module Untrusted exposing (Untrusted, untrust, validateEmail)

import Email exposing (Email)


type Untrusted a
    = Untrusted a


validateEmail : Untrusted Email -> Result String Email
validateEmail (Untrusted email) =
    let
        emailText =
            Email.toString email
    in
    Email.fromString emailText |> Result.fromMaybe emailText


untrust : a -> Untrusted a
untrust =
    Untrusted
