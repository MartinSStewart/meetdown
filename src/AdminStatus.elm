module AdminStatus exposing (..)


type AdminStatus
    = IsNotAdmin
    | IsAdminButDisabled
    | IsAdminAndEnabled


isAdmin : AdminStatus -> Bool
isAdmin adminStatus =
    case adminStatus of
        IsNotAdmin ->
            False

        IsAdminButDisabled ->
            True

        IsAdminAndEnabled ->
            True


isAdminEnabled : AdminStatus -> Bool
isAdminEnabled adminStatus =
    case adminStatus of
        IsNotAdmin ->
            False

        IsAdminButDisabled ->
            False

        IsAdminAndEnabled ->
            True
