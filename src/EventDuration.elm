module EventDuration exposing (Error(..), EventDuration, errorToString, fromMinutes, maxLength, toDuration, toMinutes)

import Duration exposing (Duration)


type EventDuration
    = EventDuration Int


type Error
    = EventDurationNotGreaterThan0
    | EventDurationTooLong


errorToString : Error -> String
errorToString error =
    case error of
        EventDurationNotGreaterThan0 ->
            "Value must be greater than 0"

        EventDurationTooLong ->
            "The event can't be more than " ++ String.fromInt (maxLength // 60) ++ " hours long"


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
        Ok (EventDuration minutes)


toMinutes : EventDuration -> Int
toMinutes (EventDuration minutes) =
    minutes


toDuration : EventDuration -> Duration
toDuration (EventDuration minutes) =
    Duration.minutes (toFloat minutes)
