module Id exposing
    ( ButtonId
    , ClientId(..)
    , DateInputId
    , DeleteUserToken
    , GroupId(..)
    , HtmlId(..)
    , Id(..)
    , LoginToken
    , NumberInputId
    , RadioButtonId
    , SessionId(..)
    , SessionIdFirst4Chars(..)
    , TextInputId
    , TimeInputId
    , UserId
    , anonymizeSessionId
    , buttonId
    , clientIdFromString
    , clientIdToString
    , cryptoHashFromString
    , cryptoHashToString
    , dateInputId
    , getUniqueId
    , getUniqueShortId
    , htmlIdToString
    , numberInputId
    , radioButtonId
    , sessionIdFirst4CharsToString
    , sessionIdFromString
    , textInputId
    , timeInputId
    )

import Env
import Sha256
import Time


type UserId
    = UserId Never


type GroupId
    = GroupId Never


type SessionId
    = SessionId String


type SessionIdFirst4Chars
    = SessionIdFirst4Chars String


anonymizeSessionId : SessionId -> SessionIdFirst4Chars
anonymizeSessionId (SessionId sessionId) =
    String.left 4 sessionId |> SessionIdFirst4Chars


sessionIdFirst4CharsToString : SessionIdFirst4Chars -> String
sessionIdFirst4CharsToString (SessionIdFirst4Chars a) =
    a


type ClientId
    = ClientId String


type Id a
    = Id String


type LoginToken
    = LoginToken Never


type DeleteUserToken
    = DeleteUserToken Never


type HtmlId a
    = HtmlId String


htmlIdToString : HtmlId a -> String
htmlIdToString (HtmlId a) =
    a


type ButtonId
    = ButtonId Never


buttonId : String -> HtmlId ButtonId
buttonId =
    (++) "a_" >> HtmlId


type TextInputId
    = TextInputId Never


textInputId : String -> HtmlId TextInputId
textInputId =
    (++) "b_" >> HtmlId


type RadioButtonId
    = RadioButtonId Never


radioButtonId : String -> (a -> String) -> a -> HtmlId RadioButtonId
radioButtonId radioGroupName valueToString value =
    "c_" ++ radioGroupName ++ "_" ++ valueToString value |> HtmlId


type NumberInputId
    = NumberInputId Never


numberInputId : String -> HtmlId NumberInputId
numberInputId =
    (++) "d_" >> HtmlId


type DateInputId
    = DateInputId Never


dateInputId : String -> HtmlId DateInputId
dateInputId =
    (++) "e_" >> HtmlId


type TimeInputId
    = TimeInputId Never


timeInputId : String -> HtmlId TimeInputId
timeInputId =
    (++) "f_" >> HtmlId


sessionIdFromString : String -> SessionId
sessionIdFromString =
    SessionId


clientIdFromString : String -> ClientId
clientIdFromString =
    ClientId


clientIdToString : ClientId -> String
clientIdToString (ClientId clientId) =
    clientId


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
