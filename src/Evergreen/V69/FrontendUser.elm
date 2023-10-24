module Evergreen.V69.FrontendUser exposing (..)

import Evergreen.V69.Description
import Evergreen.V69.Name
import Evergreen.V69.ProfileImage


type alias FrontendUser =
    { name : Evergreen.V69.Name.Name
    , description : Evergreen.V69.Description.Description
    , profileImage : Evergreen.V69.ProfileImage.ProfileImage
    }
