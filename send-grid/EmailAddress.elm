module EmailAddress exposing (EmailAddress(..), fromString, toString)

{-|

@docs EmailAddress, fromString, toString

-}

-- This code is originally from bellroy/elm-email. I copied the implementation here in order to rename it to EmailAddress, normalize the contents (toLower all the strings), and make it an opaque type.

import Parser exposing ((|.), (|=), Parser, Step(..), andThen, chompWhile, end, getChompedString, loop, map, oneOf, problem, run, succeed, symbol)


{-| The type of an email address
-}
type EmailAddress
    = EmailAddress
        { localPart : String
        , tags : List String
        , domain : String
        , tld : List String
        }


{-| Parse an email address from a String.
Note that this will also convert all the characters to lowercase.
This is done because email addresses are case insensitive.
If the email wasn't converted to all lowercase you could end up with this gotcha `Email.fromString a@a.com /= Email.fromString A@a.com`
-}
fromString : String -> Maybe EmailAddress
fromString string =
    case run parseEmail string of
        Ok result ->
            result

        _ ->
            Nothing


{-| Render Email to a String
-}
toString : EmailAddress -> String
toString (EmailAddress { localPart, tags, domain, tld }) =
    String.join ""
        [ localPart
        , case tags of
            [] ->
                ""

            _ ->
                "+" ++ String.join "+" tags
        , "@"
        , domain
        , "."
        , String.join "." tld
        ]



-- Parser


parseEmail : Parser (Maybe EmailAddress)
parseEmail =
    let
        split char parser =
            loop []
                (\r ->
                    oneOf
                        [ succeed (\tld -> Loop (tld :: r))
                            |. symbol (String.fromChar char)
                            |= parser
                        , succeed ()
                            |> map (\_ -> Done (List.reverse r))
                        ]
                )
    in
    succeed
        (\localPart tags domain tlds ->
            let
                fullLocalPart =
                    String.join ""
                        [ localPart
                        , case tags of
                            [] ->
                                ""

                            _ ->
                                "+" ++ String.join "+" tags
                        ]
            in
            if String.length fullLocalPart > 64 then
                Nothing

            else if List.length tlds < 1 then
                Nothing

            else
                { localPart = String.toLower localPart
                , tags = List.map String.toLower tags
                , domain = String.toLower domain
                , tld = List.map String.toLower tlds
                }
                    |> EmailAddress
                    |> Just
        )
        |= parseLocalPart
        |= split '+' parseLocalPart
        |. symbol "@"
        |= parseDomain
        |= split '.' parseTld
        |. end


parseLocalPart : Parser String
parseLocalPart =
    succeed ()
        |. chompWhile
            (\a ->
                (a /= '+')
                    && (a /= '@')
                    && (a /= '\\')
                    && (a /= '"')
            )
        |> getChompedString
        |> andThen
            (\localPart ->
                if String.startsWith "." localPart || String.endsWith "." localPart || String.indexes ".." localPart /= [] then
                    problem "localPart can't start or end with a dot, nor can there be double dots"

                else if String.trim localPart /= localPart then
                    problem "localPart can't be wrapped with whitespace"

                else
                    succeed localPart
            )


parseDomain : Parser String
parseDomain =
    succeed ()
        |. chompWhile
            (\a ->
                (Char.isAlphaNum a
                    || (a == '-')
                )
                    && (a /= '@')
                    && (a /= '.')
            )
        |> getChompedString
        |> andThen
            (\a ->
                if String.length a < 1 then
                    problem "Domain has to be atleast 1 character long."

                else
                    succeed a
            )


parseTld : Parser String
parseTld =
    succeed ()
        |. chompWhile
            (\a ->
                Char.isUpper a
                    || Char.isLower a
                    || (a == '-')
            )
        |> getChompedString
        |> andThen
            (\a ->
                if String.length a >= 2 then
                    succeed a

                else
                    problem "Tld needs to be at least 2 character long."
            )
