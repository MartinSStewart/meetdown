module RataDie
    exposing
        ( RataDie
        , ceilingWeekday
        , dayOfMonth
        , floorWeekday
        , lastOfMonth
        )

import Time exposing (Month(..), Weekday(..))


type alias RataDie =
    Int



-- create


dayOfMonth : Int -> Month -> Int -> RataDie
dayOfMonth y m d =
    daysBeforeYear y + daysBeforeMonth y m + d


lastOfMonth : Int -> Month -> RataDie
lastOfMonth y m =
    daysBeforeYear y + daysBeforeMonth y m + daysInMonth y m



-- extract


weekdayNumber : RataDie -> Int
weekdayNumber rd =
    case rd |> modBy 7 of
        0 ->
            7

        n ->
            n



-- floor


floorWeekday : Weekday -> RataDie -> RataDie
floorWeekday weekday rd =
    let
        daysSincePreviousWeekday =
            (weekdayNumber rd + 7 - weekdayToNumber weekday) |> modBy 7
    in
    rd - daysSincePreviousWeekday



-- ceiling


ceilingWeekday : Weekday -> RataDie -> RataDie
ceilingWeekday weekday rd =
    let
        floored =
            floorWeekday weekday rd
    in
    if rd == floored then
        rd

    else
        floored + 7



-- calculations


isLeapYear : Int -> Bool
isLeapYear y =
    modBy 4 y == 0 && modBy 100 y /= 0 || modBy 400 y == 0


daysBeforeYear : Int -> Int
daysBeforeYear y1 =
    let
        y =
            y1 - 1

        leapYears =
            (y // 4) - (y // 100) + (y // 400)
    in
    365 * y + leapYears



-- lookups


daysInMonth : Int -> Month -> Int
daysInMonth y m =
    case m of
        Jan ->
            31

        Feb ->
            if isLeapYear y then
                29

            else
                28

        Mar ->
            31

        Apr ->
            30

        May ->
            31

        Jun ->
            30

        Jul ->
            31

        Aug ->
            31

        Sep ->
            30

        Oct ->
            31

        Nov ->
            30

        Dec ->
            31


daysBeforeMonth : Int -> Month -> Int
daysBeforeMonth y m =
    let
        leapDays =
            if isLeapYear y then
                1

            else
                0
    in
    case m of
        Jan ->
            0

        Feb ->
            31

        Mar ->
            59 + leapDays

        Apr ->
            90 + leapDays

        May ->
            120 + leapDays

        Jun ->
            151 + leapDays

        Jul ->
            181 + leapDays

        Aug ->
            212 + leapDays

        Sep ->
            243 + leapDays

        Oct ->
            273 + leapDays

        Nov ->
            304 + leapDays

        Dec ->
            334 + leapDays


weekdayToNumber : Weekday -> Int
weekdayToNumber wd =
    case wd of
        Mon ->
            1

        Tue ->
            2

        Wed ->
            3

        Thu ->
            4

        Fri ->
            5

        Sat ->
            6

        Sun ->
            7
