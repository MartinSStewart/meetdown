module BiDict exposing
    ( BiDict
    , toDict, fromDict, getReverse, uniqueValues, uniqueValuesCount, toReverseList
    , empty, singleton, insert, update, remove
    , isEmpty, member, get, size
    , keys, values, toList, fromList
    , map, foldl, foldr, filter, partition
    , union, intersect, diff, merge
    )

{-| A dictionary that **maintains a mapping from the values back to keys,**
allowing for modelling **many-to-one relationships.**

Example usage:

    manyToOne : BiDict String Int
    manyToOne =
        BiDict.empty
            |> BiDict.insert "A" 1
            |> BiDict.insert "B" 2
            |> BiDict.insert "C" 1
            |> BiDict.insert "D" 4

    BiDict.getReverse 1 manyToOne
    --> Set.fromList ["A", "C"]


# Dictionaries

@docs BiDict


# Differences from Dict

@docs toDict, fromDict, getReverse, uniqueValues, uniqueValuesCount, toReverseList


# Build

@docs empty, singleton, insert, update, remove


# Query

@docs isEmpty, member, get, size


# Lists

@docs keys, values, toList, fromList


# Transform

@docs map, foldl, foldr, filter, partition


# Combine

@docs union, intersect, diff, merge

-}

import Dict exposing (Dict)
import Dict.Extra
import Set exposing (Set)


{-| The underlying data structure. Think about it as

    type alias BiDict a b =
        { forward : Dict a b -- just a normal Dict!
        , reverse : Dict b (Set a) -- the reverse mappings!
        }

-}
type BiDict comparable1 comparable2
    = BiDict
        { forward : Dict comparable1 comparable2
        , reverse : Dict comparable2 (Set comparable1)
        }


{-| Create an empty dictionary.
-}
empty : BiDict comparable1 comparable2
empty =
    BiDict
        { forward = Dict.empty
        , reverse = Dict.empty
        }


{-| Create a dictionary with one key-value pair.
-}
singleton : comparable1 -> comparable2 -> BiDict comparable1 comparable2
singleton from to =
    BiDict
        { forward = Dict.singleton from to
        , reverse = Dict.singleton to (Set.singleton from)
        }


{-| Insert a key-value pair into a dictionary. Replaces value when there is
a collision.
-}
insert : comparable1 -> comparable2 -> BiDict comparable1 comparable2 -> BiDict comparable1 comparable2
insert from to (BiDict d) =
    BiDict
        { d
            | forward = Dict.insert from to d.forward
            , reverse =
                let
                    oldTo =
                        Dict.get from d.forward

                    reverseWithoutOld =
                        case oldTo of
                            Nothing ->
                                d.reverse

                            Just oldTo_ ->
                                d.reverse
                                    |> Dict.update oldTo_
                                        (Maybe.map (Set.remove from)
                                            >> Maybe.andThen normalizeSet
                                        )
                in
                reverseWithoutOld
                    |> Dict.update to (Maybe.withDefault Set.empty >> Set.insert from >> Just)
        }


{-| Update the value of a dictionary for a specific key with a given function.
-}
update : comparable1 -> (Maybe comparable2 -> Maybe comparable2) -> BiDict comparable1 comparable2 -> BiDict comparable1 comparable2
update from fn (BiDict d) =
    Dict.update from fn d.forward
        |> fromDict


{-| In our model, (Just Set.empty) has the same meaning as Nothing.
Make it be Nothing!
-}
normalizeSet : Set comparable -> Maybe (Set comparable)
normalizeSet set =
    if Set.isEmpty set then
        Nothing

    else
        Just set


{-| Remove a key-value pair from a dictionary. If the key is not found,
no changes are made.
-}
remove : comparable1 -> BiDict comparable1 comparable2 -> BiDict comparable1 comparable2
remove from (BiDict d) =
    BiDict
        { d
            | forward = Dict.remove from d.forward
            , reverse = Dict.Extra.filterMap (\_ set -> Set.remove from set |> normalizeSet) d.reverse
        }


{-| Determine if a dictionary is empty.

    isEmpty empty == True

-}
isEmpty : BiDict comparable1 comparable2 -> Bool
isEmpty (BiDict d) =
    Dict.isEmpty d.forward


{-| Determine if a key is in a dictionary.
-}
member : comparable1 -> BiDict comparable1 comparable2 -> Bool
member from (BiDict d) =
    Dict.member from d.forward


{-| Get the value associated with a key. If the key is not found, return
`Nothing`. This is useful when you are not sure if a key will be in the
dictionary.

    animals = fromList [ ("Tom", Cat), ("Jerry", Mouse) ]

    get "Tom"   animals == Just Cat
    get "Jerry" animals == Just Mouse
    get "Spike" animals == Nothing

-}
get : comparable1 -> BiDict comparable1 comparable2 -> Maybe comparable2
get from (BiDict d) =
    Dict.get from d.forward


{-| Get the keys associated with a value. If the value is not found,
return an empty set.
-}
getReverse : comparable2 -> BiDict comparable1 comparable2 -> Set comparable1
getReverse to (BiDict d) =
    Dict.get to d.reverse
        |> Maybe.withDefault Set.empty


{-| Determine the number of key-value pairs in the dictionary.
-}
size : BiDict comparable1 comparable2 -> Int
size (BiDict d) =
    Dict.size d.forward


{-| Get all of the keys in a dictionary, sorted from lowest to highest.

    keys (fromList [ ( 0, "Alice" ), ( 1, "Bob" ) ]) == [ 0, 1 ]

-}
keys : BiDict comparable1 comparable2 -> List comparable1
keys (BiDict d) =
    Dict.keys d.forward


{-| Get all of the values in a dictionary, in the order of their keys.

    values (fromList [ ( 0, "Alice" ), ( 1, "Bob" ) ]) == [ "Alice", "Bob" ]

-}
values : BiDict comparable1 comparable2 -> List comparable2
values (BiDict d) =
    Dict.values d.forward


{-| Get a list of unique values in the dictionary.
-}
uniqueValues : BiDict comparable1 comparable2 -> List comparable2
uniqueValues (BiDict d) =
    Dict.keys d.reverse


{-| Get a count of unique values in the dictionary.
-}
uniqueValuesCount : BiDict comparable1 comparable2 -> Int
uniqueValuesCount (BiDict d) =
    Dict.size d.reverse


{-| Convert a dictionary into an association list of key-value pairs, sorted by keys.
-}
toList : BiDict comparable1 comparable2 -> List ( comparable1, comparable2 )
toList (BiDict d) =
    Dict.toList d.forward


{-| Convert a dictionary into a reverse association list of value-keys pairs.
-}
toReverseList : BiDict comparable1 comparable2 -> List ( comparable2, Set comparable1 )
toReverseList (BiDict d) =
    Dict.toList d.reverse


{-| Convert an association list into a dictionary.
-}
fromList : List ( comparable1, comparable2 ) -> BiDict comparable1 comparable2
fromList list =
    Dict.fromList list
        |> fromDict


{-| Apply a function to all values in a dictionary.
-}
map : (comparable1 -> comparable21 -> comparable22) -> BiDict comparable1 comparable21 -> BiDict comparable1 comparable22
map fn (BiDict d) =
    -- TODO diff instead of throwing away and creating from scratch?
    Dict.map fn d.forward
        |> fromDict


{-| Convert BiDict into a Dict. (Throw away the reverse mapping.)
-}
toDict : BiDict comparable1 comparable2 -> Dict comparable1 comparable2
toDict (BiDict d) =
    d.forward


{-| Convert Dict into a BiDict. (Compute the reverse mapping.)
-}
fromDict : Dict comparable1 comparable2 -> BiDict comparable1 comparable2
fromDict forward =
    BiDict
        { forward = forward
        , reverse =
            forward
                |> Dict.foldl
                    (\key value acc ->
                        Dict.update value
                            (\maybeKeys ->
                                Just <|
                                    case maybeKeys of
                                        Nothing ->
                                            Set.singleton key

                                        Just keys_ ->
                                            Set.insert key keys_
                            )
                            acc
                    )
                    Dict.empty
        }


{-| Fold over the key-value pairs in a dictionary from lowest key to highest key.


    getAges users =
        Dict.foldl addAge [] users

    addAge _ user ages =
        user.age :: ages

    -- getAges users == [33,19,28]

-}
foldl : (comparable1 -> comparable2 -> acc -> acc) -> acc -> BiDict comparable1 comparable2 -> acc
foldl fn zero (BiDict d) =
    Dict.foldl fn zero d.forward


{-| Fold over the key-value pairs in a dictionary from highest key to lowest key.


    getAges users =
        Dict.foldr addAge [] users

    addAge _ user ages =
        user.age :: ages

    -- getAges users == [28,19,33]

-}
foldr : (comparable1 -> comparable2 -> acc -> acc) -> acc -> BiDict comparable1 comparable2 -> acc
foldr fn zero (BiDict d) =
    Dict.foldr fn zero d.forward


{-| Keep only the key-value pairs that pass the given test.
-}
filter : (comparable1 -> comparable2 -> Bool) -> BiDict comparable1 comparable2 -> BiDict comparable1 comparable2
filter fn (BiDict d) =
    -- TODO diff instead of throwing away and creating from scratch?
    Dict.filter fn d.forward
        |> fromDict


{-| Partition a dictionary according to some test. The first dictionary
contains all key-value pairs which passed the test, and the second contains
the pairs that did not.
-}
partition : (comparable1 -> comparable2 -> Bool) -> BiDict comparable1 comparable2 -> ( BiDict comparable1 comparable2, BiDict comparable1 comparable2 )
partition fn (BiDict d) =
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
union : BiDict comparable1 comparable2 -> BiDict comparable1 comparable2 -> BiDict comparable1 comparable2
union (BiDict left) (BiDict right) =
    -- TODO diff instead of throwing away and creating from scratch?
    Dict.union left.forward right.forward
        |> fromDict


{-| Keep a key-value pair when its key appears in the second dictionary.
Preference is given to values in the first dictionary.
-}
intersect : BiDict comparable1 comparable2 -> BiDict comparable1 comparable2 -> BiDict comparable1 comparable2
intersect (BiDict left) (BiDict right) =
    -- TODO diff instead of throwing away and creating from scratch?
    Dict.intersect left.forward right.forward
        |> fromDict


{-| Keep a key-value pair when its key does not appear in the second dictionary.
-}
diff : BiDict comparable1 comparable2 -> BiDict comparable1 comparable2 -> BiDict comparable1 comparable2
diff (BiDict left) (BiDict right) =
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
    (comparable1 -> comparable21 -> acc -> acc)
    -> (comparable1 -> comparable21 -> comparable22 -> acc -> acc)
    -> (comparable1 -> comparable22 -> acc -> acc)
    -> BiDict comparable1 comparable21
    -> BiDict comparable1 comparable22
    -> acc
    -> acc
merge fnLeft fnBoth fnRight (BiDict left) (BiDict right) zero =
    Dict.merge fnLeft fnBoth fnRight left.forward right.forward zero
