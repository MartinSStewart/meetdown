# timezone-data

This Elm package contains time zone data from the [IANA Time Zone Database][tzdb] for using with [`elm/time`][elmtime].

The `elm/time` library provides a `Posix` type for representing an instant in time. Extracting human-readable parts from a `Posix` time requires a `Time.Zone`. This library provides `Time.Zone` values for all named zones in the database, covering changes between 1970 and 2037.


## Installation

```sh
elm install justinmimbs/timezone-data
```


## Examples

### Get the local time zone

The `TimeZone.getZone` task gets the client's local `Time.Zone` along with its zone name.

```elm
import Time
import TimeZone

getZone : Task TimeZone.Error ( String, Time.Zone )
getZone =
    TimeZone.getZone
```

See [this page][getzone] for a full example.

### Get a specific time zone

Each zone is stored as a function, waiting to be evaluated to a `Time.Zone`.

```elm
import Time
import TimeZone exposing (america__new_york)


-- unevaluated

lazyZone : () -> Time.Zone
lazyZone =
    america__new_york


-- evaluated

zone : Time.Zone
zone =
    america__new_york ()
```

Once evaluated, you should store the `Time.Zone` values you need in your model
so that they don't need to be evaluated again.


## Alternatives

Using this library to include all time zones in your compiled asset would increase its minified and gzipped size by about 18 KB. For a more lightweight approach to getting time zones into Elm, you may consider [fetching only the data you need at runtime][tzif]. And if your use case is taking UTC timestamps and displaying them nicely formatted in the client's local time, then you may look into custom elements, like Github's [`time-elements`][time-elements].


[tzdb]: https://www.iana.org/time-zones
[elmtime]: https://package.elm-lang.org/packages/elm/time/latest/
[getzone]: https://github.com/justinmimbs/timezone-data/blob/master/examples/GetZone.elm
[tzif]: https://package.elm-lang.org/packages/justinmimbs/tzif/latest/
[time-elements]: https://github.com/github/time-elements
