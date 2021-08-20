module Effect.Command exposing
    ( none, batch
    , map
    , BackendOnly, Command, FrontendOnly, PortToJs, sendToJs
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


# Commands

@docs Cmd, none, batch


# Fancy Stuff

@docs map

-}

import Effect.Internal exposing (Command(..), NavigationKey, Subscription(..))
import Json.Encode


type alias FrontendOnly =
    Effect.Internal.FrontendOnly


type alias BackendOnly =
    Effect.Internal.BackendOnly


{-| A command is a way of telling Elm, “Hey, I want you to do this thing!”
So if you want to send an HTTP request, you would need to command Elm to do it.
Or if you wanted to ask for geolocation, you would need to command Elm to go
get it.

Every `Cmd` specifies (1) which effects you need access to and (2) the type of
messages that will come back into your application.

**Note:** Do not worry if this seems confusing at first! As with every Elm user
ever, commands will make more sense as you work through [the Elm Architecture
Tutorial](https://guide.elm-lang.org/architecture/) and see how they
fit into a real application!

-}
type alias Command restriction toMsg msg =
    Effect.Internal.Command restriction toMsg msg


{-| When you need the runtime system to perform a couple commands, you
can batch them together. Each is handed to the runtime at the same time,
and since each can perform arbitrary operations in the world, there are
no ordering guarantees about the results.

**Note:** `Cmd.none` and `Cmd.batch [ Cmd.none, Cmd.none ]` and `Cmd.batch []`
all do the same thing.

-}
batch : List (Command restriction toMsg msg) -> Command restriction toMsg msg
batch =
    Batch


{-| Tell the runtime that there are no commands.
-}
none : Command restriction toMsg msg
none =
    None


{-| -}
sendToJs : String -> (Json.Encode.Value -> Cmd msg) -> Json.Encode.Value -> Command FrontendOnly toMsg msg
sendToJs =
    Port


type alias PortToJs =
    { portName : String, value : Json.Encode.Value }


{-| Transform the messages produced by a command.
Very similar to [`Html.map`](/packages/elm/html/latest/Html#map).

This is very rarely useful in well-structured Elm code, so definitely read the
section on [structure] in the guide before reaching for this!

[structure]: https://guide.elm-lang.org/webapps/structure.html

-}
map :
    (toBackendA -> toBackendB)
    -> (frontendMsgA -> frontendMsgB)
    -> Command restriction toBackendA frontendMsgA
    -> Command restriction toBackendB frontendMsgB
map mapToMsg mapMsg frontendEffect =
    case frontendEffect of
        Batch frontendEffects ->
            List.map (map mapToMsg mapMsg) frontendEffects |> Batch

        None ->
            None

        SendToBackend toMsg ->
            mapToMsg toMsg |> SendToBackend

        NavigationPushUrl navigationKey url ->
            NavigationPushUrl navigationKey url

        NavigationReplaceUrl navigationKey url ->
            NavigationReplaceUrl navigationKey url

        NavigationLoad url ->
            NavigationLoad url

        NavigationBack navigationKey int ->
            NavigationBack navigationKey int

        NavigationForward navigationKey int ->
            NavigationForward navigationKey int

        NavigationReload ->
            NavigationReload

        NavigationReloadAndSkipCache ->
            NavigationReloadAndSkipCache

        Task simulatedTask ->
            Effect.Internal.taskMap mapMsg simulatedTask
                |> Effect.Internal.taskMapError mapMsg
                |> Task

        Port portName function value ->
            Port portName (function >> Cmd.map mapMsg) value

        SendToFrontend clientId toMsg ->
            SendToFrontend clientId (mapToMsg toMsg)

        FileDownloadUrl record ->
            FileDownloadUrl record

        FileDownloadString record ->
            FileDownloadString record

        FileDownloadBytes record ->
            FileDownloadBytes record

        FileSelectFile strings function ->
            FileSelectFile strings (function >> mapMsg)

        FileSelectFiles strings function ->
            FileSelectFiles strings (\file restOfFiles -> function file restOfFiles |> mapMsg)

        Broadcast toMsg ->
            Broadcast (mapToMsg toMsg)
