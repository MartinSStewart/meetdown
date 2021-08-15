module MockFile exposing (File(..))

import File


type File
    = RealFile File.File
    | MockFile String
