module Id exposing
    ( DeleteUserToken
    , GroupId
    , Id
    , LoginToken
    , SessionIdFirst4Chars
    , UserId
    , anonymizeSessionId
    , cryptoHashFromString
    , cryptoHashToString
    , getUniqueId
    , getUniqueShortId
    , sessionIdFirst4CharsToString
    )

import Effect.Lamdera as Lamdera exposing (SessionId)
import Env
import Sha256
import Time


type UserId
    = UserId Never


type GroupId
    = GroupId Never


type SessionIdFirst4Chars
    = SessionIdFirst4Chars String


anonymizeSessionId : SessionId -> SessionIdFirst4Chars
anonymizeSessionId sessionId =
    String.left 4 (Lamdera.sessionIdToString sessionId) |> SessionIdFirst4Chars


sessionIdFirst4CharsToString : SessionIdFirst4Chars -> String
sessionIdFirst4CharsToString (SessionIdFirst4Chars a) =
    a


type Id a
    = Id String


type LoginToken
    = LoginToken Never


type DeleteUserToken
    = DeleteUserToken Never


getUniqueId : { a | secretCounter : Int, time : Time.Posix } -> ( { a | secretCounter : Int, time : Time.Posix }, Id b )
getUniqueId model =
    ( { model | secretCounter = model.secretCounter + 1 }
    , Env.secretKey
        ++ ":"
        ++ String.fromInt model.secretCounter
        ++ ":"
        ++ String.fromInt (Time.posixToMillis model.time)
        |> Sha256.sha256
        |> Id
    )


getUniqueShortId :
    (Id b -> { a | secretCounter : Int, time : Time.Posix } -> Bool)
    -> { a | secretCounter : Int, time : Time.Posix }
    -> ( { a | secretCounter : Int, time : Time.Posix }, Id b )
getUniqueShortId isUnique model =
    let
        id =
            Env.secretKey
                ++ ":"
                ++ String.fromInt model.secretCounter
                ++ ":"
                ++ String.fromInt (Time.posixToMillis model.time)
                |> Sha256.sha224
                |> String.left 6
                |> Id

        newModel =
            { model | secretCounter = model.secretCounter + 1 }
    in
    if isUnique id newModel then
        ( newModel, id )

    else
        getUniqueShortId isUnique newModel


cryptoHashToString : Id a -> String
cryptoHashToString (Id hash) =
    hash


cryptoHashFromString : String -> Maybe (Id a)
cryptoHashFromString text =
    if text == "" then
        Nothing

    else if
        String.all
            (\char ->
                let
                    code =
                        Char.toCode char
                in
                -- Only digits and lower case letters are allowed
                (0x30 <= code && code <= 0x39) || (0x61 <= code && code <= 0x66)
            )
            text
    then
        Just (Id text)

    else
        Nothing
