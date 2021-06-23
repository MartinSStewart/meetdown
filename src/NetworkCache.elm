module NetworkCache exposing (Cache(..), Request(..), getValue)

import AssocList as Dict exposing (Dict)
import FrontendUser exposing (FrontendUser)
import Group exposing (Group)
import Id exposing (GroupId, Id, UserId)
import Types exposing (LoadedFrontend)


type Cache a
    = Cached Int a
    | NotFound
    | Fetching


type Request id
    = NoRequest
    | Request id


type Object valueBuilder requestBuilder state
    = Object (Maybe valueBuilder) requestBuilder state


start valueBuilder requestBuilder state =
    Object (Just valueBuilder) requestBuilder state


getValue :
    id
    -> (state -> Dict id (Cache a))
    -> (Dict id (Cache a) -> state -> state)
    -> Object (a -> value) (Request id -> request) state
    -> Object value request state
getValue id getter setter (Object maybeValueBuilder requestBuilder state) =
    let
        ( maybeValue, newDict, request ) =
            getValueHelper id (getter state)
    in
    Object
        (Maybe.map2
            (\valueBuilder value -> valueBuilder value)
            maybeValueBuilder
            maybeValue
        )
        (requestBuilder request)
        (setter newDict state)


a model =
    start Tuple.pair Tuple.pair
        |> getValue (Id.groupIdFromInt 0) .cachedGroups (\dict a -> { a | cachedGroups = dict })


getValueHelper : id -> Dict id (Cache value) -> ( Maybe value, Dict id (Cache value), Request id )
getValueHelper id dict =
    case Dict.get id dict of
        Just (Cached _ value) ->
            ( Just value, dict, NoRequest )

        Just NotFound ->
            ( Nothing, dict, NoRequest )

        Just Fetching ->
            ( Nothing, dict, NoRequest )

        Nothing ->
            ( Nothing, Dict.insert id Fetching dict, Request id )
