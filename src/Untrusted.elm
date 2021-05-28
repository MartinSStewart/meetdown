module Untrusted exposing
    ( Untrusted
    , description
    , eventDuration
    , eventName
    , eventType
    , untrust
    , validateEmailAddress
    , validateGroupName
    , validateName
    , validateProfileImage
    )

import Address
import Description exposing (Description)
import EmailAddress exposing (EmailAddress)
import Event exposing (EventType(..))
import EventDuration exposing (EventDuration)
import EventName exposing (EventName)
import GroupName exposing (GroupName)
import Link
import Name exposing (Name)
import ProfileImage exposing (ProfileImage)
import Url


type Untrusted a
    = Untrusted a


validateName : Untrusted Name -> Maybe Name
validateName (Untrusted a) =
    Name.toString a |> Name.fromString |> Result.toMaybe


validateEmailAddress : Untrusted EmailAddress -> Maybe EmailAddress
validateEmailAddress (Untrusted a) =
    EmailAddress.toString a |> EmailAddress.fromString


validateGroupName : Untrusted GroupName -> Maybe GroupName
validateGroupName (Untrusted a) =
    GroupName.toString a |> GroupName.fromString |> Result.toMaybe


eventName : Untrusted EventName -> Maybe EventName
eventName (Untrusted a) =
    EventName.toString a |> EventName.fromString |> Result.toMaybe


eventDuration : Untrusted EventDuration -> Maybe EventDuration
eventDuration (Untrusted a) =
    EventDuration.toMinutes a |> EventDuration.fromMinutes |> Result.toMaybe


eventType : Untrusted EventType -> Maybe EventType
eventType (Untrusted a) =
    case a of
        MeetOnline (Just link) ->
            Link.toString link |> Link.fromString |> Maybe.map (Just >> MeetOnline)

        MeetOnline Nothing ->
            MeetOnline Nothing |> Just

        MeetInPerson (Just address) ->
            Address.toString address |> Address.fromString |> Result.toMaybe |> Maybe.map (Just >> MeetInPerson)

        MeetInPerson Nothing ->
            MeetInPerson Nothing |> Just


description : Untrusted Description -> Maybe Description
description (Untrusted a) =
    Description.toString a |> Description.fromString |> Result.toMaybe


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
