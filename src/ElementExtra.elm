module ElementExtra exposing (nonemptyText)

import Element exposing (Element)
import Element.Input
import String.Nonempty exposing (NonemptyString)


nonemptyText : NonemptyString -> Element msg
nonemptyText =
    String.Nonempty.toString >> Element.text
