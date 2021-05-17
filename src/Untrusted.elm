module Untrusted exposing (Untrusted, untrust, validateEmail, validateGroupName)

import EmailAddress exposing (EmailAddress)
import GroupName exposing (GroupName)


type Untrusted a
    = Untrusted a


validateEmail : Untrusted EmailAddress -> Result String EmailAddress
validateEmail (Untrusted email) =
    let
        emailText =
            EmailAddress.toString email
    in
    EmailAddress.fromString emailText |> Result.fromMaybe emailText


validateGroupName : Untrusted GroupName -> Result String GroupName
validateGroupName (Untrusted groupName) =
    let
        groupNameText =
            GroupName.toString groupName
    in
    GroupName.fromString groupNameText |> Result.toMaybe |> Result.fromMaybe groupNameText


untrust : a -> Untrusted a
untrust =
    Untrusted
