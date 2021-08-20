module Evergreen.V48.FrontendUser exposing (..)

import Evergreen.V48.Description
import Evergreen.V48.Name
import Evergreen.V48.ProfileImage


type alias FrontendUser =
    { name : Evergreen.V48.Name.Name
    , description : Evergreen.V48.Description.Description
    , profileImage : Evergreen.V48.ProfileImage.ProfileImage
    }
