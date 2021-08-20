module Effect.Task exposing
    ( Task, perform, attempt
    , andThen, succeed, fail, sequence
    , map, map2, map3, map4, map5
    , onError, mapError
    )

{-| Tasks make it easy to describe asynchronous operations that may fail, like
HTTP requests or writing to a database.


# Tasks

@docs Task, perform, attempt


# Chains

@docs andThen, succeed, fail, sequence


# Maps

@docs map, map2, map3, map4, map5


# Errors

@docs onError, mapError

-}

import Effect.Internal exposing (Command(..), HttpBody(..), Task(..))


{-| Here are some common tasks:

  - [`now : Task x Posix`][now]
  - [`focus : String -> Task Error ()`][focus]
  - [`sleep : Float -> Task x ()`][sleep]

[now]: /packages/elm/time/latest/Time#now
[focus]: /packages/elm/browser/latest/Browser-Dom#focus
[sleep]: /packages/elm/core/latest/Process#sleep

In each case we have a `Task` that will resolve successfully with an `a` value
or unsuccessfully with an `x` value. So `Browser.Dom.focus` we may fail with an
`Error` if the given ID does not exist. Whereas `Time.now` never fails so
I cannot be more specific than `x`. No such value will ever exist! Instead it
always succeeds with the current POSIX time.

More generally a task is a _description_ of what you need to do. Like a todo
list. Or like a grocery list. Or like GitHub issues. So saying "the task is
to tell me the current POSIX time" does not complete the task! You need
[`perform`](#perform) tasks or [`attempt`](#attempt) tasks.

-}
type alias Task restriction x a =
    Effect.Internal.Task restriction x a


{-| Like I was saying in the [`Task`](#Task) documentation, just having a
`Task` does not mean it is done. We must command Elm to `perform` the task:

    -- elm install elm/time


    import Task
    import Time

    type Msg
        = Click
        | Search String
        | NewTime Time.Posix

    getNewTime : Cmd Msg
    getNewTime =
        Task.perform NewTime Time.now

If you have worked through [`guide.elm-lang.org`][guide] (highly recommended!)
you will recognize `Cmd` from the section on The Elm Architecture. So we have
changed a task like "make delicious lasagna" into a command like "Hey Elm, make
delicious lasagna and give it to my `update` function as a `Msg` value."

[guide]: https://guide.elm-lang.org/

-}
perform : (a -> msg) -> Task restriction Never a -> Command restriction toMsg msg
perform f task =
    task
        |> map f
        |> mapError never
        |> Task


{-| This is very similar to [`perform`](#perform) except it can handle failures!
So we could _attempt_ to focus on a certain DOM node like this:

    -- elm install elm/browser


    import Browser.Dom
    import Task

    type Msg
        = Click
        | Search String
        | Focus (Result Browser.DomError ())

    focus : Cmd Msg
    focus =
        Task.attempt Focus (Browser.Dom.focus "my-app-search-box")

So the task is "focus on this DOM node" and we are turning it into the command
"Hey Elm, attempt to focus on this DOM node and give me a `Msg` about whether
you succeeded or failed."

**Note:** Definitely work through [`guide.elm-lang.org`][guide] to get a
feeling for how commands fit into The Elm Architecture.

[guide]: https://guide.elm-lang.org/

-}
attempt : (Result x a -> msg) -> Task restriction x a -> Command restriction toMsg msg
attempt f task =
    task
        |> map (Ok >> f)
        |> mapError (Err >> f)
        |> Task


{-| Chain together a task and a callback. The first task will run, and if it is
successful, you give the result to the callback resulting in another task. This
task then gets run. We could use this to make a task that resolves an hour from
now:

    -- elm install elm/time


    import Process
    import Time

    timeInOneHour : Task x Time.Posix
    timeInOneHour =
        Process.sleep (60 * 60 * 1000)
            |> andThen (\_ -> Time.now)

First the process sleeps for an hour **and then** it tells us what time it is.

-}
andThen : (a -> Task restriction x b) -> Task restriction x a -> Task restriction x b
andThen =
    Effect.Internal.andThen


{-| A task that succeeds immediately when run. It is usually used with
[`andThen`](#andThen). You can use it like `map` if you want:

    import Time


    -- elm install elm/time
    timeInMillis : Task x Int
    timeInMillis =
        Time.now
            |> andThen (\t -> succeed (Time.posixToMillis t))

-}
succeed : a -> Task restriction x a
succeed =
    Succeed


{-| A task that fails immediately when run. Like with `succeed`, this can be
used with `andThen` to check on the outcome of another task.

    type Error
        = NotFound

    notFound : Task Error a
    notFound =
        fail NotFound

-}
fail : x -> Task restriction x a
fail =
    Fail


{-| Transform a task. Maybe you want to use [`elm/time`][time] to figure
out what time it will be in one hour:

    import Task exposing (Task)
    import Time


    -- elm install elm/time
    timeInOneHour : Task x Time.Posix
    timeInOneHour =
        Task.map addAnHour Time.now

    addAnHour : Time.Posix -> Time.Posix
    addAnHour time =
        Time.millisToPosix (Time.posixToMillis time + 60 * 60 * 1000)

[time]: /packages/elm/time/latest/

-}
map : (a -> b) -> Task restriction x a -> Task restriction x b
map =
    Effect.Internal.taskMap


{-| Put the results of two tasks together. For example, if we wanted to know
the current month, we could use [`elm/time`][time] to ask:

    import Task exposing (Task)
    import Time


    -- elm install elm/time
    getMonth : Task x Int
    getMonth =
        Task.map2 Time.toMonth Time.here Time.now

**Note:** Say we were doing HTTP requests instead. `map2` does each task in
order, so it would try the first request and only continue after it succeeds.
If it fails, the whole thing fails!

[time]: /packages/elm/time/latest/

-}
map2 : (a -> b -> result) -> Task restriction x a -> Task restriction x b -> Task restriction x result
map2 func taskA taskB =
    taskA
        |> andThen
            (\a ->
                taskB
                    |> andThen (\b -> succeed (func a b))
            )


{-| -}
map3 : (a -> b -> c -> result) -> Task restriction x a -> Task restriction x b -> Task restriction x c -> Task restriction x result
map3 func taskA taskB taskC =
    taskA
        |> andThen
            (\a ->
                taskB
                    |> andThen
                        (\b ->
                            taskC
                                |> andThen (\c -> succeed (func a b c))
                        )
            )


{-| -}
map4 :
    (a -> b -> c -> d -> result)
    -> Task restriction x a
    -> Task restriction x b
    -> Task restriction x c
    -> Task restriction x d
    -> Task restriction x result
map4 func taskA taskB taskC taskD =
    taskA
        |> andThen
            (\a ->
                taskB
                    |> andThen
                        (\b ->
                            taskC
                                |> andThen
                                    (\c ->
                                        taskD
                                            |> andThen (\d -> succeed (func a b c d))
                                    )
                        )
            )


{-| -}
map5 :
    (a -> b -> c -> d -> e -> result)
    -> Task restriction x a
    -> Task restriction x b
    -> Task restriction x c
    -> Task restriction x d
    -> Task restriction x e
    -> Task restriction x result
map5 func taskA taskB taskC taskD taskE =
    taskA
        |> andThen
            (\a ->
                taskB
                    |> andThen
                        (\b ->
                            taskC
                                |> andThen
                                    (\c ->
                                        taskD
                                            |> andThen
                                                (\d ->
                                                    taskE
                                                        |> andThen (\e -> succeed (func a b c d e))
                                                )
                                    )
                        )
            )


{-| Transform the error value. This can be useful if you need a bunch of error
types to match up.

    type Error
        = Http Http.Error
        | WebGL WebGL.Error

    getResources : Task Error Resource
    getResources =
        sequence
            [ mapError Http serverTask
            , mapError WebGL textureTask
            ]

-}
mapError : (x -> y) -> Task restriction x a -> Task restriction y a
mapError =
    Effect.Internal.taskMapError


{-| Start with a list of tasks, and turn them into a single task that returns a
list. The tasks will be run in order one-by-one and if any task fails the whole
sequence fails.

    sequence [ succeed 1, succeed 2 ] == succeed [ 1, 2 ]

-}
sequence : List (Task restriction x a) -> Task restriction x (List a)
sequence tasks =
    List.foldr (map2 (::)) (succeed []) tasks


{-| Recover from a failure in a task. If the given task fails, we use the
callback to recover.

    fail "file not found"
      |> onError (\msg -> succeed 42)
      -- succeed 42

    succeed 9
      |> onError (\msg -> succeed 42)
      -- succeed 9

-}
onError : (x -> Task restriction y a) -> Task restriction x a -> Task restriction y a
onError f task =
    case task of
        Succeed a ->
            Succeed a

        Fail x ->
            f x

        HttpTask request ->
            HttpTask
                { method = request.method
                , url = request.url
                , body = request.body
                , headers = request.headers
                , onRequestComplete = request.onRequestComplete >> onError f
                , timeout = request.timeout
                }

        SleepTask delay onResult ->
            SleepTask delay (onResult >> onError f)

        TimeNow gotTime ->
            TimeNow (gotTime >> onError f)

        TimeHere gotTimeZone ->
            TimeHere (gotTimeZone >> onError f)

        TimeGetZoneName gotTimeZoneName ->
            TimeGetZoneName (gotTimeZoneName >> onError f)

        SetViewport x y function ->
            SetViewport x y (function >> onError f)

        GetViewport function ->
            GetViewport (function >> onError f)

        GetElement string function ->
            GetElement string (function >> onError f)

        Focus string function ->
            Focus string (function >> onError f)

        Blur string function ->
            Blur string (function >> onError f)

        GetViewportOf string function ->
            GetViewportOf string (function >> onError f)

        SetViewportOf string x y function ->
            SetViewportOf string x y (function >> onError f)

        FileToString file function ->
            FileToString file (function >> onError f)

        FileToBytes file function ->
            FileToBytes file (function >> onError f)

        FileToUrl file function ->
            FileToUrl file (function >> onError f)
