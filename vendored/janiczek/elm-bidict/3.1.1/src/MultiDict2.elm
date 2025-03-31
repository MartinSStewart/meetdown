module MultiDict2 exposing
    ( MultiDict
    , toDict, fromDict
    , empty, singleton, insert, update, remove, removeAll
    , isEmpty, member, get, size
    , keys, values, toList, fromList, fromFlatList
    , map, foldl, foldr, filter, partition
    , union, intersect, diff, merge
    )

{-| A dictionary mapping unique keys to **multiple** values, allowing for
modelling **one-to-many relationships.**

Example usage:

    oneToMany : MultiDict String Int
    oneToMany =
        MultiDict.empty
            |> MultiDict.insert "A" 1
            |> MultiDict.insert "B" 2
            |> MultiDict.insert "C" 3
            |> MultiDict.insert "A" 2

    MultiDict.get "A" oneToMany
    --> Set.fromList [1, 2]


# Dictionaries

@docs MultiDict


# Differences from Dict

@docs toDict, fromDict


# Build

@docs empty, singleton, insert, update, remove, removeAll


# Query

@docs isEmpty, member, get, size


# Lists

@docs keys, values, toList, fromList, fromFlatList


# Transform

@docs map, foldl, foldr, filter, partition


# Combine

@docs union, intersect, diff, merge

-}

import Dict exposing (Dict)
import Dict.Extra
import List.Extra
import Set exposing (Set)


{-| The underlying data structure. Think about it as

     type alias MultiDict comparable1 comparable2 =
         Dict comparable1 (Set comparable2) -- just a normal Dict!

-}
type MultiDict comparable1 comparable2
    = MultiDict (Dict comparable1 (Set comparable2))


{-| Create an empty dictionary.
-}
empty : MultiDict comparable1 comparable2
empty =
    MultiDict Dict.empty


{-| Create a dictionary with one key-value pair.
-}
singleton : comparable1 -> comparable2 -> MultiDict comparable1 comparable2
singleton from to =
    MultiDict (Dict.singleton from (Set.singleton to))


{-| Insert a key-value pair into a dictionary. Replaces value when there is
a collision.
-}
insert : comparable1 -> comparable2 -> MultiDict comparable1 comparable2 -> MultiDict comparable1 comparable2
insert from to (MultiDict d) =
    MultiDict <|
        Dict.update
            from
            (\maybeSet ->
                case maybeSet of
                    Nothing ->
                        Just (Set.singleton to)

                    Just set ->
                        Just (Set.insert to set)
            )
            d


{-| Update the value of a dictionary for a specific key with a given function.
-}
update : comparable1 -> (Set comparable2 -> Set comparable2) -> MultiDict comparable1 comparable2 -> MultiDict comparable1 comparable2
update from fn (MultiDict d) =
    MultiDict <| Dict.update from (Maybe.andThen (normalizeSet << fn)) d


{-| In our model, (Just Set.empty) has the same meaning as Nothing.
Make it be Nothing!
-}
normalizeSet : Set comparable1 -> Maybe (Set comparable1)
normalizeSet set =
    if Set.isEmpty set then
        Nothing

    else
        Just set


{-| Remove all key-value pairs for the given key from a dictionary. If the key is
not found, no changes are made.
-}
removeAll : comparable1 -> MultiDict comparable1 comparable2 -> MultiDict comparable1 comparable2
removeAll from (MultiDict d) =
    MultiDict (Dict.remove from d)


{-| Remove a single key-value pair from a dictionary. If the key is not found,
no changes are made.
-}
remove : comparable1 -> comparable2 -> MultiDict comparable1 comparable2 -> MultiDict comparable1 comparable2
remove from to (MultiDict d) =
    MultiDict <|
        Dict.update from (Maybe.andThen (Set.remove to >> normalizeSet)) d


{-| Determine if a dictionary is empty.

    isEmpty empty == True

-}
isEmpty : MultiDict comparable1 comparable2 -> Bool
isEmpty (MultiDict d) =
    Dict.isEmpty d


{-| Determine if a key is in a dictionary.
-}
member : comparable1 -> MultiDict comparable1 comparable2 -> Bool
member from (MultiDict d) =
    Dict.member from d


{-| Get the value associated with a key. If the key is not found, return
`Nothing`. This is useful when you are not sure if a key will be in the
dictionary.

    animals = fromList [ ("Tom", "cat"), ("Jerry", "mouse") ]

    get "Tom"   animals == Set.singleton "cat"
    get "Jerry" animals == Set.singleton "mouse"
    get "Spike" animals == Set.empty

-}
get : comparable1 -> MultiDict comparable1 comparable2 -> Set comparable2
get from (MultiDict d) =
    Dict.get from d
        |> Maybe.withDefault Set.empty


{-| Determine the number of key-value pairs in the dictionary.
-}
size : MultiDict comparable1 comparable2 -> Int
size (MultiDict d) =
    Dict.foldl (\_ set acc -> Set.size set + acc) 0 d


{-| Get all of the keys in a dictionary, sorted from lowest to highest.

    keys (fromList [ ( 0, "Alice" ), ( 1, "Bob" ) ]) == [ 0, 1 ]

-}
keys : MultiDict comparable1 comparable2 -> List comparable1
keys (MultiDict d) =
    Dict.keys d


{-| Get all of the values in a dictionary, in the order of their keys.

    values (fromList [ ( 0, "Alice" ), ( 1, "Bob" ) ]) == [ "Alice", "Bob" ]

-}
values : MultiDict comparable1 comparable2 -> List comparable2
values (MultiDict d) =
    Dict.values d
        |> List.concatMap Set.toList


{-| Convert a dictionary into an association list of key-value pairs, sorted by keys.
-}
toList : MultiDict comparable1 comparable2 -> List ( comparable1, Set comparable2 )
toList (MultiDict d) =
    Dict.toList d


{-| Convert an association list into a dictionary.
-}
fromList : List ( comparable1, Set comparable2 ) -> MultiDict comparable1 comparable2
fromList list =
    Dict.fromList list
        |> fromDict


{-| Convert an association list into a dictionary.

    fromFlatList
        [ ( "foo", 1 )
        , ( "bar", 2 )
        , ( "foo", 3 )
        ]

results in the same dict as

    fromList
        [ ( "foo", Set.fromList [ 1, 3 ] )
        , ( "bar", Set.fromList [ 2 ] )
        ]

-}
fromFlatList : List ( comparable1, comparable2 ) -> MultiDict comparable1 comparable2
fromFlatList list =
    list
        |> List.Extra.gatherEqualsBy Tuple.first
        |> List.map
            (\( ( key, _ ) as x, xs ) ->
                ( key
                , Set.fromList <| List.map Tuple.second <| x :: xs
                )
            )
        |> Dict.fromList
        |> fromDict


{-| Apply a function to all values in a dictionary.
-}
map : (comparable1 -> comparable21 -> comparable22) -> MultiDict comparable1 comparable21 -> MultiDict comparable1 comparable22
map fn (MultiDict d) =
    MultiDict <| Dict.map (\key set -> Set.map (fn key) set) d


{-| Convert MultiDict into a Dict. (Throw away the reverse mapping.)
-}
toDict : MultiDict comparable1 comparable2 -> Dict comparable1 (Set comparable2)
toDict (MultiDict d) =
    d


{-| Convert Dict into a MultiDict. (Compute the reverse mapping.)
-}
fromDict : Dict comparable1 (Set comparable2) -> MultiDict comparable1 comparable2
fromDict dict =
    MultiDict dict


{-| Fold over the key-value pairs in a dictionary from lowest key to highest key.


    getAges users =
        Dict.foldl addAge [] users

    addAge _ user ages =
        user.age :: ages

    -- getAges users == [33,19,28]

-}
foldl : (comparable1 -> Set comparable2 -> acc -> acc) -> acc -> MultiDict comparable1 comparable2 -> acc
foldl fn zero (MultiDict d) =
    Dict.foldl fn zero d


{-| Fold over the key-value pairs in a dictionary from highest key to lowest key.


    getAges users =
        Dict.foldr addAge [] users

    addAge _ user ages =
        user.age :: ages

    -- getAges users == [28,19,33]

-}
foldr : (comparable1 -> Set comparable2 -> acc -> acc) -> acc -> MultiDict comparable1 comparable2 -> acc
foldr fn zero (MultiDict d) =
    Dict.foldr fn zero d


{-| Keep only the mappings that pass the given test.
-}
filter : (comparable1 -> comparable2 -> Bool) -> MultiDict comparable1 comparable2 -> MultiDict comparable1 comparable2
filter fn (MultiDict d) =
    Dict.toList d
        |> List.filterMap
            (\( key, values_ ) ->
                values_
                    |> Set.filter (fn key)
                    |> normalizeSet
                    |> Maybe.map (Tuple.pair key)
            )
        |> fromList


{-| Partition a dictionary according to some test. The first dictionary
contains all key-value pairs which passed the test, and the second contains
the pairs that did not.
-}
partition : (comparable1 -> Set comparable2 -> Bool) -> MultiDict comparable1 comparable2 -> ( MultiDict comparable1 comparable2, MultiDict comparable1 comparable2 )
partition fn (MultiDict d) =
    let
        ( true, false ) =
            Dict.partition fn d
    in
    ( MultiDict true
    , MultiDict false
    )


{-| Combine two dictionaries. If there is a collision, preference is given
to the first dictionary.
-}
union : MultiDict comparable1 comparable2 -> MultiDict comparable1 comparable2 -> MultiDict comparable1 comparable2
union (MultiDict left) (MultiDict right) =
    MultiDict <| Dict.union left right


{-| Keep a key-value pair when its key appears in the second dictionary.
Preference is given to values in the first dictionary.
-}
intersect : MultiDict comparable1 comparable2 -> MultiDict comparable1 comparable2 -> MultiDict comparable1 comparable2
intersect (MultiDict left) (MultiDict right) =
    MultiDict <| Dict.intersect left right


{-| Keep a key-value pair when its key does not appear in the second dictionary.
-}
diff : MultiDict comparable1 comparable2 -> MultiDict comparable1 comparable2 -> MultiDict comparable1 comparable2
diff (MultiDict left) (MultiDict right) =
    MultiDict <| Dict.diff left right


{-| The most general way of combining two dictionaries. You provide three
accumulators for when a given key appears:

1.  Only in the left dictionary.
2.  In both dictionaries.
3.  Only in the right dictionary.

You then traverse all the keys from lowest to highest, building up whatever
you want.

-}
merge :
    (comparable1 -> Set comparable21 -> acc -> acc)
    -> (comparable1 -> Set comparable21 -> Set comparable22 -> acc -> acc)
    -> (comparable1 -> Set comparable22 -> acc -> acc)
    -> MultiDict comparable1 comparable21
    -> MultiDict comparable1 comparable22
    -> acc
    -> acc
merge fnLeft fnBoth fnRight (MultiDict left) (MultiDict right) zero =
    Dict.merge fnLeft fnBoth fnRight left right zero
