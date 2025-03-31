module MultiBiDict.Assoc2 exposing
    ( MultiBiDict
    , toDict, fromDict, getReverse, uniqueValues, uniqueValuesCount, toReverseList
    , empty, singleton, insert, update, remove, removeAll
    , isEmpty, member, get, size
    , keys, values, toList, fromList
    , map, foldl, foldr, filter, partition
    , union, intersect, diff, merge
    )

{-| A dictionary mapping unique keys to **multiple** values, which
**maintains a mapping from the values back to keys,** allowing for
modelling **many-to-many relationships.**

Example usage:

    manyToMany : MultiBiDict String Int
    manyToMany =
        MultiBiDict.empty
            |> MultiBiDict.insert "A" 1
            |> MultiBiDict.insert "B" 2
            |> MultiBiDict.insert "C" 3
            |> MultiBiDict.insert "A" 2

    MultiBiDict.get "A" manyToMany
    --> Set.fromList [1, 2]

    MultiBiDict.getReverse 2 manyToMany
    --> Set.fromList ["A", "B"]

This module in particular uses [`assoc-list`](https://package.elm-lang.org/packages/pzp1997/assoc-list/latest/) and [`assoc-set`](https://package.elm-lang.org/packages/erlandsona/assoc-set/latest/)
under the hood to get rid of the `comparable` constraint on keys that's usually
associated with Dicts and Sets.


# Dictionaries

@docs MultiBiDict


# Differences from Dict

@docs toDict, fromDict, getReverse, uniqueValues, uniqueValuesCount, toReverseList


# Build

@docs empty, singleton, insert, update, remove, removeAll


# Query

@docs isEmpty, member, get, size


# Lists

@docs keys, values, toList, fromList


# Transform

@docs map, foldl, foldr, filter, partition


# Combine

@docs union, intersect, diff, merge

-}

import SeqDict as Dict exposing (Dict)
import SeqDict.Extra as DictExtra
import SeqSet as Set exposing (Set)


{-| The underlying data structure. Think about it as

    type alias MultiBiDict a b =
        { forward : Dict a (Set b) -- just a normal Dict!
        , reverse : Dict b (Set a) -- the reverse mappings!
        }

-}
type MultiBiDict a b
    = MultiBiDict
        { forward : Dict a (Set b)
        , reverse : Dict b (Set a)
        }


{-| Create an empty dictionary.
-}
empty : MultiBiDict a b
empty =
    MultiBiDict
        { forward = Dict.empty
        , reverse = Dict.empty
        }


{-| Create a dictionary with one key-value pair.
-}
singleton : a -> b -> MultiBiDict a b
singleton from to =
    MultiBiDict
        { forward = Dict.singleton from (Set.singleton to)
        , reverse = Dict.singleton to (Set.singleton from)
        }


{-| Insert a key-value pair into a dictionary. Replaces value when there is
a collision.
-}
insert : a -> b -> MultiBiDict a b -> MultiBiDict a b
insert from to (MultiBiDict d) =
    Dict.update
        from
        (\maybeSet ->
            case maybeSet of
                Nothing ->
                    Just (Set.singleton to)

                Just set ->
                    Just (Set.insert to set)
        )
        d.forward
        |> fromDict


{-| Update the value of a dictionary for a specific key with a given function.
-}
update : a -> (Set b -> Set b) -> MultiBiDict a b -> MultiBiDict a b
update from fn (MultiBiDict d) =
    Dict.update from (Maybe.map fn) d.forward
        |> fromDict


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
removeAll : a -> MultiBiDict a b -> MultiBiDict a b
removeAll from (MultiBiDict d) =
    MultiBiDict
        { d
            | forward = Dict.remove from d.forward
            , reverse = DictExtra.filterMap (\_ set -> Set.remove from set |> normalizeSet) d.reverse
        }


{-| Remove a single key-value pair from a dictionary. If the key is not found,
no changes are made.
-}
remove : a -> b -> MultiBiDict a b -> MultiBiDict a b
remove from to (MultiBiDict d) =
    Dict.update from (Maybe.andThen (Set.remove to >> normalizeSet)) d.forward
        |> fromDict


{-| Determine if a dictionary is empty.

    isEmpty empty == True

-}
isEmpty : MultiBiDict a b -> Bool
isEmpty (MultiBiDict d) =
    Dict.isEmpty d.forward


{-| Determine if a key is in a dictionary.
-}
member : a -> MultiBiDict a b -> Bool
member from (MultiBiDict d) =
    Dict.member from d.forward


{-| Get the value associated with a key. If the key is not found, return
`Nothing`. This is useful when you are not sure if a key will be in the
dictionary.

    animals = fromList [ ("Tom", Cat), ("Jerry", Mouse) ]

    get "Tom"   animals == Just Cat
    get "Jerry" animals == Just Mouse
    get "Spike" animals == Nothing

-}
get : a -> MultiBiDict a b -> Set b
get from (MultiBiDict d) =
    Dict.get from d.forward
        |> Maybe.withDefault Set.empty


{-| Get the keys associated with a value. If the value is not found,
return an empty set.
-}
getReverse : b -> MultiBiDict a b -> Set a
getReverse to (MultiBiDict d) =
    Dict.get to d.reverse
        |> Maybe.withDefault Set.empty


{-| Determine the number of key-value pairs in the dictionary.
-}
size : MultiBiDict a b -> Int
size (MultiBiDict d) =
    Dict.foldl (\_ set acc -> Set.size set + acc) 0 d.forward


{-| Get all of the keys in a dictionary, sorted from lowest to highest.

    keys (fromList [ ( 0, "Alice" ), ( 1, "Bob" ) ]) == [ 0, 1 ]

-}
keys : MultiBiDict a b -> List a
keys (MultiBiDict d) =
    Dict.keys d.forward


{-| Get all of the values in a dictionary, in the order of their keys.

    values (fromList [ ( 0, "Alice" ), ( 1, "Bob" ) ]) == [ "Alice", "Bob" ]

-}
values : MultiBiDict a b -> List b
values (MultiBiDict d) =
    Dict.values d.forward
        |> List.concatMap Set.toList


{-| Get a list of unique values in the dictionary.
-}
uniqueValues : MultiBiDict a b -> List b
uniqueValues (MultiBiDict d) =
    Dict.keys d.reverse


{-| Get a count of unique values in the dictionary.
-}
uniqueValuesCount : MultiBiDict a b -> Int
uniqueValuesCount (MultiBiDict d) =
    Dict.size d.reverse


{-| Convert a dictionary into an association list of key-value pairs, sorted by keys.
-}
toList : MultiBiDict a b -> List ( a, Set b )
toList (MultiBiDict d) =
    Dict.toList d.forward


{-| Convert a dictionary into a reverse association list of value-keys pairs.
-}
toReverseList : MultiBiDict a b -> List ( b, Set a )
toReverseList (MultiBiDict d) =
    Dict.toList d.reverse


{-| Convert an association list into a dictionary.
-}
fromList : List ( a, Set b ) -> MultiBiDict a b
fromList list =
    Dict.fromList list
        |> fromDict


{-| Apply a function to all values in a dictionary.
-}
map : (a -> b1 -> b2) -> MultiBiDict a b1 -> MultiBiDict a b2
map fn (MultiBiDict d) =
    -- TODO diff instead of throwing away and creating from scratch?
    Dict.map (\key set -> Set.map (fn key) set) d.forward
        |> fromDict


{-| Convert MultiBiDict into a Dict. (Throw away the reverse mapping.)
-}
toDict : MultiBiDict a b -> Dict a (Set b)
toDict (MultiBiDict d) =
    d.forward


{-| Convert Dict into a MultiBiDict. (Compute the reverse mapping.)
-}
fromDict : Dict a (Set b) -> MultiBiDict a b
fromDict forward =
    MultiBiDict
        { forward = forward
        , reverse =
            Dict.foldl
                (\key set acc ->
                    Set.foldl
                        (\value acc_ ->
                            Dict.update
                                value
                                (\maybeSet ->
                                    case maybeSet of
                                        Nothing ->
                                            Just (Set.singleton key)

                                        Just set_ ->
                                            Just (Set.insert key set_)
                                )
                                acc_
                        )
                        acc
                        set
                )
                Dict.empty
                forward
        }


{-| Fold over the key-value pairs in a dictionary from lowest key to highest key.


    getAges users =
        Dict.foldl addAge [] users

    addAge _ user ages =
        user.age :: ages

    -- getAges users == [33,19,28]

-}
foldl : (a -> Set b -> acc -> acc) -> acc -> MultiBiDict a b -> acc
foldl fn zero (MultiBiDict d) =
    Dict.foldl fn zero d.forward


{-| Fold over the key-value pairs in a dictionary from highest key to lowest key.


    getAges users =
        Dict.foldr addAge [] users

    addAge _ user ages =
        user.age :: ages

    -- getAges users == [28,19,33]

-}
foldr : (a -> Set b -> acc -> acc) -> acc -> MultiBiDict a b -> acc
foldr fn zero (MultiBiDict d) =
    Dict.foldr fn zero d.forward


{-| Keep only the mappings that pass the given test.
-}
filter : (a -> b -> Bool) -> MultiBiDict a b -> MultiBiDict a b
filter fn (MultiBiDict d) =
    Dict.toList d.forward
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
partition : (a -> Set b -> Bool) -> MultiBiDict a b -> ( MultiBiDict a b, MultiBiDict a b )
partition fn (MultiBiDict d) =
    -- TODO diff instead of throwing away and creating from scratch?
    let
        ( forwardTrue, forwardFalse ) =
            Dict.partition fn d.forward
    in
    ( fromDict forwardTrue
    , fromDict forwardFalse
    )


{-| Combine two dictionaries. If there is a collision, preference is given
to the first dictionary.
-}
union : MultiBiDict a b -> MultiBiDict a b -> MultiBiDict a b
union (MultiBiDict left) (MultiBiDict right) =
    -- TODO diff instead of throwing away and creating from scratch?
    Dict.union left.forward right.forward
        |> fromDict


{-| Keep a key-value pair when its key appears in the second dictionary.
Preference is given to values in the first dictionary.
-}
intersect : MultiBiDict a b -> MultiBiDict a b -> MultiBiDict a b
intersect (MultiBiDict left) (MultiBiDict right) =
    -- TODO diff instead of throwing away and creating from scratch?
    Dict.intersect left.forward right.forward
        |> fromDict


{-| Keep a key-value pair when its key does not appear in the second dictionary.
-}
diff : MultiBiDict a b -> MultiBiDict a b -> MultiBiDict a b
diff (MultiBiDict left) (MultiBiDict right) =
    -- TODO diff instead of throwing away and creating from scratch?
    Dict.diff left.forward right.forward
        |> fromDict


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
    -> MultiBiDict a b1
    -> MultiBiDict a b2
    -> acc
    -> acc
merge fnLeft fnBoth fnRight (MultiBiDict left) (MultiBiDict right) zero =
    Dict.merge fnLeft fnBoth fnRight left.forward right.forward zero
