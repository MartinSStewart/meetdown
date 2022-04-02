module Cache exposing (..)

import AssocList as Dict exposing (Dict)


type Cache item
    = ItemDoesNotExist
    | ItemCached item
    | ItemRequestPending


map : (a -> a) -> Cache a -> Cache a
map mapFunc userCache =
    case userCache of
        ItemDoesNotExist ->
            ItemDoesNotExist

        ItemCached item ->
            mapFunc item |> ItemCached

        ItemRequestPending ->
            ItemRequestPending


get : key -> Dict key (Cache value) -> Maybe value
get key dict =
    case Dict.get key dict of
        Just ItemDoesNotExist ->
            Nothing

        Just (ItemCached item) ->
            Just item

        Just ItemRequestPending ->
            Nothing

        Nothing ->
            Nothing
