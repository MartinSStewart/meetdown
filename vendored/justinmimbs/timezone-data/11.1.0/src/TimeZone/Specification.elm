module TimeZone.Specification exposing (Clock(..), DateTime, DayOfMonth(..), Rule, Zone, ZoneRules(..), ZoneState, toOffsets)

import RataDie exposing (RataDie)
import Time exposing (Month(..), Weekday)



-- Represent data from the source files of the TZ database.


type alias Year =
    Int


type alias Minutes =
    Int


type DayOfMonth
    = Day Int
    | Next Weekday Int
    | Prev Weekday Int
    | Last Weekday


type Clock
    = Universal
    | Standard
    | WallClock


type alias Rule =
    { from : Year
    , to : Year

    -- transition time
    , month : Month
    , day : DayOfMonth
    , time : Minutes
    , clock : Clock

    -- to state
    , save : Minutes -- add to Standard time
    }


type ZoneRules
    = Save Minutes
    | Rules (List Rule)


type alias ZoneState =
    { standardOffset : Minutes
    , zoneRules : ZoneRules
    }


type alias DateTime =
    { year : Year
    , month : Month
    , day : Int
    , time : Minutes
    , clock : Clock
    }


type alias Zone =
    { history : List ( ZoneState, DateTime )
    , current : ZoneState
    }



-- Convert a zone specification into a list of offset changes.


type alias Change =
    { start : Int
    , offset : Minutes
    }


type alias Offset =
    { standard : Minutes
    , save : Minutes
    }


toOffsets : Int -> Int -> Zone -> ( List Change, Minutes )
toOffsets minYear maxYear zone =
    let
        initialState : ZoneState
        initialState =
            case zone.history of
                ( earliest, _ ) :: _ ->
                    earliest

                [] ->
                    zone.current

        initialOffset : Offset
        initialOffset =
            { standard =
                initialState.standardOffset
            , save =
                case initialState.zoneRules of
                    Save save ->
                        save

                    _ ->
                        0
            }

        ascendingChanges : List Change
        ascendingChanges =
            zone
                |> zoneToRanges
                    (DateTime minYear Jan 1 0 Universal)
                    (DateTime (maxYear + 1) Jan 1 0 Universal)
                |> List.foldl
                    (\( start, state, until ) ( prevOffset, prevChanges ) ->
                        let
                            ( nextChanges, nextOffset ) =
                                stateToOffsetChanges prevOffset start until state
                        in
                        ( nextOffset, prevChanges ++ nextChanges )
                    )
                    ( initialOffset, [] )
                |> Tuple.second
                |> stripDuplicatesByHelp .offset (initialOffset.standard + initialOffset.save) []

        ( initial, ascending ) =
            dropChangesBeforeEpoch ( initialOffset.standard + initialOffset.save, ascendingChanges )
    in
    ( List.reverse ascending
    , initial
    )


dropChangesBeforeEpoch : ( Minutes, List Change ) -> ( Minutes, List Change )
dropChangesBeforeEpoch ( initial, changes ) =
    case changes of
        change :: rest ->
            if change.start <= 0 then
                dropChangesBeforeEpoch ( change.offset, rest )

            else
                ( initial, changes )

        [] ->
            ( initial, [] )


zoneToRanges : DateTime -> DateTime -> Zone -> List ( DateTime, ZoneState, DateTime )
zoneToRanges zoneStart zoneUntil zone =
    let
        ( currentStart, historyRanges ) =
            List.foldl
                (\( state, nextStart ) ( start, ranges ) ->
                    ( nextStart
                    , ( start, state, nextStart ) :: ranges
                    )
                )
                ( zoneStart, [] )
                zone.history
    in
    ( currentStart, zone.current, zoneUntil ) :: historyRanges |> List.reverse


stateToOffsetChanges : Offset -> DateTime -> DateTime -> ZoneState -> ( List Change, Offset )
stateToOffsetChanges previousOffset start until { standardOffset, zoneRules } =
    case zoneRules of
        Save save ->
            ( [ { start = utcMinutesFromDateTime previousOffset start
                , offset = standardOffset + save
                }
              ]
            , { standard = standardOffset, save = save }
            )

        Rules rules ->
            rulesToOffsetChanges previousOffset start until standardOffset rules


rulesToOffsetChanges : Offset -> DateTime -> DateTime -> Minutes -> List Rule -> ( List Change, Offset )
rulesToOffsetChanges previousOffset start until standardOffset rules =
    let
        transitions : List { start : Int, clock : Clock, save : Minutes }
        transitions =
            List.range (start.year - 1) until.year
                |> List.concatMap
                    (\year ->
                        rules
                            |> List.filter
                                (\rule -> rule.from <= year && year <= rule.to)
                            |> List.map
                                (\rule ->
                                    { start =
                                        -- date
                                        minutesFromRataDie
                                            (case rule.day of
                                                Day day ->
                                                    RataDie.dayOfMonth year rule.month day

                                                Next weekday after ->
                                                    RataDie.dayOfMonth year rule.month after
                                                        |> RataDie.ceilingWeekday weekday

                                                Prev weekday before ->
                                                    RataDie.dayOfMonth year rule.month before
                                                        |> RataDie.floorWeekday weekday

                                                Last weekday ->
                                                    RataDie.lastOfMonth year rule.month
                                                        |> RataDie.floorWeekday weekday
                                            )
                                            -- time
                                            + rule.time
                                    , clock =
                                        rule.clock
                                    , save =
                                        rule.save
                                    }
                                )
                            |> List.sortBy .start
                    )

        initialOffset =
            { standard = standardOffset, save = 0 }

        initialChange =
            { start = utcMinutesFromDateTime previousOffset start
            , offset = standardOffset
            }

        ( nextOffset, descendingChanges ) =
            transitions
                |> List.foldl
                    (\transition ( currentOffset, changes ) ->
                        let
                            newOffset =
                                { standard = standardOffset, save = transition.save }
                        in
                        if transition.start + utcAdjustment transition.clock previousOffset <= initialChange.start then
                            let
                                updatedInitialChange =
                                    { start = initialChange.start
                                    , offset = standardOffset + transition.save
                                    }
                            in
                            ( newOffset, [ updatedInitialChange ] )

                        else if transition.start + utcAdjustment transition.clock currentOffset < utcMinutesFromDateTime currentOffset until then
                            let
                                change =
                                    { start = transition.start + utcAdjustment transition.clock currentOffset
                                    , offset = standardOffset + transition.save
                                    }
                            in
                            ( newOffset, change :: changes )

                        else
                            ( currentOffset, changes )
                    )
                    ( initialOffset, [ initialChange ] )
    in
    ( List.reverse descendingChanges, nextOffset )



-- time helpers


utcAdjustment : Clock -> Offset -> Int
utcAdjustment clock { standard, save } =
    case clock of
        Universal ->
            0

        Standard ->
            0 - standard

        WallClock ->
            0 - (standard + save)


utcMinutesFromDateTime : Offset -> DateTime -> Int
utcMinutesFromDateTime offset datetime =
    minutesFromDateTime datetime + utcAdjustment datetime.clock offset


minutesFromDateTime : DateTime -> Int
minutesFromDateTime { year, month, day, time } =
    minutesFromRataDie (RataDie.dayOfMonth year month day) + time


minutesFromRataDie : RataDie -> Int
minutesFromRataDie rd =
    (rd - 719163) * 1440



-- List


stripDuplicatesBy : (a -> b) -> List a -> List a
stripDuplicatesBy f list =
    case list of
        [] ->
            list

        x :: xs ->
            stripDuplicatesByHelp f (f x) [ x ] xs


stripDuplicatesByHelp : (a -> b) -> b -> List a -> List a -> List a
stripDuplicatesByHelp f a rev list =
    case list of
        [] ->
            List.reverse rev

        x :: xs ->
            let
                b =
                    f x

                rev_ =
                    if a /= b then
                        x :: rev

                    else
                        rev
            in
            stripDuplicatesByHelp f b rev_ xs
