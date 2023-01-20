module UserPage exposing (view)

import Colors exposing (UserConfig)
import Description
import Element exposing (Element)
import FrontendUser exposing (FrontendUser)
import Name
import ProfileImage
import Ui


view : UserConfig -> FrontendUser -> Element msg
view userConfig user =
    Element.column
        (Ui.pageContentAttributes ++ [ Element.spacing 32 ])
        [ Element.row
            [ Element.spacing 16 ]
            [ ProfileImage.image userConfig ProfileImage.defaultSize user.profileImage, Ui.title (Name.toString user.name) ]
        , Description.toParagraph userConfig False user.description
        ]
