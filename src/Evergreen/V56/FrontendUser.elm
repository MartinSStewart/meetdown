module Evergreen.V56.FrontendUser exposing (..)

import Evergreen.V56.Description
import Evergreen.V56.Name
import Evergreen.V56.ProfileImage


type alias FrontendUser =
    { name : Evergreen.V56.Name.Name
    , description : Evergreen.V56.Description.Description
    , profileImage : Evergreen.V56.ProfileImage.ProfileImage
    }
