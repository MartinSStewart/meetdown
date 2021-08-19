module Effect.Process exposing
    ( sleep
    , Task
    )

{-|


# Processes

@docs sleep

-}

import Duration exposing (Duration)
import Effect.Internal


type alias Task restriction x a =
    Effect.Internal.Task restriction x a


{-| Block progress on the current process for the given number of milliseconds.
The JavaScript equivalent of this is [`setTimeout`][setTimeout] which lets you
delay work until later.

[setTimeout]: https://developer.mozilla.org/en-US/docs/Web/API/WindowTimers/setTimeout

-}
sleep : Duration -> Task restriction x ()
sleep duration =
    Effect.Internal.SleepTask duration Effect.Internal.Succeed
