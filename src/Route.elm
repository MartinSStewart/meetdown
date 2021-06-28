module Route exposing (Route(..), Token(..), decode, encode, encodeWithToken, loginTokenName)

import Group exposing (EventId)
import GroupName exposing (GroupName)
import Id exposing (DeleteUserToken, GroupId, Id, LoginToken, UserId)
import Name exposing (Name)
import Url
import Url.Builder
import Url.Parser exposing ((</>), (<?>))
import Url.Parser.Query


type Route
    = HomepageRoute
    | GroupRoute (Id GroupId) GroupName
    | AdminRoute
    | CreateGroupRoute
    | SearchGroupsRoute String
    | MyGroupsRoute
    | MyProfileRoute
    | UserRoute (Id UserId) Name
    | PrivacyRoute
    | TermsOfServiceRoute
    | CodeOfConductRoute
    | FrequentQuestionsRoute


decode : Url.Parser.Parser (( Route, Token ) -> c) c
decode =
    Url.Parser.oneOf
        [ Url.Parser.top |> Url.Parser.map HomepageRoute
        , Url.Parser.s "group"
            </> Url.Parser.string
            </> Url.Parser.string
            |> Url.Parser.map
                (\groupIdSegment groupNameSegment ->
                    case ( Id.cryptoHashFromString groupIdSegment, decodeGroupName groupNameSegment ) of
                        ( Just groupId, Just groupName ) ->
                            GroupRoute groupId groupName

                        _ ->
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
        , Url.Parser.s "user"
            </> Url.Parser.string
            </> Url.Parser.string
            |> Url.Parser.map
                (\userIdSegment userNameSegment ->
                    case ( Id.cryptoHashFromString userIdSegment, decodeName userNameSegment ) of
                        ( Just userId, Just name ) ->
                            UserRoute userId name

                        _ ->
                            HomepageRoute
                )
        , Url.Parser.s "privacy" |> Url.Parser.map PrivacyRoute
        , Url.Parser.s "terms-of-service" |> Url.Parser.map TermsOfServiceRoute
        , Url.Parser.s "code-of-conduct" |> Url.Parser.map CodeOfConductRoute
        , Url.Parser.s "faq" |> Url.Parser.map FrequentQuestionsRoute
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
        (Url.Parser.Query.string loginTokenName |> Url.Parser.Query.map (Maybe.andThen Id.cryptoHashFromString))
        (Url.Parser.Query.string groupIdName |> Url.Parser.Query.map (Maybe.andThen Id.cryptoHashFromString))
        (Url.Parser.Query.int eventIdName |> Url.Parser.Query.map (Maybe.map Group.eventIdFromInt))
        (Url.Parser.Query.string deleteUserTokenName |> Url.Parser.Query.map (Maybe.andThen Id.cryptoHashFromString))


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
    | LoginToken (Id LoginToken) (Maybe ( Id GroupId, EventId ))
    | DeleteUserToken (Id DeleteUserToken)


encode : Route -> String
encode route =
    encodeWithToken route NoToken


encodeGroupName : GroupName -> String
encodeGroupName =
    GroupName.toString >> String.replace " " "-" >> Url.percentEncode


decodeGroupName : String -> Maybe GroupName
decodeGroupName text =
    case Url.percentDecode text of
        Just decoded ->
            String.replace "-" " " decoded |> GroupName.fromString |> Result.toMaybe

        Nothing ->
            Nothing


encodeName : Name -> String
encodeName =
    Name.toString >> String.replace " " "-" >> Url.percentEncode


decodeName : String -> Maybe Name
decodeName text =
    case Url.percentDecode text of
        Just decoded ->
            String.replace "-" " " decoded |> Name.fromString |> Result.toMaybe

        Nothing ->
            Nothing


encodeWithToken : Route -> Token -> String
encodeWithToken route token =
    Url.Builder.absolute
        (case route of
            HomepageRoute ->
                []

            GroupRoute groupId groupName ->
                [ "group", Id.cryptoHashToString groupId, encodeGroupName groupName ]

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

            UserRoute userId name ->
                [ "user", Id.cryptoHashToString userId, encodeName name ]

            PrivacyRoute ->
                [ "privacy" ]

            TermsOfServiceRoute ->
                [ "terms-of-service" ]

            CodeOfConductRoute ->
                [ "code-of-conduct" ]

            FrequentQuestionsRoute ->
                [ "faq" ]
        )
        (case token of
            LoginToken loginToken maybeJoinEvent ->
                Url.Builder.string loginTokenName (Id.cryptoHashToString loginToken)
                    :: (case maybeJoinEvent of
                            Just ( groupId, eventId ) ->
                                [ Url.Builder.string groupIdName (Id.cryptoHashToString groupId)
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
