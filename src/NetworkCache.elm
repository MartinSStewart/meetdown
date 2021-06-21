module NetworkCache exposing (..)

import AssocList as Dict exposing (Dict)
import FrontendUser exposing (FrontendUser)
import Group exposing (Group)
import Id exposing (GroupId, Id, UserId)


type alias Data =
    { users : Dict (Id UserId) (Cache FrontendUser)
    , groups : Dict GroupId (Cache Group)
    }


type Cache a
    = Cached Int a
    | NotFound
    | Fetching


type Request id
    = NoRequest
    | Request id


getValue : id -> Dict id (Cache value) -> ( Maybe value, Dict id (Cache value), Request id )
getValue id dict =
    case Dict.get id dict of
        Just (Cached _ value) ->
            ( Just value, dict, NoRequest )

        Just NotFound ->
            ( Nothing, dict, NoRequest )

        Just Fetching ->
            ( Nothing, dict, NoRequest )

        Nothing ->
            ( Nothing, Dict.insert id Fetching dict, Request id )
