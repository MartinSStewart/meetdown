module Group exposing
    ( EditCancellationStatusError(..)
    , EditEventError(..)
    , EventId
    , Group
    , GroupVisibility(..)
    , JoinEventError(..)
    , PastOngoingOrFuture(..)
    , addEvent
    , createdAt
    , description
    , editCancellationStatus
    , editEvent
    , eventIdFromInt
    , eventIdToInt
    , events
    , getEvent
    , init
    , joinEvent
    , leaveEvent
    , name
    , ownerId
    , totalEvents
    , visibility
    , withDescription
    , withName
    , withVisibility
    )

import AssocList as Dict exposing (Dict)
import AssocSet as Set exposing (Set)
import Description exposing (Description)
import Duration
import Event exposing (CancellationStatus, Event)
import GroupName exposing (GroupName)
import Id exposing (Id, UserId)
import List.Extra as List
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
        , pendingReview : Bool
        }


type GroupVisibility
    = UnlistedGroup
    | PublicGroup


init : Id UserId -> GroupName -> Description -> GroupVisibility -> Time.Posix -> Group
init ownerId_ groupName description_ groupVisibility_ createdAt_ =
    Group
        { ownerId = ownerId_
        , name = groupName
        , description = description_
        , events = Dict.empty
        , visibility = groupVisibility_
        , eventCounter = 0
        , createdAt = createdAt_
        , pendingReview = True
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


withVisibility : GroupVisibility -> Group -> Group
withVisibility groupVisibility (Group a) =
    Group { a | visibility = groupVisibility }


type EventId
    = EventId Int


eventIdFromInt : Int -> EventId
eventIdFromInt =
    EventId


eventIdToInt : EventId -> Int
eventIdToInt (EventId a) =
    a


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


type PastOngoingOrFuture
    = IsPastEvent
    | IsOngoingEvent
    | IsFutureEvent


getEvent : Time.Posix -> EventId -> Group -> Maybe ( Event, PastOngoingOrFuture )
getEvent currentTime eventId group =
    let
        { pastEvents, ongoingEvent, futureEvents } =
            events currentTime group
    in
    case List.find (Tuple.first >> (==) eventId) futureEvents of
        Just ( _, futureEvent ) ->
            Just ( futureEvent, IsFutureEvent )

        Nothing ->
            case List.find (Tuple.first >> (==) eventId) pastEvents of
                Just ( _, pastEvent ) ->
                    Just ( pastEvent, IsPastEvent )

                Nothing ->
                    case ongoingEvent of
                        Just ( eventId_, event_ ) ->
                            if eventId == eventId_ then
                                Just ( event_, IsOngoingEvent )

                            else
                                Nothing

                        Nothing ->
                            Nothing


type EditEventError
    = EditEventStartsInThePast
    | EditEventOverlapsOtherEvents (Set EventId)
    | CantEditPastEvent
    | CantChangeStartTimeOfOngoingEvent
    | EditEventNotFound


type EditCancellationStatusError
    = CancellationStatusCantBeAfterEventStart
    | CantChangeCancellationStatusOfOngoingEvent
    | CantChangeCancellationStatusOfPastEvent
    | EditEventNotFound_


editCancellationStatus : Time.Posix -> EventId -> CancellationStatus -> Group -> Result EditCancellationStatusError Group
editCancellationStatus currentTime eventId cancellationStatus group =
    case getEvent currentTime eventId group of
        Just ( _, IsPastEvent ) ->
            Err CantChangeCancellationStatusOfPastEvent

        Just ( _, IsOngoingEvent ) ->
            Err CantChangeCancellationStatusOfOngoingEvent

        Just ( futureEvent, IsFutureEvent ) ->
            if Duration.from (Event.startTime futureEvent) currentTime |> Quantity.greaterThanZero then
                Err CancellationStatusCantBeAfterEventStart

            else
                editEventHelper
                    eventId
                    (Event.withCancellationStatus currentTime cancellationStatus futureEvent)
                    group
                    |> Ok

        Nothing ->
            Err EditEventNotFound_


editEvent : Time.Posix -> EventId -> (Event -> Event) -> Group -> Result EditEventError ( Event, Group )
editEvent currentTime eventId editEventFunc group =
    case getEvent currentTime eventId group of
        Just ( _, IsPastEvent ) ->
            Err CantEditPastEvent

        Just ( futureEvent, IsFutureEvent ) ->
            let
                edittedEvent =
                    editEventFunc futureEvent
            in
            if Duration.from currentTime (Event.startTime edittedEvent) |> Quantity.lessThanZero then
                Err EditEventStartsInThePast

            else
                case
                    allEvents group
                        |> Dict.remove eventId
                        |> Dict.toList
                        |> List.filter (Tuple.second >> Event.overlaps edittedEvent)
                of
                    head :: rest ->
                        List.map Tuple.first (head :: rest) |> Set.fromList |> EditEventOverlapsOtherEvents |> Err

                    [] ->
                        ( edittedEvent, editEventHelper eventId edittedEvent group ) |> Ok

        Just ( ongoingEvent, IsOngoingEvent ) ->
            let
                edittedEvent =
                    editEventFunc ongoingEvent
            in
            if Event.startTime edittedEvent == Event.startTime ongoingEvent then
                ( edittedEvent, editEventHelper eventId edittedEvent group ) |> Ok

            else
                Err CantChangeStartTimeOfOngoingEvent

        Nothing ->
            Err EditEventNotFound


editEventHelper : EventId -> Event -> Group -> Group
editEventHelper eventId event (Group group) =
    Group { group | events = Dict.insert eventId event group.events }


type JoinEventError
    = NoSpotsLeftInEvent
    | EventNotFound


joinEvent : Id UserId -> EventId -> Group -> Result JoinEventError Group
joinEvent userId eventId (Group group) =
    case Dict.get eventId group.events of
        Just event ->
            case Event.addAttendee userId event of
                Ok newEvent ->
                    Group { group | events = Dict.insert eventId newEvent group.events } |> Ok

                Err () ->
                    Err NoSpotsLeftInEvent

        Nothing ->
            Err EventNotFound


leaveEvent : Id UserId -> EventId -> Group -> Group
leaveEvent userId eventId (Group group) =
    Group { group | events = Dict.update eventId (Maybe.map (Event.removeAttendee userId)) group.events }


totalEvents : Group -> Int
totalEvents (Group a) =
    Dict.size a.events


allEvents : Group -> Dict EventId Event
allEvents (Group group) =
    group.events


{-| pastEvents and futureEvents are sorted so the head element is the event closest to the currentTime
-}
events :
    Time.Posix
    -> Group
    ->
        { pastEvents : List ( EventId, Event )
        , ongoingEvent : Maybe ( EventId, Event )
        , futureEvents : List ( EventId, Event )
        }
events currentTime (Group a) =
    Dict.toList a.events
        |> List.partition
            (\( _, event ) ->
                Duration.from currentTime (Event.startTime event) |> Quantity.lessThanZero
            )
        |> (\( past, future ) ->
                let
                    ( ongoingEvent, pastEvents ) =
                        case List.sortBy (Tuple.second >> Event.startTime >> Time.posixToMillis) past |> List.reverse of
                            head :: rest ->
                                if Event.isOngoing currentTime (Tuple.second head) then
                                    ( Just head, rest )

                                else
                                    ( Nothing, head :: rest )

                            [] ->
                                ( Nothing, [] )
                in
                { pastEvents = pastEvents
                , ongoingEvent = ongoingEvent
                , futureEvents = List.sortBy (Tuple.second >> Event.startTime >> Time.posixToMillis) future
                }
           )


createdAt : Group -> Time.Posix
createdAt (Group a) =
    a.createdAt
