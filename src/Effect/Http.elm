module Effect.Http exposing
    ( Header, header
    , emptyBody, stringBody, jsonBody
    , Expect(..), expectString, expectJson, expectWhatever, Error(..)
    , expectStringResponse, Response(..)
    , task, Resolver, stringResolver
    , HttpBody
    )

{-| This module parallels [elm/http's `Http` module](https://package.elm-lang.org/packages/elm/http/2.0.0/Http).
_Pull requests are welcome to add any functions that are missing._

The functions here produce `BackendEffect`s instead of `Cmd`s, which are meant to be used
to help you implement the function to provide when using [`ProgramTest.withBackendEffects`](ProgramTest#withBackendEffects).


# Requests

@docs get, post, request


# Header

@docs Header, header


# Body

@docs Body, emptyBody, stringBody, jsonBody


# Expect

@docs Expect, expectString, expectJson, expectWhatever, Error


# Elaborate Expectations

@docs expectStringResponse, Response


# Tasks

@docs task, Resolver, stringResolver

-}

import Dict exposing (Dict)
import Duration exposing (Duration)
import Effect.Command exposing (Command)
import Effect.Internal exposing (HttpBody(..), Task(..))
import Effect.Task exposing (Task)
import Http
import Json.Decode exposing (Decoder)
import Json.Encode


{-| An HTTP header for configuring requests.
-}
type alias Header =
    ( String, String )


{-| Represents the body of a `Request`.
-}
type alias HttpBody =
    Effect.Internal.HttpBody


{-| Create a `GET` request.
-}
get :
    { url : String
    , expect : Expect msg
    }
    -> Command restriction toFrontend msg
get r =
    request
        { method = "GET"
        , headers = []
        , url = r.url
        , body = emptyBody
        , expect = r.expect
        , timeout = Nothing
        , tracker = Nothing
        }


{-| Create a `POST` request.
-}
post :
    { url : String
    , body : HttpBody
    , expect : Expect msg
    }
    -> Command restriction toFrontend msg
post r =
    request
        { method = "POST"
        , headers = []
        , url = r.url
        , body = r.body
        , expect = r.expect
        , timeout = Nothing
        , tracker = Nothing
        }


{-| Create a custom request.
-}
request :
    { method : String
    , headers : List Header
    , url : String
    , body : HttpBody
    , expect : Expect msg
    , timeout : Maybe Duration
    , tracker : Maybe String
    }
    -> Command restriction toFrontend msg
request r =
    let
        (Expect onResult) =
            r.expect
    in
    HttpTask
        { method = r.method
        , url = r.url
        , headers = r.headers
        , body = r.body
        , onRequestComplete = mapResponse >> onResult >> Effect.Task.succeed
        , timeout = r.timeout
        }
        |> Effect.Internal.Task


mapResponse : Http.Response body -> Response body
mapResponse response =
    case response of
        Http.BadUrl_ url ->
            BadUrl_ url

        Http.Timeout_ ->
            Timeout_

        Http.NetworkError_ ->
            NetworkError_

        Http.BadStatus_ metadata body ->
            BadStatus_ metadata body

        Http.GoodStatus_ metadata body ->
            GoodStatus_ metadata body


{-| Create a `Header`.
-}
header : String -> String -> Header
header =
    Tuple.pair


{-| Create an empty body for your `Request`.
-}
emptyBody : HttpBody
emptyBody =
    EmptyBody


{-| Put some JSON value in the body of your `Request`. This will automatically
add the `Content-Type: application/json` header.
-}
jsonBody : Json.Encode.Value -> HttpBody
jsonBody value =
    JsonBody value


{-| Put some string in the body of your `Request`.
-}
stringBody : String -> String -> HttpBody
stringBody contentType content =
    StringBody
        { contentType = contentType
        , content = content
        }


{-| Logic for interpreting a response body.
-}
type Expect msg
    = Expect (Response String -> msg)


{-| Expect the response body to be a `String`.
-}
expectString : (Result Error String -> msg) -> Expect msg
expectString onResult =
    Expect <|
        \response ->
            case response of
                BadUrl_ s ->
                    onResult (Err <| BadUrl s)

                Timeout_ ->
                    onResult (Err Timeout)

                NetworkError_ ->
                    onResult (Err NetworkError)

                BadStatus_ metadata body ->
                    onResult (Err <| BadStatus metadata.statusCode)

                GoodStatus_ _ body ->
                    onResult (Ok body)


{-| Expect a Response with a String body.
-}
expectStringResponse : (Result x a -> msg) -> (Response String -> Result x a) -> Expect msg
expectStringResponse toMsg onResponse =
    Expect (onResponse >> toMsg)


{-| Expect the response body to be JSON.
-}
expectJson : (Result Error a -> msg) -> Decoder a -> Expect msg
expectJson onResult decoder =
    Expect <|
        \response ->
            case response of
                BadUrl_ s ->
                    onResult (Err <| BadUrl s)

                Timeout_ ->
                    onResult (Err Timeout)

                NetworkError_ ->
                    onResult (Err NetworkError)

                BadStatus_ metadata _ ->
                    onResult (Err <| BadStatus metadata.statusCode)

                GoodStatus_ _ body ->
                    case Json.Decode.decodeString decoder body of
                        Err jsonError ->
                            onResult (Err <| BadBody <| Json.Decode.errorToString jsonError)

                        Ok value ->
                            onResult (Ok value)


{-| Expect the response body to be whatever.
-}
expectWhatever : (Result Error () -> msg) -> Expect msg
expectWhatever onResult =
    Expect <|
        \response ->
            case response of
                BadUrl_ s ->
                    onResult (Err <| BadUrl s)

                Timeout_ ->
                    onResult (Err Timeout)

                NetworkError_ ->
                    onResult (Err NetworkError)

                BadStatus_ metadata _ ->
                    onResult (Err <| BadStatus metadata.statusCode)

                GoodStatus_ _ _ ->
                    onResult (Ok ())


{-| A `Response` can come back a couple different ways:

  - `BadUrl_` means you did not provide a valid URL.
  - `Timeout_` means it took too long to get a response.
  - `NetworkError_` means the user turned off their wifi, went in a cave, etc.
  - `BadResponse_` means you got a response back, but the status code indicates failure.
  - `GoodResponse_` means you got a response back with a nice status code!

The type of the `body` depends on whether you use
[`expectStringResponse`](#expectStringResponse)
or [`expectBytesResponse`](#expectBytesResponse).

-}
type Response body
    = BadUrl_ String
    | Timeout_
    | NetworkError_
    | BadStatus_ Metadata body
    | GoodStatus_ Metadata body


{-| Extra information about the response:

  - `url` of the server that actually responded (so you can detect redirects)
  - `statusCode` like `200` or `404`
  - `statusText` describing what the `statusCode` means a little
  - `headers` like `Content-Length` and `Expires`

**Note:** It is possible for a response to have the same header multiple times.
In that case, all the values end up in a single entry in the `headers`
dictionary. The values are separated by commas, following the rules outlined
[here](https://stackoverflow.com/questions/4371328/are-duplicate-http-response-headers-acceptable).

-}
type alias Metadata =
    { url : String
    , statusCode : Int
    , statusText : String
    , headers : Dict String String
    }


{-| A `Request` can fail in a couple ways:

  - `BadUrl` means you did not provide a valid URL.
  - `Timeout` means it took too long to get a response.
  - `NetworkError` means the user turned off their wifi, went in a cave, etc.
  - `BadStatus` means you got a response back, but the status code indicates failure.
  - `BadBody` means you got a response back with a nice status code, but the body
    of the response was something unexpected. The `String` in this case is a
    debugging message that explains what went wrong with your JSON decoder or
    whatever.

**Note:** You can use [`expectStringResponse`](#expectStringResponse) and
[`expectBytesResponse`](#expectBytesResponse) to get more flexibility on this.

-}
type Error
    = BadUrl String
    | Timeout
    | NetworkError
    | BadStatus Int
    | BadBody String


{-| Just like [`request`](#request), but it creates a `Task`.
-}
task :
    { method : String
    , headers : List Header
    , url : String
    , body : HttpBody
    , resolver : Resolver restriction x a
    , timeout : Maybe Duration
    }
    -> Task restriction x a
task r =
    HttpTask
        { method = r.method
        , url = r.url
        , headers = r.headers
        , body = r.body
        , onRequestComplete =
            case r.resolver of
                StringResolver f ->
                    mapResponse >> f
        , timeout = r.timeout
        }


{-| Describes how to resolve an HTTP task.
-}
type Resolver restriction x a
    = StringResolver (Response String -> Task restriction x a)


{-| Turn a response with a `String` body into a result.
-}
stringResolver : (Response String -> Result x a) -> Resolver restriction x a
stringResolver f =
    let
        fromResult result =
            case result of
                Err x ->
                    Effect.Task.fail x

                Ok a ->
                    Effect.Task.succeed a
    in
    StringResolver (f >> fromResult)
