module Group exposing (EventId, Group, GroupVisibility(..), addEvent, description, events, init, joinEvent, leaveEvent, name, ownerId, totalEvents, visibility, withDescription, withName)

import AssocList as Dict exposing (Dict)
import AssocSet as Set exposing (Set)
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
        , events : Dict EventId Event
        , visibility : GroupVisibility
        , eventCounter : Int
        , createdAt : Time.Posix
        }


type GroupVisibility
    = UnlistedGroup
    | PublicGroup


init : Id UserId -> GroupName -> Description -> GroupVisibility -> Time.Posix -> Group
init ownerId_ groupName description_ groupVisibility_ createdAt =
    Group
        { ownerId = ownerId_
        , name = groupName
        , description = description_
        , events = Dict.empty
        , visibility = groupVisibility_
        , eventCounter = 0
        , createdAt = createdAt
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


withName : GroupName -> Group -> Group
withName name_ (Group a) =
    Group { a | name = name_ }


withDescription : Description -> Group -> Group
withDescription description_ (Group a) =
    Group { a | description = description_ }


visibility : Group -> GroupVisibility
visibility (Group a) =
    a.visibility


type EventId
    = EventId Int


addEvent : Event -> Group -> Result (Set EventId) Group
addEvent event (Group a) =
    case Dict.toList a.events |> List.filter (Tuple.second >> Event.overlaps event) of
        head :: rest ->
            head :: rest |> List.map Tuple.first |> Set.fromList |> Err

        [] ->
            { a
                | events = Dict.insert (EventId a.eventCounter) event a.events
                , eventCounter = a.eventCounter + 1
            }
                |> Group
                |> Ok


joinEvent : Id UserId -> EventId -> Group -> Group
joinEvent userId eventId (Group group) =
    Group { group | events = Dict.update eventId (Maybe.map (Event.addAttendee userId)) group.events }


leaveEvent : Id UserId -> EventId -> Group -> Group
leaveEvent userId eventId (Group group) =
    Group { group | events = Dict.update eventId (Maybe.map (Event.removeAttendee userId)) group.events }


totalEvents : Group -> Int
totalEvents (Group a) =
    Dict.size a.events


{-| pastEvents and futureEvents are sorted so the head element is the event closest to the currentTime
-}
events : Time.Posix -> Group -> { pastEvents : List ( EventId, Event ), futureEvents : List ( EventId, Event ) }
events currentTime (Group a) =
    Dict.toList a.events
        |> List.partition
            (\( _, event ) ->
                Duration.from currentTime (Event.endTime event) |> Quantity.lessThanZero
            )
        |> (\( past, future ) -> { pastEvents = List.reverse past, futureEvents = future })
