module Env exposing (..)


sendGridApiKey_ : String
sendGridApiKey_ =
    ""


adminEmailAddress : String
adminEmailAddress =
    "a@a.se"


contactEmailAddress : String
contactEmailAddress =
    "contact+email@email.com"


secretKey : String
secretKey =
    "123"


domain : String
domain =
    "http://localhost:8000"


postmarkServerToken : String
postmarkServerToken =
    ""


isProduction_ : String
isProduction_ =
    "False"


isProduction : Bool
isProduction =
    isProduction_ == "True"
