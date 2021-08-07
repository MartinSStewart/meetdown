module Evergreen.V46.FrontendUser exposing (..)

import Evergreen.V46.Description
import Evergreen.V46.Name
import Evergreen.V46.ProfileImage


type alias FrontendUser =
    { name : Evergreen.V46.Name.Name
    , description : Evergreen.V46.Description.Description
    , profileImage : Evergreen.V46.ProfileImage.ProfileImage
    }
