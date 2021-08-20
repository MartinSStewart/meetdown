module Evergreen.V48.Effect.Browser.Dom exposing (..)


type Error
    = NotFound String


type alias Element =
    { scene :
        { width : Float
        , height : Float
        }
    , viewport :
        { x : Float
        , y : Float
        , width : Float
        , height : Float
        }
    , element :
        { x : Float
        , y : Float
        , width : Float
        , height : Float
        }
    }
