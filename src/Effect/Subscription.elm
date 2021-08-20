module Effect.Subscription exposing
    ( none, batch
    , map
    , Subscription, fromJs
    )

{-|

> **Note:** Elm has **managed effects**, meaning that things like HTTP
> requests or writing to disk are all treated as _data_ in Elm. When this
> data is given to the Elm runtime system, it can do some “query optimization”
> before actually performing the effect. Perhaps unexpectedly, this managed
> effects idea is the heart of why Elm is so nice for testing, reuse,
> reproducibility, etc.
>
> Elm has two kinds of managed effects: commands and subscriptions.


# Subscriptions

@docs Sub, none, batch


# Fancy Stuff

@docs map

-}

import Effect.Command exposing (FrontendOnly)
import Effect.Internal
import Json.Decode


{-| A subscription is a way of telling Elm, “Hey, let me know if anything
interesting happens over there!” So if you want to listen for messages on a web
socket, you would tell Elm to create a subscription. If you want to get clock
ticks, you would tell Elm to subscribe to that. The cool thing here is that
this means _Elm_ manages all the details of subscriptions instead of _you_.
So if a web socket goes down, _you_ do not need to manually reconnect with an
exponential backoff strategy, _Elm_ does this all for you behind the scenes!

Every `Sub` specifies (1) which effects you need access to and (2) the type of
messages that will come back into your application.

**Note:** Do not worry if this seems confusing at first! As with every Elm user
ever, subscriptions will make more sense as you work through [the Elm Architecture
Tutorial](https://guide.elm-lang.org/architecture/) and see how they fit
into a real application!

-}
type alias Subscription restriction msg =
    Effect.Internal.Subscription restriction msg


{-| When you need to subscribe to multiple things, you can create a `batch` of
subscriptions.

**Note:** `Sub.none` and `Sub.batch [ Sub.none, Sub.none ]` and
`Sub.batch []` all do the same thing.

-}
batch : List (Subscription restriction msg) -> Subscription restriction msg
batch =
    Effect.Internal.SubBatch


{-| Tell the runtime that there are no subscriptions.
-}
none : Subscription restriction msg
none =
    Effect.Internal.SubNone


{-| -}
fromJs : String -> ((Json.Decode.Value -> msg) -> Sub msg) -> (Json.Decode.Value -> msg) -> Subscription FrontendOnly msg
fromJs portName portFunction msg =
    Effect.Internal.SubPort portName (portFunction msg) msg


{-| Transform the messages produced by a subscription.
Very similar to [`Html.map`](/packages/elm/html/latest/Html#map).

This is very rarely useful in well-structured Elm code, so definitely read the
section on [structure] in the guide before reaching for this!

[structure]: https://guide.elm-lang.org/webapps/structure.html

-}
map : (a -> b) -> Subscription restriction a -> Subscription restriction b
map mapFunc subscription =
    case subscription of
        Effect.Internal.SubBatch subscriptions ->
            List.map (map mapFunc) subscriptions |> Effect.Internal.SubBatch

        Effect.Internal.TimeEvery duration msg ->
            Effect.Internal.TimeEvery duration (msg >> mapFunc)

        Effect.Internal.OnAnimationFrame msg ->
            Effect.Internal.OnAnimationFrame (msg >> mapFunc)

        Effect.Internal.OnAnimationFrameDelta msg ->
            Effect.Internal.OnAnimationFrameDelta (msg >> mapFunc)

        Effect.Internal.OnKeyPress decoder ->
            Effect.Internal.OnKeyPress (Json.Decode.map mapFunc decoder)

        Effect.Internal.OnKeyDown decoder ->
            Effect.Internal.OnKeyPress (Json.Decode.map mapFunc decoder)

        Effect.Internal.OnKeyUp decoder ->
            Effect.Internal.OnKeyUp (Json.Decode.map mapFunc decoder)

        Effect.Internal.OnClick decoder ->
            Effect.Internal.OnClick (Json.Decode.map mapFunc decoder)

        Effect.Internal.OnMouseMove decoder ->
            Effect.Internal.OnMouseMove (Json.Decode.map mapFunc decoder)

        Effect.Internal.OnMouseDown decoder ->
            Effect.Internal.OnMouseDown (Json.Decode.map mapFunc decoder)

        Effect.Internal.OnMouseUp decoder ->
            Effect.Internal.OnMouseUp (Json.Decode.map mapFunc decoder)

        Effect.Internal.OnVisibilityChange msg ->
            Effect.Internal.OnVisibilityChange (msg >> mapFunc)

        Effect.Internal.OnResize msg ->
            Effect.Internal.OnResize (\w h -> msg w h |> mapFunc)

        Effect.Internal.SubPort portName sub msg ->
            Effect.Internal.SubPort portName (Sub.map mapFunc sub) (msg >> mapFunc)

        Effect.Internal.SubNone ->
            Effect.Internal.SubNone

        Effect.Internal.OnConnect msg ->
            Effect.Internal.OnConnect (\sessionId clientId -> msg sessionId clientId |> mapFunc)

        Effect.Internal.OnDisconnect msg ->
            Effect.Internal.OnDisconnect (\sessionId clientId -> msg sessionId clientId |> mapFunc)
