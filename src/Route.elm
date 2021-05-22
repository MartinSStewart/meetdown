module Route exposing (Route(..), Token(..), decode, encode, loginTokenName)

import Env
import Id exposing (CryptoHash, DeleteUserToken, GroupId, LoginToken)
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
    | MyProfileRoute


decode : Url.Parser.Parser (( Route, Token ) -> c) c
decode =
    Url.Parser.oneOf
        [ Url.Parser.top |> Url.Parser.map HomepageRoute
        , Url.Parser.s "group" </> Url.Parser.string |> Url.Parser.map (Id.cryptoHashFromString >> GroupRoute)
        , Url.Parser.s "admin" |> Url.Parser.map AdminRoute
        , Url.Parser.s "create-group" |> Url.Parser.map CreateGroupRoute
        , Url.Parser.s "my-groups" |> Url.Parser.map MyGroupsRoute
        , Url.Parser.s "profile" |> Url.Parser.map MyProfileRoute
        ]
        <?> decodeToken
        |> Url.Parser.map Tuple.pair


decodeToken : Url.Parser.Query.Parser Token
decodeToken =
    Url.Parser.Query.map2
        (\maybeLoginToken maybeDeleteUserToken ->
            case ( maybeLoginToken, maybeDeleteUserToken ) of
                ( Just _, Just _ ) ->
                    NoToken

                ( Nothing, Just deleteUserToken ) ->
                    DeleteUserToken deleteUserToken

                ( Just loginToken, Nothing ) ->
                    LoginToken loginToken

                ( Nothing, Nothing ) ->
                    NoToken
        )
        (Url.Parser.Query.string loginTokenName |> Url.Parser.Query.map (Maybe.map Id.cryptoHashFromString))
        (Url.Parser.Query.string deleteUserTokenName |> Url.Parser.Query.map (Maybe.map Id.cryptoHashFromString))


loginTokenName =
    "login-token"


deleteUserTokenName =
    "delete-user-token"


type Token
    = NoToken
    | LoginToken (CryptoHash LoginToken)
    | DeleteUserToken (CryptoHash DeleteUserToken)


encode : Route -> Token -> String
encode route token =
    Url.Builder.absolute
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

            MyProfileRoute ->
                [ "profile" ]
        )
        (case token of
            LoginToken loginToken ->
                [ Id.cryptoHashToString loginToken |> Url.Builder.string loginTokenName ]

            DeleteUserToken deleteUserToken ->
                [ Id.cryptoHashToString deleteUserToken |> Url.Builder.string deleteUserTokenName ]

            NoToken ->
                []
        )
