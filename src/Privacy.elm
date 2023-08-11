module Privacy exposing (view)

import Element exposing (Element)
import MarkdownThemed
import MyUi
import Route
import UserConfig exposing (UserConfig)


view : UserConfig -> Element msg
view ({ texts } as userConfig) =
    Element.column
        MyUi.pageContentAttributes
        [ MyUi.title texts.privacyNotice
        , MarkdownThemed.renderFull userConfig (texts.privacyMarkdown (Route.encode Route.TermsOfServiceRoute))
        ]
