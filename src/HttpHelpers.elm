module HttpHelpers exposing (..)

import Effect.Http as Http exposing (..)


httpErrorToString : Http.Error -> String
httpErrorToString err =
    case err of
        BadUrl url ->
            "HTTP Malformed url: " ++ url

        Timeout ->
            "HTTP Timeout exceeded"

        NetworkError ->
            "HTTP Network error"

        BadStatus code ->
            "Unexpected HTTP response code: " ++ String.fromInt code

        BadBody text ->
            "Unexpected HTTP response: " ++ text
