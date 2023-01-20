module Evergreen.V62.FrontendUser exposing (..)

import Evergreen.V62.Description
import Evergreen.V62.Name
import Evergreen.V62.ProfileImage


type alias FrontendUser =
    { name : Evergreen.V62.Name.Name
    , description : Evergreen.V62.Description.Description
    , profileImage : Evergreen.V62.ProfileImage.ProfileImage
    }
