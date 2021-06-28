module Evergreen.V37.MockFile exposing (..)

import File


type File
    = RealFile File
    | MockFile String
