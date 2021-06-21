module Id exposing
    ( ButtonId
    , ClientId
    , DateInputId
    , DeleteUserToken
    , GroupId
    , HtmlId
    , Id
    , LoginToken
    , NumberInputId
    , RadioButtonId
    , SessionId
    , SessionIdLast4Chars
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
    , groupIdFromInt
    , groupIdToInt
    , htmlIdToString
    , numberInputId
    , radioButtonId
    , sessionIdFromString
    , sessionIdLast4CharsToString
    , textInputId
    , timeInputId
    )

import Env
import Sha256
import Time


type UserId
    = UserId Never


type GroupId
    = GroupId Int


type SessionId
    = SessionId String


type SessionIdLast4Chars
    = SessionIdLast4Chars String


anonymizeSessionId : SessionId -> SessionIdLast4Chars
anonymizeSessionId (SessionId sessionId) =
    String.right 4 sessionId |> SessionIdLast4Chars


sessionIdLast4CharsToString : SessionIdLast4Chars -> String
sessionIdLast4CharsToString (SessionIdLast4Chars a) =
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


cryptoHashToString : Id a -> String
cryptoHashToString (Id hash) =
    hash


cryptoHashFromString : String -> Id a
cryptoHashFromString =
    Id


groupIdFromInt : Int -> GroupId
groupIdFromInt =
    GroupId


groupIdToInt : GroupId -> Int
groupIdToInt (GroupId groupId) =
    groupId
