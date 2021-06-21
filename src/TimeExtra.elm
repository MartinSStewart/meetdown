module TimeExtra exposing (..)

import Duration exposing (Duration)
import Quantity
import Time


diffToString : Time.Posix -> Time.Posix -> String
diffToString start end =
    let
        difference : Duration
        difference =
            Duration.from start end |> Quantity.abs

        months =
            Duration.inDays difference / 30 |> floor

        weeks =
            Duration.inWeeks difference |> floor

        days =
            Duration.inDays difference |> floor

        hours =
            Duration.inHours difference |> floor

        minutes =
            Duration.inMinutes difference |> round

        suffix =
            if Time.posixToMillis start <= Time.posixToMillis end then
                ""

            else
                " ago"
    in
    if months >= 2 then
        String.fromInt months ++ "\u{00A0}months" ++ suffix

    else if weeks >= 2 then
        String.fromInt weeks ++ "\u{00A0}weeks" ++ suffix

    else if days > 1 then
        String.fromInt days ++ "\u{00A0}days" ++ suffix

    else if days == 1 then
        if Time.posixToMillis start <= Time.posixToMillis end then
            "tomorrow"

        else
            "yesterday"

    else if hours > 6 then
        String.fromInt hours ++ "\u{00A0}hours" ++ suffix

    else if Duration.inHours difference >= 1.2 then
        (removeTrailing0s (Duration.inHours difference) |> String.left 3) ++ "\u{00A0}hours" ++ suffix

    else if minutes > 1 then
        String.fromInt minutes ++ "\u{00A0}minutes" ++ suffix

    else if minutes == 1 then
        "1\u{00A0}minute" ++ suffix

    else
        "now"


removeTrailing0s : Float -> String
removeTrailing0s =
    String.fromFloat
        >> String.foldl
            (\char newText ->
                if newText == "" && (char == '0' || char == '.') then
                    newText

                else
                    newText ++ String.fromChar char
            )
            ""
