module Evergreen.V30.MockFile exposing (..)

import File


type File
    = RealFile File
    | MockFile String
