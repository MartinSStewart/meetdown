module MultiDict.Assoc exposing
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

This module in particular uses [`assoc-list`](https://package.elm-lang.org/packages/pzp1997/assoc-list/latest/) and [`assoc-set`](https://package.elm-lang.org/packages/erlandsona/assoc-set/latest/)
under the hood to get rid of the `comparable` constraint on keys that's usually
associated with Dicts and Sets.


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

import SeqDict as Dict exposing (Dict)
import SeqDict.Extra as DictExtra
import SeqSet as Set exposing (Set)


{-| The underlying data structure. Think about it as

     type alias MultiDict a b =
         Dict a (Set b) -- just a normal Dict!

-}
type MultiDict a b
    = MultiDict (Dict a (Set b))


{-| Create an empty dictionary.
-}
empty : MultiDict a b
empty =
    MultiDict Dict.empty


{-| Create a dictionary with one key-value pair.
-}
singleton : a -> b -> MultiDict a b
singleton from to =
    MultiDict (Dict.singleton from (Set.singleton to))


{-| Insert a key-value pair into a dictionary. Replaces value when there is
a collision.
-}
insert : a -> b -> MultiDict a b -> MultiDict a b
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
update : a -> (Set b -> Set b) -> MultiDict a b -> MultiDict a b
update from fn (MultiDict d) =
    MultiDict <| Dict.update from (Maybe.andThen (normalizeSet << fn)) d


{-| In our model, (Just Set.empty) has the same meaning as Nothing.
Make it be Nothing!
-}
normalizeSet : Set a -> Maybe (Set a)
normalizeSet set =
    if Set.isEmpty set then
        Nothing

    else
        Just set


{-| Remove all key-value pairs for the given key from a dictionary. If the key is
not found, no changes are made.
-}
removeAll : a -> MultiDict a b -> MultiDict a b
removeAll from (MultiDict d) =
    MultiDict (Dict.remove from d)


{-| Remove a single key-value pair from a dictionary. If the key is not found,
no changes are made.
-}
remove : a -> b -> MultiDict a b -> MultiDict a b
remove from to (MultiDict d) =
    MultiDict <| Dict.update from (Maybe.andThen (Set.remove to >> normalizeSet)) d


{-| Determine if a dictionary is empty.

    isEmpty empty == True

-}
isEmpty : MultiDict a b -> Bool
isEmpty (MultiDict d) =
    Dict.isEmpty d


{-| Determine if a key is in a dictionary.
-}
member : a -> MultiDict a b -> Bool
member from (MultiDict d) =
    Dict.member from d


{-| Get the value associated with a key. If the key is not found, return
`Nothing`. This is useful when you are not sure if a key will be in the
dictionary.

    animals = fromList [ ("Tom", Cat), ("Jerry", Mouse) ]

    get "Tom"   animals == SeqSet.singleton Cat
    get "Jerry" animals == SeqSet.singleton Mouse
    get "Spike" animals == SeqSet.empty

-}
get : a -> MultiDict a b -> Set b
get from (MultiDict d) =
    Dict.get from d
        |> Maybe.withDefault Set.empty


{-| Determine the number of key-value pairs in the dictionary.
-}
size : MultiDict a b -> Int
size (MultiDict d) =
    Dict.foldl (\_ set acc -> Set.size set + acc) 0 d


{-| Get all of the keys in a dictionary, sorted from lowest to highest.

    keys (fromList [ ( 0, "Alice" ), ( 1, "Bob" ) ]) == [ 0, 1 ]

-}
keys : MultiDict a b -> List a
keys (MultiDict d) =
    Dict.keys d


{-| Get all of the values in a dictionary, in the order of their keys.

    values (fromList [ ( 0, "Alice" ), ( 1, "Bob" ) ]) == [ "Alice", "Bob" ]

-}
values : MultiDict a b -> List b
values (MultiDict d) =
    Dict.values d
        |> List.concatMap Set.toList


{-| Convert a dictionary into an association list of key-value pairs, sorted by keys.
-}
toList : MultiDict a b -> List ( a, Set b )
toList (MultiDict d) =
    Dict.toList d


{-| Convert an association list into a dictionary.
-}
fromList : List ( a, Set b ) -> MultiDict a b
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
fromFlatList : List ( a, b ) -> MultiDict a b
fromFlatList list =
    List.foldl
        (\( k, v ) -> insert k v)
        empty
        list


{-| Apply a function to all values in a dictionary.
-}
map : (a -> b1 -> b2) -> MultiDict a b1 -> MultiDict a b2
map fn (MultiDict d) =
    MultiDict <| Dict.map (\key set -> Set.map (fn key) set) d


{-| Convert MultiDict into a Dict. (Throw away the reverse mapping.)
-}
toDict : MultiDict a b -> Dict a (Set b)
toDict (MultiDict d) =
    d


{-| Convert Dict into a MultiDict. (Compute the reverse mapping.)
-}
fromDict : Dict a (Set b) -> MultiDict a b
fromDict dict =
    MultiDict dict


{-| Fold over the key-value pairs in a dictionary from lowest key to highest key.


    getAges users =
        Dict.foldl addAge [] users

    addAge _ user ages =
        user.age :: ages

    -- getAges users == [33,19,28]

-}
foldl : (a -> Set b -> acc -> acc) -> acc -> MultiDict a b -> acc
foldl fn zero (MultiDict d) =
    Dict.foldl fn zero d


{-| Fold over the key-value pairs in a dictionary from highest key to lowest key.


    getAges users =
        Dict.foldr addAge [] users

    addAge _ user ages =
        user.age :: ages

    -- getAges users == [28,19,33]

-}
foldr : (a -> Set b -> acc -> acc) -> acc -> MultiDict a b -> acc
foldr fn zero (MultiDict d) =
    Dict.foldr fn zero d


{-| Keep only the mappings that pass the given test.
-}
filter : (a -> b -> Bool) -> MultiDict a b -> MultiDict a b
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
partition : (a -> Set b -> Bool) -> MultiDict a b -> ( MultiDict a b, MultiDict a b )
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
union : MultiDict a b -> MultiDict a b -> MultiDict a b
union (MultiDict left) (MultiDict right) =
    MultiDict <| Dict.union left right


{-| Keep a key-value pair when its key appears in the second dictionary.
Preference is given to values in the first dictionary.
-}
intersect : MultiDict a b -> MultiDict a b -> MultiDict a b
intersect (MultiDict left) (MultiDict right) =
    MultiDict <| Dict.intersect left right


{-| Keep a key-value pair when its key does not appear in the second dictionary.
-}
diff : MultiDict a b -> MultiDict a b -> MultiDict a b
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
    (a -> Set b1 -> acc -> acc)
    -> (a -> Set b1 -> Set b2 -> acc -> acc)
    -> (a -> Set b2 -> acc -> acc)
    -> MultiDict a b1
    -> MultiDict a b2
    -> acc
    -> acc
merge fnLeft fnBoth fnRight (MultiDict left) (MultiDict right) zero =
    Dict.merge fnLeft fnBoth fnRight left right zero
