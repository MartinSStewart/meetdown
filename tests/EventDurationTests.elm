module EventDurationTests exposing (..)

import Effect.Test as TF
import EventDuration
import Expect
import Test exposing (..)
import Tests
import Unsafe
import UserConfig


tests =
    describe "Event duration tests"
        [ test "toString" <|
            \_ ->
                EventDuration.toString UserConfig.englishTexts (Unsafe.eventDuration (5 * 60))
                    |> Expect.equal "5\u{00A0}hours"
        ]


appTests =
    describe "App tests" (List.map TF.toTest Tests.tests)
