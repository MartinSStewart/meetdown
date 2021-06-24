module Evergreen.V25.MockFile exposing (..)

import File


type File
    = RealFile File
    | MockFile String
