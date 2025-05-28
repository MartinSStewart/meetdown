module Evergreen.V74.FrontendUser exposing (..)

import Evergreen.V74.Description
import Evergreen.V74.Name
import Evergreen.V74.ProfileImage


type alias FrontendUser =
    { name : Evergreen.V74.Name.Name
    , description : Evergreen.V74.Description.Description
    , profileImage : Evergreen.V74.ProfileImage.ProfileImage
    }
