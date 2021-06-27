module Evergreen.V29.MockFile exposing (..)

import File


type File
    = RealFile File
    | MockFile String
