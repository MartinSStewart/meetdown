module Untrusted exposing
    ( Untrusted
    , untrust
    , validateDescription
    , validateEmailAddress
    , validateGroupName
    , validateName
    , validateProfileImage
    )

import Description exposing (Description)
import EmailAddress exposing (EmailAddress)
import GroupForm exposing (GroupFormValidated)
import GroupName exposing (GroupName)
import Name exposing (Name)
import ProfileImage exposing (ProfileImage)


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


validateProfileImage : Untrusted ProfileImage -> Maybe ProfileImage
validateProfileImage (Untrusted profileImage) =
    case ProfileImage.getCustomImageUrl profileImage of
        Just dataUrl ->
            ProfileImage.customImage dataUrl |> Result.toMaybe

        Nothing ->
            Just ProfileImage.defaultImage


untrust : a -> Untrusted a
untrust =
    Untrusted
