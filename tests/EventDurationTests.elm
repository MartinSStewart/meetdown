module EventDurationTests exposing (..)

import EventDuration
import Expect
import Test exposing (..)
import Unsafe


tests =
    describe "Event duration tests"
        [ test "toString" <|
            \_ ->
                EventDuration.toString (Unsafe.eventDuration (5 * 60))
                    |> Expect.equal "5\u{00A0}hours"
        ]
