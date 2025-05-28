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
    "5602c97d-28a5-4823-a487-d93e6915bb93"


isProduction_ : String
isProduction_ =
    "False"


isProduction : Bool
isProduction =
    isProduction_ == "True"
