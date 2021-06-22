module Evergreen.V16.FrontendUser exposing (..)

import Evergreen.V16.Description
import Evergreen.V16.Name
import Evergreen.V16.ProfileImage


type alias FrontendUser =
    { name : Evergreen.V16.Name.Name
    , description : Evergreen.V16.Description.Description
    , profileImage : Evergreen.V16.ProfileImage.ProfileImage
    }
