module Evergreen.V62.Cache exposing (..)


type Cache item
    = ItemDoesNotExist
    | ItemCached item
    | ItemRequestPending
