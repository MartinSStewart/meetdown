module FrontendUser exposing (..)

import Description exposing (Description)
import Name exposing (Name)
import ProfileImage exposing (ProfileImage)


type alias FrontendUser =
    { name : Name
    , description : Description
    , profileImage : ProfileImage
    }
