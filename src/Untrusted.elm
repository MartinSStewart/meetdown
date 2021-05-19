module Untrusted exposing
    ( Untrusted
    , untrust
    , validateDescription
    , validateEmailAddress
    , validateGroupName
    , validateName
    )

import Description exposing (Description)
import EmailAddress exposing (EmailAddress)
import GroupForm exposing (GroupFormValidated)
import GroupName exposing (GroupName)
import Name exposing (Name)


type Untrusted a
    = Untrusted a


validateName : Untrusted Name -> Maybe Name
validateName (Untrusted name) =
    Name.toString name |> Name.fromString |> Result.toMaybe


validateEmailAddress : Untrusted EmailAddress -> Maybe EmailAddress
validateEmailAddress (Untrusted email) =
    EmailAddress.toString email |> EmailAddress.fromString


validateGroupName : Untrusted GroupName -> Maybe GroupName
validateGroupName (Untrusted groupName) =
    GroupName.toString groupName |> GroupName.fromString |> Result.toMaybe


validateDescription : Untrusted Description -> Maybe Description
validateDescription (Untrusted description) =
    Description.toString description |> Description.fromString |> Result.toMaybe


untrust : a -> Untrusted a
untrust =
    Untrusted
