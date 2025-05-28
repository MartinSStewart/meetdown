module Evergreen.V74.BiDict.Assoc2 exposing (..)

import SeqDict
import SeqSet


type BiDict a b
    = BiDict
        { forward : SeqDict.SeqDict a b
        , reverse : SeqDict.SeqDict b (SeqSet.SeqSet a)
        }
