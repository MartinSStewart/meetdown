module Evergreen.V25.FrontendUser exposing (..)

import Evergreen.V25.Description
import Evergreen.V25.Name
import Evergreen.V25.ProfileImage


type alias FrontendUser =
    { name : Evergreen.V25.Name.Name
    , description : Evergreen.V25.Description.Description
    , profileImage : Evergreen.V25.ProfileImage.ProfileImage
    }
