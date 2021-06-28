module Evergreen.V33.MockFile exposing (..)

import File


type File
    = RealFile File
    | MockFile String
