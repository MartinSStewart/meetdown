module Evergreen.V56.Cache exposing (..)


type Cache item
    = ItemDoesNotExist
    | ItemCached item
    | ItemRequestPending
