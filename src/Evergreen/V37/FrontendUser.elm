module Evergreen.V37.FrontendUser exposing (..)

import Evergreen.V37.Description
import Evergreen.V37.Name
import Evergreen.V37.ProfileImage


type alias FrontendUser =
    { name : Evergreen.V37.Name.Name
    , description : Evergreen.V37.Description.Description
    , profileImage : Evergreen.V37.ProfileImage.ProfileImage
    }
