module Route exposing (Route(..), decode, encode, loginTokenName)

import Env
import Id exposing (CryptoHash, GroupId, LoginToken)
import Url
import Url.Builder
import Url.Parser exposing ((</>), (<?>))
import Url.Parser.Query


type Route
    = Homepage
    | GroupRoute GroupId
    | AdminRoute


decode : Url.Parser.Parser (( Route, Maybe (CryptoHash LoginToken) ) -> c) c
decode =
    Url.Parser.oneOf
        [ Url.Parser.top |> Url.Parser.map Homepage
        , Url.Parser.s "group" </> Url.Parser.string |> Url.Parser.map (Id.groupIdFromString >> GroupRoute)
        , Url.Parser.s "admin" |> Url.Parser.map AdminRoute
        ]
        <?> decodeLoginToken
        |> Url.Parser.map Tuple.pair


decodeLoginToken : Url.Parser.Query.Parser (Maybe (CryptoHash LoginToken))
decodeLoginToken =
    Url.Parser.Query.string loginTokenName |> Url.Parser.Query.map (Maybe.map Id.cryptoHashFromString)


loginTokenName =
    "login-token"


encode : Route -> Maybe (CryptoHash LoginToken) -> String
encode route maybeLoginToken =
    Url.Builder.crossOrigin
        Env.domain
        (case route of
            Homepage ->
                []

            GroupRoute groupId ->
                [ "group", Url.percentEncode (Id.groupIdToString groupId) ]

            AdminRoute ->
                [ "admin" ]
        )
        (case maybeLoginToken of
            Just loginToken ->
                [ Id.cryptoHashToString loginToken |> Url.Builder.string loginTokenName ]

            Nothing ->
                []
        )
