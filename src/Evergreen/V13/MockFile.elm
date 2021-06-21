module Evergreen.V13.MockFile exposing (..)

import File


type File
    = RealFile File
    | MockFile String
