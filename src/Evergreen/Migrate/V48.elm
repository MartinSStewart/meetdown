module Evergreen.Migrate.V48 exposing (..)

import Evergreen.V46.Types as Old
import Evergreen.V48.Types as New
import Lamdera.Migrations exposing (..)


frontendModel : Old.FrontendModel -> ModelMigration New.FrontendModel New.FrontendMsg
frontendModel old =
    Unimplemented


backendModel : Old.BackendModel -> ModelMigration New.BackendModel New.BackendMsg
backendModel old =
    Unimplemented


frontendMsg : Old.FrontendMsg -> MsgMigration New.FrontendMsg New.FrontendMsg
frontendMsg old =
    Unimplemented


toBackend : Old.ToBackend -> MsgMigration New.ToBackend New.BackendMsg
toBackend old =
    Unimplemented


backendMsg : Old.BackendMsg -> MsgMigration New.BackendMsg New.BackendMsg
backendMsg old =
    MsgUnchanged


toFrontend : Old.ToFrontend -> MsgMigration New.ToFrontend New.FrontendMsg
toFrontend old =
    Unimplemented