module Unsafe exposing (addAttendee, addEvent, description, emailAddress, eventDurationFromMinutes, eventName, groupName, name)

import Description exposing (Description)
import EmailAddress exposing (EmailAddress)
import Event exposing (Event)
import EventDuration exposing (EventDuration)
import EventName exposing (EventName)
import Group exposing (Group)
import GroupName exposing (GroupName)
import Id exposing (Id, UserId)
import Name exposing (Name)


name : String -> Name
name text =
    case Name.fromString text of
        Ok ok ->
            ok

        Err _ ->
            unreachable ()


groupName : String -> GroupName
groupName text =
    case GroupName.fromString text of
        Ok ok ->
            ok

        Err _ ->
            unreachable ()


description : String -> Description
description text =
    case Description.fromString text of
        Ok ok ->
            ok

        Err _ ->
            unreachable ()


addEvent : Event -> Group -> Group
addEvent event group =
    case Group.addEvent event group of
        Ok value ->
            value

        Err _ ->
            unreachable ()


addAttendee : Id UserId -> Event -> Event
addAttendee id event =
    case Event.addAttendee id event of
        Ok ok ->
            ok

        Err _ ->
            unreachable ()


eventDurationFromMinutes : Int -> EventDuration
eventDurationFromMinutes minutes =
    case EventDuration.fromMinutes minutes of
        Ok ok ->
            ok

        Err _ ->
            unreachable ()


eventName : String -> EventName
eventName text =
    case EventName.fromString text of
        Ok ok ->
            ok

        Err _ ->
            unreachable ()


emailAddress : String -> EmailAddress
emailAddress text =
    case EmailAddress.fromString text of
        Just ok ->
            ok

        Nothing ->
            unreachable ()


{-| Be very careful when using this!
-}
unreachable : () -> a
unreachable () =
    let
        _ =
            causeStackOverflow 0
    in
    unreachable ()


causeStackOverflow : Int -> Int
causeStackOverflow value =
    causeStackOverflow value + 1
