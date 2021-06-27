module Evergreen.V30.FrontendUser exposing (..)

import Evergreen.V30.Description
import Evergreen.V30.Name
import Evergreen.V30.ProfileImage


type alias FrontendUser =
    { name : Evergreen.V30.Name.Name
    , description : Evergreen.V30.Description.Description
    , profileImage : Evergreen.V30.ProfileImage.ProfileImage
    }
