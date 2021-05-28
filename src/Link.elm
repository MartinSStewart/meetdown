module Link exposing (Link, fromString, toString)

import Parser exposing ((|.), (|=), Parser)


type Link
    = Link String


fromString : String -> Maybe Link
fromString text =
    case Parser.run parser text of
        Ok () ->
            Link text |> Just

        Err _ ->
            Nothing


toString : Link -> String
toString (Link url) =
    url


parser : Parser ()
parser =
    Parser.succeed ()
        |. Parser.oneOf
            [ Parser.token "http://"
            , Parser.token "https://"
            , Parser.token ""
            ]
        |. (Parser.chompWhile (\c -> c /= '.')
                |> Parser.getChompedString
                |> Parser.andThen
                    (\text ->
                        if text == "" then
                            Parser.problem "Invalid url"

                        else if String.contains " " text then
                            Parser.problem "Invalid url"

                        else
                            Parser.succeed ()
                    )
           )
        |. Parser.chompIf (always True)
