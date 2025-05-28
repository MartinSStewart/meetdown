module Evergreen.V74.Cache exposing (..)


type Cache item
    = ItemDoesNotExist
    | ItemCached item
    | ItemRequestPending
