module Evergreen.V46.MockFile exposing (..)

import File


type File
    = RealFile File.File
    | MockFile String
