module Evergreen.V49.FrontendUser exposing (..)

import Evergreen.V49.Description
import Evergreen.V49.Name
import Evergreen.V49.ProfileImage


type alias FrontendUser =
    { name : Evergreen.V49.Name.Name
    , description : Evergreen.V49.Description.Description
    , profileImage : Evergreen.V49.ProfileImage.ProfileImage
    }
