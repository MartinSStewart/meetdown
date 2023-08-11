module Terms exposing (view)

import Element
import MarkdownThemed
import MyUi
import Route
import UserConfig exposing (UserConfig)


view : UserConfig -> Element.Element msg
view ({ texts } as userConfig) =
    Element.column
        MyUi.pageContentAttributes
        [ MyUi.title texts.tos
        , MarkdownThemed.renderFull userConfig (texts.tosMarkdown (Route.encode Route.PrivacyRoute) (Route.encode Route.CodeOfConductRoute))
        ]
