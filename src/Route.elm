module Route exposing (Route(..), Token(..), decode, encode, encodeWithToken, loginTokenName)

import Group exposing (EventId)
import GroupName exposing (GroupName)
import Id exposing (DeleteUserToken, GroupId, Id, LoginToken, UserId)
import Url
import Url.Builder
import Url.Parser exposing ((</>), (<?>))
import Url.Parser.Query


type Route
    = HomepageRoute
    | GroupRoute GroupId GroupName
    | AdminRoute
    | CreateGroupRoute
    | SearchGroupsRoute String
    | MyGroupsRoute
    | MyProfileRoute
    | UserRoute (Id UserId)


decode : Url.Parser.Parser (( Route, Token ) -> c) c
decode =
    Url.Parser.oneOf
        [ Url.Parser.top |> Url.Parser.map HomepageRoute
        , Url.Parser.s "group"
            </> Url.Parser.string
            |> Url.Parser.map
                (\text ->
                    case String.split "-" text of
                        head :: rest ->
                            case ( String.toInt head, String.join "-" rest |> Url.percentDecode ) of
                                ( Just groupId, Just groupNameText ) ->
                                    case GroupName.fromString (String.replace "-" " " groupNameText) of
                                        Ok groupName ->
                                            GroupRoute (Id.groupIdFromInt groupId) groupName

                                        Err _ ->
                                            HomepageRoute

                                _ ->
                                    HomepageRoute

                        [] ->
                            HomepageRoute
                )
        , Url.Parser.s "admin" |> Url.Parser.map AdminRoute
        , Url.Parser.s "create-group" |> Url.Parser.map CreateGroupRoute
        , Url.Parser.s "search"
            </> Url.Parser.string
            |> Url.Parser.map (Url.percentDecode >> Maybe.withDefault "" >> SearchGroupsRoute)
        , Url.Parser.s "search" |> Url.Parser.map (SearchGroupsRoute "")
        , Url.Parser.s "my-groups" |> Url.Parser.map MyGroupsRoute
        , Url.Parser.s "profile" |> Url.Parser.map MyProfileRoute
        , Url.Parser.s "user" </> Url.Parser.string |> Url.Parser.map (Id.cryptoHashFromString >> UserRoute)
        ]
        <?> decodeToken
        |> Url.Parser.map Tuple.pair


decodeToken : Url.Parser.Query.Parser Token
decodeToken =
    Url.Parser.Query.map4
        (\maybeLoginToken maybeGroupId maybeEventId maybeDeleteUserToken ->
            let
                maybeJoinEvent =
                    Maybe.map2 Tuple.pair maybeGroupId maybeEventId
            in
            case ( maybeLoginToken, maybeDeleteUserToken ) of
                ( Just _, Just _ ) ->
                    NoToken

                ( Nothing, Just deleteUserToken ) ->
                    DeleteUserToken deleteUserToken

                ( Just loginToken, Nothing ) ->
                    LoginToken loginToken maybeJoinEvent

                ( Nothing, Nothing ) ->
                    NoToken
        )
        (Url.Parser.Query.string loginTokenName |> Url.Parser.Query.map (Maybe.map Id.cryptoHashFromString))
        (Url.Parser.Query.int groupIdName |> Url.Parser.Query.map (Maybe.map Id.groupIdFromInt))
        (Url.Parser.Query.int eventIdName |> Url.Parser.Query.map (Maybe.map Group.eventIdFromInt))
        (Url.Parser.Query.string deleteUserTokenName |> Url.Parser.Query.map (Maybe.map Id.cryptoHashFromString))


loginTokenName =
    "login-token"


groupIdName =
    "group-id"


eventIdName =
    "event-id"


deleteUserTokenName =
    "delete-user-token"


type Token
    = NoToken
    | LoginToken (Id LoginToken) (Maybe ( GroupId, EventId ))
    | DeleteUserToken (Id DeleteUserToken)


encode : Route -> String
encode route =
    encodeWithToken route NoToken


encodeWithToken : Route -> Token -> String
encodeWithToken route token =
    Url.Builder.absolute
        (case route of
            HomepageRoute ->
                []

            GroupRoute groupId groupName ->
                let
                    groupNameText =
                        GroupName.toString groupName
                            |> String.replace " " "-"
                            |> Url.percentEncode
                in
                [ "group", String.fromInt (Id.groupIdToInt groupId) ++ "-" ++ groupNameText ]

            AdminRoute ->
                [ "admin" ]

            CreateGroupRoute ->
                [ "create-group" ]

            MyGroupsRoute ->
                [ "my-groups" ]

            MyProfileRoute ->
                [ "profile" ]

            SearchGroupsRoute searchText ->
                "search"
                    :: (if searchText == "" then
                            []

                        else
                            [ Url.percentEncode searchText ]
                       )

            UserRoute userId ->
                [ "user", Id.cryptoHashToString userId ]
        )
        (case token of
            LoginToken loginToken maybeJoinEvent ->
                Url.Builder.string loginTokenName (Id.cryptoHashToString loginToken)
                    :: (case maybeJoinEvent of
                            Just ( groupId, eventId ) ->
                                [ Url.Builder.int groupIdName (Id.groupIdToInt groupId)
                                , Url.Builder.int eventIdName (Group.eventIdToInt eventId)
                                ]

                            Nothing ->
                                []
                       )

            DeleteUserToken deleteUserToken ->
                [ Id.cryptoHashToString deleteUserToken |> Url.Builder.string deleteUserTokenName ]

            NoToken ->
                []
        )
