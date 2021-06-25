module Evergreen.V26.MockFile exposing (..)

import File


type File
    = RealFile File
    | MockFile String
