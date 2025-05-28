module Evergreen.V74.Postmark exposing (..)


type alias PostmarkSendResponse =
    { to : String
    , submittedAt : String
    , messageID : String
    , errorCode : Int
    , message : String
    }
