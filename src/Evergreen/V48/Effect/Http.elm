module Evergreen.V48.Effect.Http exposing (..)


type Error
    = BadUrl String
    | Timeout
    | NetworkError
    | BadStatus Int
    | BadBody String
