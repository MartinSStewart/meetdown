module EventDuration exposing (Error(..), EventDuration, errorToString, fromMinutes, maxLength, minLength, toDuration, toMinutes)

import Duration exposing (Duration)


type EventDuration
    = EventDuration Int


type Error
    = EventDurationIsNegative
    | EventDurationTooShort
    | EventDurationTooLong


errorToString : Error -> String
errorToString error =
    case error of
        EventDurationIsNegative ->
            "Value can't be negative"

        EventDurationTooShort ->
            "The event must be at least " ++ String.fromInt minLength ++ " minutes long"

        EventDurationTooLong ->
            "The event can't be more than " ++ String.fromInt (maxLength // (24 * 60)) ++ " days long"


minLength : number
minLength =
    15


maxLength : number
maxLength =
    60 * 24 * 7


fromMinutes : Int -> Result Error EventDuration
fromMinutes minutes =
    if minutes < 0 then
        Err EventDurationIsNegative

    else if minutes < minLength then
        Err EventDurationTooShort

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
