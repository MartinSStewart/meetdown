module DictExtra exposing (updateJust)

import AssocList as Dict exposing (Dict)


updateJust : key -> (value -> value) -> Dict key value -> Dict key value
updateJust key function dict =
    Dict.update key (Maybe.map function) dict
