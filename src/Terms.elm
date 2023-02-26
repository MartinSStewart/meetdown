module Terms exposing (view)

import Element
import MarkdownThemed
import Route
import Ui
import UserConfig exposing (UserConfig)


view : UserConfig -> Element.Element msg
view ({ texts } as userConfig) =
    Element.column
        Ui.pageContentAttributes
        [ Ui.title texts.tos
        , MarkdownThemed.renderFull userConfig (texts.tosMarkdown (Route.encode Route.PrivacyRoute) (Route.encode Route.CodeOfConductRoute))
        ]
