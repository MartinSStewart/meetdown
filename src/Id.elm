module Id exposing
    ( ClientId
    , CryptoHash
    , DeleteUserToken
    , GroupId
    , LoginToken
    , SessionId
    , UserId
    , adminUserId
    , clientIdFromString
    , clientIdToString
    , cryptoHashFromString
    , cryptoHashToString
    , getCryptoHash
    , sessionIdFromString
    )

import Env
import Lamdera
import Sha256


type UserId
    = UserId Never


type GroupId
    = GroupId Never


type SessionId
    = SessionId Lamdera.SessionId


type ClientId
    = ClientId Lamdera.ClientId


type CryptoHash a
    = CryptoHash String


type LoginToken
    = LoginToken Never


type DeleteUserToken
    = DeleteUserToken Never


sessionIdFromString : Lamdera.SessionId -> SessionId
sessionIdFromString =
    SessionId


clientIdFromString : Lamdera.ClientId -> ClientId
clientIdFromString =
    ClientId


clientIdToString : ClientId -> Lamdera.ClientId
clientIdToString (ClientId clientId) =
    clientId


adminUserId : CryptoHash UserId
adminUserId =
    cryptoHashFromString Env.adminUserId_


getCryptoHash : { a | secretCounter : Int } -> ( { a | secretCounter : Int }, CryptoHash b )
getCryptoHash model =
    ( { model | secretCounter = model.secretCounter + 1 }
    , Env.secretKey ++ ":" ++ String.fromInt model.secretCounter |> Sha256.sha256 |> CryptoHash
    )


cryptoHashToString : CryptoHash a -> String
cryptoHashToString (CryptoHash hash) =
    hash


cryptoHashFromString : String -> CryptoHash a
cryptoHashFromString =
    CryptoHash
