module Evergreen.V71.FrontendUser exposing (..)

import Evergreen.V71.Description
import Evergreen.V71.Name
import Evergreen.V71.ProfileImage


type alias FrontendUser =
    { name : Evergreen.V71.Name.Name
    , description : Evergreen.V71.Description.Description
    , profileImage : Evergreen.V71.ProfileImage.ProfileImage
    }
