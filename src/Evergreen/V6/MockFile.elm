module Evergreen.V6.MockFile exposing (..)

import File


type File
    = RealFile File
    | MockFile String
