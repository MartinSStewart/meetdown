module UserPage exposing (view)

import Description
import Element exposing (Element)
import FrontendUser exposing (FrontendUser)
import Name
import ProfileImage
import Ui


view : FrontendUser -> Element msg
view user =
    Element.column
        (Ui.pageContentAttributes ++ [ Element.spacing 32 ])
        [ Element.row
            [ Element.spacing 16 ]
            [ ProfileImage.image user.profileImage, Ui.title (Name.toString user.name) ]
        , Description.toParagraph False user.description
        ]
