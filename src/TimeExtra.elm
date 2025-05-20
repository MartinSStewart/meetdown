module TimeExtra exposing (..)

import Round
import Time


removeTrailing0s : Int -> Float -> String
removeTrailing0s decimalPoints value =
    case Round.round decimalPoints value |> String.split "." of
        [ nonDecimal, decimal ] ->
            if decimalPoints > 0 then
                nonDecimal
                    ++ "."
                    ++ (String.foldr
                            (\char ( text, reachedNonZero ) ->
                                if reachedNonZero || char /= '0' then
                                    ( text, True )

                                else
                                    ( String.dropRight 1 text, False )
                            )
                            ( decimal, False )
                            decimal
                            |> Tuple.first
                       )
                    |> dropSuffix "."

            else
                nonDecimal

        [ nonDecimal ] ->
            nonDecimal

        _ ->
            "0"


dropSuffix : String -> String -> String
dropSuffix suffix string =
    if String.endsWith suffix string then
        String.dropRight (String.length suffix) string

    else
        string


{-| Convert a POSIX time (in ms) to UTC ICS datetime string (yyyyMMddTHHmmssZ)
-}
toUtcIcsString : Time.Zone -> Int -> String
toUtcIcsString _ posixMs =
    let
        posix =
            Time.millisToPosix posixMs

        year =
            Time.toYear Time.utc posix |> String.fromInt

        month =
            Time.toMonth Time.utc posix
                |> (\m ->
                        let
                            n =
                                case m of
                                    Time.Jan ->
                                        1

                                    Time.Feb ->
                                        2

                                    Time.Mar ->
                                        3

                                    Time.Apr ->
                                        4

                                    Time.May ->
                                        5

                                    Time.Jun ->
                                        6

                                    Time.Jul ->
                                        7

                                    Time.Aug ->
                                        8

                                    Time.Sep ->
                                        9

                                    Time.Oct ->
                                        10

                                    Time.Nov ->
                                        11

                                    Time.Dec ->
                                        12
                        in
                        if n < 10 then
                            "0" ++ String.fromInt n

                        else
                            String.fromInt n
                   )

        day =
            Time.toDay Time.utc posix
                |> (\d ->
                        if d < 10 then
                            "0" ++ String.fromInt d

                        else
                            String.fromInt d
                   )

        hour =
            Time.toHour Time.utc posix
                |> (\h ->
                        if h < 10 then
                            "0" ++ String.fromInt h

                        else
                            String.fromInt h
                   )

        minute =
            Time.toMinute Time.utc posix
                |> (\m ->
                        if m < 10 then
                            "0" ++ String.fromInt m

                        else
                            String.fromInt m
                   )

        second =
            Time.toSecond Time.utc posix
                |> (\s ->
                        if s < 10 then
                            "0" ++ String.fromInt s

                        else
                            String.fromInt s
                   )
    in
    year ++ month ++ day ++ "T" ++ hour ++ minute ++ second ++ "Z"
