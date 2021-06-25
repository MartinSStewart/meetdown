module Untrusted exposing
    ( Untrusted
    , description
    , eventDuration
    , eventName
    , eventType
    , maxAttendees
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
import MaxAttendees exposing (MaxAttendees)
import Name exposing (Name)
import ProfileImage exposing (ProfileImage)


{-| We can't be sure a value we got from the frontend hasn't been tampered with.
In cases where an opaque type uses code to give some kind of guarantee (for example
MaxAttendees makes sure the max number of attendees is at least 2) we wrap the value in Unstrusted to
make sure we don't forget to validate the value again on the backend.
-}
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


maxAttendees : Untrusted MaxAttendees -> Maybe MaxAttendees
maxAttendees (Untrusted a) =
    case MaxAttendees.toMaybe a of
        Just maxAttendees_ ->
            MaxAttendees.maxAttendees maxAttendees_ |> Result.toMaybe

        Nothing ->
            Just MaxAttendees.noLimit


untrust : a -> Untrusted a
untrust =
    Untrusted
