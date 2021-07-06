module TimeExtraTests exposing (..)

import Duration
import Expect
import Test exposing (..)
import Time
import TimeExtra


hour =
    60 * 60 * 1000


tests =
    describe "Time extra tests"
        [ test "5 hours" <|
            \_ ->
                TimeExtra.diffToString (Time.millisToPosix 0) (Time.millisToPosix (5 * hour))
                    |> Expect.equal "5\u{00A0}hours"
        , test "4.9 hours" <|
            \_ ->
                Duration.hours 4.9
                    |> Duration.inMilliseconds
                    |> round
                    |> Time.millisToPosix
                    |> TimeExtra.diffToString (Time.millisToPosix 0)
                    |> Expect.equal "4.9\u{00A0}hours"
        , test "5 hours ago" <|
            \_ ->
                TimeExtra.diffToString (Time.millisToPosix (5 * hour)) (Time.millisToPosix 0)
                    |> Expect.equal "5\u{00A0}hours ago"
        , test "yesterday" <|
            \_ ->
                TimeExtra.diffToString (Time.millisToPosix (24 * hour)) (Time.millisToPosix 0)
                    |> Expect.equal "yesterday"
        , test "1 day" <|
            \_ ->
                TimeExtra.diffToString (Time.millisToPosix 0) (Time.millisToPosix (24 * hour))
                    |> Expect.equal "1\u{00A0}day"
        , test "2 days" <|
            \_ ->
                TimeExtra.diffToString (Time.millisToPosix 0) (Time.millisToPosix (36 * hour))
                    |> Expect.equal "2\u{00A0}days"
        , test "2 days ago" <|
            \_ ->
                TimeExtra.diffToString (Time.millisToPosix (36 * hour)) (Time.millisToPosix 0)
                    |> Expect.equal "2\u{00A0}days ago"
        ]
