module Evergreen.Migrate.V26 exposing (..)

import Array
import AssocList as Dict
import AssocSet as Set
import BiDict.Assoc as BiDict
import Evergreen.V25.Address
import Evergreen.V25.Description
import Evergreen.V25.Event
import Evergreen.V25.EventDuration
import Evergreen.V25.EventName
import Evergreen.V25.Group
import Evergreen.V25.GroupName
import Evergreen.V25.Id
import Evergreen.V25.Link
import Evergreen.V25.MaxAttendees
import Evergreen.V25.Name
import Evergreen.V25.ProfileImage
import Evergreen.V25.Route
import Evergreen.V25.Types as Old
import Evergreen.V25.Untrusted
import Evergreen.V26.Address
import Evergreen.V26.Description
import Evergreen.V26.Event
import Evergreen.V26.EventDuration
import Evergreen.V26.EventName
import Evergreen.V26.Group
import Evergreen.V26.GroupName
import Evergreen.V26.Id
import Evergreen.V26.Link
import Evergreen.V26.MaxAttendees
import Evergreen.V26.Name
import Evergreen.V26.ProfileImage
import Evergreen.V26.Route
import Evergreen.V26.Types as New
import Evergreen.V26.Untrusted
import Lamdera.Migrations exposing (..)
import List.Nonempty


frontendModel : Old.FrontendModel -> ModelMigration New.FrontendModel New.FrontendMsg
frontendModel old =
    ModelUnchanged


backendModel : Old.BackendModel -> ModelMigration New.BackendModel New.BackendMsg
backendModel old =
    -- @NOTE neutered old migration to support vendoring send-grid:EmailAddress.EmailAddress in v27
    ModelUnchanged


frontendMsg : Old.FrontendMsg -> MsgMigration New.FrontendMsg New.FrontendMsg
frontendMsg old =
    MsgUnchanged


toBackend : Old.ToBackend -> MsgMigration New.ToBackend New.BackendMsg
toBackend old =
    -- @NOTE neutered old migration to support vendoring send-grid:EmailAddress.EmailAddress in v27
    MsgOldValueIgnored


backendMsg : Old.BackendMsg -> MsgMigration New.BackendMsg New.BackendMsg
backendMsg old =
    MsgUnchanged


toFrontend : Old.ToFrontend -> MsgMigration New.ToFrontend New.FrontendMsg
toFrontend old =
    MsgUnchanged
