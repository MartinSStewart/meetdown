module Untrusted exposing
    ( Untrusted
    , untrust
    , validateEmail
    , validateGroupDescription
    , validateGroupName
    )

import EmailAddress exposing (EmailAddress)
import GroupDescription exposing (GroupDescription)
import GroupForm exposing (GroupFormValidated)
import GroupName exposing (GroupName)


type Untrusted a
    = Untrusted a


validateEmail : Untrusted EmailAddress -> Result () EmailAddress
validateEmail (Untrusted email) =
    EmailAddress.toString email |> EmailAddress.fromString |> Result.fromMaybe ()


validateGroupName : Untrusted GroupName -> Result () GroupName
validateGroupName (Untrusted groupName) =
    GroupName.toString groupName |> GroupName.fromString |> Result.mapError (\_ -> ())


validateGroupDescription : Untrusted GroupDescription -> Result () GroupDescription
validateGroupDescription (Untrusted groupName) =
    GroupDescription.toString groupName |> GroupDescription.fromString |> Result.mapError (\_ -> ())


untrust : a -> Untrusted a
untrust =
    Untrusted
