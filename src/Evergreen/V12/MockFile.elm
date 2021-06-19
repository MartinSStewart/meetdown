module Evergreen.V12.MockFile exposing (..)

import File


type File
    = RealFile File
    | MockFile String
