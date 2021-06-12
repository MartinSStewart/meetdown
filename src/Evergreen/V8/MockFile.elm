module Evergreen.V8.MockFile exposing (..)

import File


type File
    = RealFile File
    | MockFile String
