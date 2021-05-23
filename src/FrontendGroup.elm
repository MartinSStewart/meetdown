module FrontendGroup exposing (FrontendGroup, description, events, init, name, owner, ownerId, visibility)

import Description exposing (Description)
import Duration
import Event exposing (Event)
import FrontendUser exposing (FrontendUser)
import GroupForm exposing (GroupVisibility)
import GroupName exposing (GroupName)
import Id exposing (Id, UserId)
import Quantity
import Time


type FrontendGroup
    = FrontendGroup
        { ownerId : Id UserId
        , owner : FrontendUser
        , name : GroupName
        , description : Description
        , events : List Event
        , visibility : GroupVisibility
        }


init : Id UserId -> FrontendUser -> GroupName -> Description -> List Event -> GroupVisibility -> FrontendGroup
init ownerId_ owner_ groupName description_ events_ groupVisibility_ =
    FrontendGroup
        { ownerId = ownerId_
        , owner = owner_
        , name = groupName
        , description = description_
        , events = List.sortBy (.endTime >> Time.posixToMillis) events_
        , visibility = groupVisibility_
        }


ownerId : FrontendGroup -> Id UserId
ownerId (FrontendGroup a) =
    a.ownerId


owner : FrontendGroup -> FrontendUser
owner (FrontendGroup a) =
    a.owner


name : FrontendGroup -> GroupName
name (FrontendGroup a) =
    a.name


description : FrontendGroup -> Description
description (FrontendGroup a) =
    a.description


visibility : FrontendGroup -> GroupVisibility
visibility (FrontendGroup a) =
    a.visibility


{-| pastEvents and futureEvents are sorted so the head element is the event closest to the currentTime
-}
events : Time.Posix -> FrontendGroup -> { pastEvents : List Event, futureEvents : List Event }
events currentTime (FrontendGroup a) =
    a.events
        |> List.partition
            (\event ->
                Duration.from currentTime event.endTime |> Quantity.lessThanZero
            )
        |> (\( past, future ) -> { pastEvents = List.reverse past, futureEvents = future })
