module Evergreen.V61.FrontendUser exposing (..)

import Evergreen.V61.Description
import Evergreen.V61.Name
import Evergreen.V61.ProfileImage


type alias FrontendUser =
    { name : Evergreen.V61.Name.Name
    , description : Evergreen.V61.Description.Description
    , profileImage : Evergreen.V61.ProfileImage.ProfileImage
    }
