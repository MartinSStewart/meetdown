module Evergreen.V68.Postmark exposing (..)


type alias PostmarkSendResponse =
    { to : String
    , submittedAt : String
    , messageID : String
    , errorCode : Int
    , message : String
    }
