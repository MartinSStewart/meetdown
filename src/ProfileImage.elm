module ProfileImage exposing (..)

import Lamdera.Wire3 exposing (Bytes)


type ProfileImage
    = DefaultImage
    | CustomImage Bytes
