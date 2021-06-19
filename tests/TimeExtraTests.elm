module TimeExtraTests exposing (..)

import Duration
import Expect
import Test exposing (..)
import Time
import TimeExtra


tests =
    describe "Time extra tests"
        [ test "5 hours" <|
            \_ ->
                TimeExtra.diffToString (Time.millisToPosix 0) (Time.millisToPosix (5 * 60 * 60 * 1000))
                    |> Expect.equal "5 hours"
        , test "4.9 hours" <|
            \_ ->
                Duration.hours 4.9
                    |> Duration.inMilliseconds
                    |> round
                    |> Time.millisToPosix
                    |> TimeExtra.diffToString (Time.millisToPosix 0)
                    |> Expect.equal "4.9 hours"
        , test "5 hours ago" <|
            \_ ->
                TimeExtra.diffToString (Time.millisToPosix (5 * 60 * 60 * 1000)) (Time.millisToPosix 0)
                    |> Expect.equal "5 hours ago"
        ]
