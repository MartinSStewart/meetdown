module Evergreen.V68.Cache exposing (..)


type Cache item
    = ItemDoesNotExist
    | ItemCached item
    | ItemRequestPending
