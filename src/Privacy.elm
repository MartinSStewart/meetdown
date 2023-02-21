module Privacy exposing (view)

import Element exposing (Element)
import MarkdownThemed
import Route
import Ui
import UserConfig exposing (UserConfig)


view : UserConfig -> Element msg
view ({ texts } as userConfig) =
    Element.column
        Ui.pageContentAttributes
        [ Ui.title texts.privacyNotice
        , MarkdownThemed.renderFull userConfig <|
            texts.privacyMarkdown (Route.encode Route.TermsOfServiceRoute)
        ]
