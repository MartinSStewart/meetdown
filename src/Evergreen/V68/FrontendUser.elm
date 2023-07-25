module Evergreen.V68.FrontendUser exposing (..)

import Evergreen.V68.Description
import Evergreen.V68.Name
import Evergreen.V68.ProfileImage


type alias FrontendUser =
    { name : Evergreen.V68.Name.Name
    , description : Evergreen.V68.Description.Description
    , profileImage : Evergreen.V68.ProfileImage.ProfileImage
    }
