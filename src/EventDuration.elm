module EventDuration exposing (Error(..), EventDuration(..), errorToString, fromMinutes, toDuration, toMinutes, toString)

import Duration exposing (Duration)
import TimeExtra
import UserConfig exposing (Texts)


type EventDuration
    = EventDuration Int


type Error
    = EventDurationNotGreaterThan0
    | EventDurationTooLong


errorToString : Texts -> Error -> String
errorToString texts error =
    case error of
        EventDurationNotGreaterThan0 ->
            texts.valueMustBeGreaterThan0

        EventDurationTooLong ->
            texts.eventCantBeMoreThan ++ String.fromInt (maxLength // 60) ++ texts.hoursLong


maxLength : number
maxLength =
    60 * 24 * 7


fromMinutes : Int -> Result Error EventDuration
fromMinutes minutes =
    if minutes <= 0 then
        Err EventDurationNotGreaterThan0

    else if minutes > maxLength then
        Err EventDurationTooLong

    else
        Ok <| EventDuration minutes


toMinutes : EventDuration -> Int
toMinutes (EventDuration minutes) =
    minutes


toDuration : EventDuration -> Duration
toDuration (EventDuration minutes) =
    Duration.minutes <| toFloat minutes


toString : Texts -> EventDuration -> String
toString texts eventDuration =
    let
        minutes =
            toMinutes eventDuration

        hours =
            toFloat minutes / 60
    in
    if minutes >= 60 then
        TimeExtra.removeTrailing0s 2 hours
            |> texts.numberOfHours

    else
        String.fromInt minutes
            |> texts.numberOfMinutes
