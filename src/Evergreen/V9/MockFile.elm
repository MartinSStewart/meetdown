module Evergreen.V9.MockFile exposing (..)

import File


type File
    = RealFile File
    | MockFile String
