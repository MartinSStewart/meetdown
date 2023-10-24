module Evergreen.V69.Cache exposing (..)


type Cache item
    = ItemDoesNotExist
    | ItemCached item
    | ItemRequestPending
