module UserPage exposing (view)

import Description
import Element exposing (Element)
import FrontendUser exposing (FrontendUser)
import MyUi
import Name
import ProfileImage
import UserConfig exposing (UserConfig)


view : UserConfig -> FrontendUser -> Element msg
view userConfig user =
    Element.column
        (MyUi.pageContentAttributes ++ [ Element.spacing 32 ])
        [ Element.row
            [ Element.spacing 16 ]
            [ ProfileImage.image userConfig ProfileImage.defaultSize user.profileImage, MyUi.title (Name.toString user.name) ]
        , Description.toParagraph userConfig False user.description
        ]
