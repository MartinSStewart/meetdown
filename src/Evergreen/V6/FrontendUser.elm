module Evergreen.V6.FrontendUser exposing (..)

import Evergreen.V6.Description
import Evergreen.V6.Name
import Evergreen.V6.ProfileImage


type alias FrontendUser =
    { name : Evergreen.V6.Name.Name
    , description : Evergreen.V6.Description.Description
    , profileImage : Evergreen.V6.ProfileImage.ProfileImage
    }
