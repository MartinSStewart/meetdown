module ElementExtra exposing (nonemptyText)

import Element exposing (Element)
import String.Nonempty exposing (NonemptyString)


nonemptyText : NonemptyString -> Element msg
nonemptyText =
    String.Nonempty.toString >> Element.text
