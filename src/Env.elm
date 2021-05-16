module Env exposing (..)

import SendGrid


sendGridApiKey_ : String
sendGridApiKey_ =
    ""


sendGridApiKey : SendGrid.ApiKey
sendGridApiKey =
    SendGrid.apiKey sendGridApiKey_


adminUserId_ : String
adminUserId_ =
    "0"


secretKey : String
secretKey =
    "123"


domain : String
domain =
    "localhost:8000"
