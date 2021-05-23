module Group exposing (Group, GroupVisibility(..), description, events, init, name, ownerId, visibility)

import Description exposing (Description)
import Duration
import Event exposing (Event)
import GroupName exposing (GroupName)
import Id exposing (Id, UserId)
import Quantity
import Time


type Group
    = Group
        { ownerId : Id UserId
        , name : GroupName
        , description : Description
        , events : List Event
        , visibility : GroupVisibility
        }


type GroupVisibility
    = PrivateGroup
    | PublicGroup


init : Id UserId -> GroupName -> Description -> List Event -> GroupVisibility -> Group
init ownerId_ groupName description_ events_ groupVisibility_ =
    Group
        { ownerId = ownerId_
        , name = groupName
        , description = description_
        , events = List.sortBy (.endTime >> Time.posixToMillis) events_
        , visibility = groupVisibility_
        }


ownerId : Group -> Id UserId
ownerId (Group a) =
    a.ownerId


name : Group -> GroupName
name (Group a) =
    a.name


description : Group -> Description
description (Group a) =
    a.description


visibility : Group -> GroupVisibility
visibility (Group a) =
    a.visibility


{-| pastEvents and futureEvents are sorted so the head element is the event closest to the currentTime
-}
events : Time.Posix -> Group -> { pastEvents : List Event, futureEvents : List Event }
events currentTime (Group a) =
    a.events
        |> List.partition
            (\event ->
                Duration.from currentTime event.endTime |> Quantity.lessThanZero
            )
        |> (\( past, future ) -> { pastEvents = List.reverse past, futureEvents = future })
