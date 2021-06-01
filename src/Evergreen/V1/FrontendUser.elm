module Evergreen.V1.FrontendUser exposing (..)

import Evergreen.V1.Description
import Evergreen.V1.Name
import Evergreen.V1.ProfileImage


type alias FrontendUser =
    { name : Evergreen.V1.Name.Name
    , description : Evergreen.V1.Description.Description
    , profileImage : Evergreen.V1.ProfileImage.ProfileImage
    }
