module Route exposing (Route(..), decode, encode, loginTokenName)

import Env
import Id exposing (CryptoHash, GroupId, LoginToken)
import Url
import Url.Builder
import Url.Parser exposing ((</>), (<?>))
import Url.Parser.Query


type Route
    = HomepageRoute
    | GroupRoute (CryptoHash GroupId)
    | AdminRoute
    | CreateGroupRoute
    | MyGroupsRoute


decode : Url.Parser.Parser (( Route, Maybe (CryptoHash LoginToken) ) -> c) c
decode =
    Url.Parser.oneOf
        [ Url.Parser.top |> Url.Parser.map HomepageRoute
        , Url.Parser.s "group" </> Url.Parser.string |> Url.Parser.map (Id.cryptoHashFromString >> GroupRoute)
        , Url.Parser.s "admin" |> Url.Parser.map AdminRoute
        , Url.Parser.s "create-group" |> Url.Parser.map CreateGroupRoute
        , Url.Parser.s "my-groups" |> Url.Parser.map MyGroupsRoute
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
            HomepageRoute ->
                []

            GroupRoute groupId ->
                [ "group", Url.percentEncode (Id.cryptoHashToString groupId) ]

            AdminRoute ->
                [ "admin" ]

            CreateGroupRoute ->
                [ "create-group" ]

            MyGroupsRoute ->
                [ "my-groups" ]
        )
        (case maybeLoginToken of
            Just loginToken ->
                [ Id.cryptoHashToString loginToken |> Url.Builder.string loginTokenName ]

            Nothing ->
                []
        )
