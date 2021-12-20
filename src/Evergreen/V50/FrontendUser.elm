module Evergreen.V50.FrontendUser exposing (..)

import Evergreen.V50.Description
import Evergreen.V50.Name
import Evergreen.V50.ProfileImage


type alias FrontendUser =
    { name : Evergreen.V50.Name.Name
    , description : Evergreen.V50.Description.Description
    , profileImage : Evergreen.V50.ProfileImage.ProfileImage
    }
