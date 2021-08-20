module Effect.Process exposing (sleep)

{-|


# Processes

@docs sleep

-}

import Duration exposing (Duration)
import Effect.Internal
import Effect.Task exposing (Task)


{-| Block progress on the current process for the given number of milliseconds.
The JavaScript equivalent of this is [`setTimeout`][setTimeout] which lets you
delay work until later.

[setTimeout]: https://developer.mozilla.org/en-US/docs/Web/API/WindowTimers/setTimeout

-}
sleep : Duration -> Task restriction x ()
sleep duration =
    Effect.Internal.SleepTask duration Effect.Internal.Succeed
