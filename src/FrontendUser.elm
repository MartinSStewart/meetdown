module FrontendUser exposing (..)

import Name exposing (Name)
import ProfileImage exposing (ProfileImage)


type alias FrontendUser =
    { name : Name
    , profileImage : ProfileImage
    }
