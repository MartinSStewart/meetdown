module MockFile exposing (File(..))

import File


type File
    = RealFile File.File
    | MockFile { name : String, content : String }
