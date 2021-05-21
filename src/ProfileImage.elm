module ProfileImage exposing (..)

import Bytes exposing (Bytes)


type ProfileImage
    = DefaultImage
    | CustomImage Bytes
