-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Backend.Scalar exposing (AuditAction(..), Codecs, Id(..), Map(..), ReconcilerName(..), RoleName(..), Slug(..), SystemName(..), Time(..), Uuid(..), defaultCodecs, defineCodecs, unwrapCodecs, unwrapEncoder)

import Graphql.Codec exposing (Codec)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type AuditAction
    = AuditAction String


type Id
    = Id String


type Map
    = Map String


type ReconcilerName
    = ReconcilerName String


type RoleName
    = RoleName String


type Slug
    = Slug String


type SystemName
    = SystemName String


type Time
    = Time String


type Uuid
    = Uuid String


defineCodecs :
    { codecAuditAction : Codec valueAuditAction
    , codecId : Codec valueId
    , codecMap : Codec valueMap
    , codecReconcilerName : Codec valueReconcilerName
    , codecRoleName : Codec valueRoleName
    , codecSlug : Codec valueSlug
    , codecSystemName : Codec valueSystemName
    , codecTime : Codec valueTime
    , codecUuid : Codec valueUuid
    }
    -> Codecs valueAuditAction valueId valueMap valueReconcilerName valueRoleName valueSlug valueSystemName valueTime valueUuid
defineCodecs definitions =
    Codecs definitions


unwrapCodecs :
    Codecs valueAuditAction valueId valueMap valueReconcilerName valueRoleName valueSlug valueSystemName valueTime valueUuid
    ->
        { codecAuditAction : Codec valueAuditAction
        , codecId : Codec valueId
        , codecMap : Codec valueMap
        , codecReconcilerName : Codec valueReconcilerName
        , codecRoleName : Codec valueRoleName
        , codecSlug : Codec valueSlug
        , codecSystemName : Codec valueSystemName
        , codecTime : Codec valueTime
        , codecUuid : Codec valueUuid
        }
unwrapCodecs (Codecs unwrappedCodecs) =
    unwrappedCodecs


unwrapEncoder :
    (RawCodecs valueAuditAction valueId valueMap valueReconcilerName valueRoleName valueSlug valueSystemName valueTime valueUuid -> Codec getterValue)
    -> Codecs valueAuditAction valueId valueMap valueReconcilerName valueRoleName valueSlug valueSystemName valueTime valueUuid
    -> getterValue
    -> Graphql.Internal.Encode.Value
unwrapEncoder getter (Codecs unwrappedCodecs) =
    (unwrappedCodecs |> getter |> .encoder) >> Graphql.Internal.Encode.fromJson


type Codecs valueAuditAction valueId valueMap valueReconcilerName valueRoleName valueSlug valueSystemName valueTime valueUuid
    = Codecs (RawCodecs valueAuditAction valueId valueMap valueReconcilerName valueRoleName valueSlug valueSystemName valueTime valueUuid)


type alias RawCodecs valueAuditAction valueId valueMap valueReconcilerName valueRoleName valueSlug valueSystemName valueTime valueUuid =
    { codecAuditAction : Codec valueAuditAction
    , codecId : Codec valueId
    , codecMap : Codec valueMap
    , codecReconcilerName : Codec valueReconcilerName
    , codecRoleName : Codec valueRoleName
    , codecSlug : Codec valueSlug
    , codecSystemName : Codec valueSystemName
    , codecTime : Codec valueTime
    , codecUuid : Codec valueUuid
    }


defaultCodecs : RawCodecs AuditAction Id Map ReconcilerName RoleName Slug SystemName Time Uuid
defaultCodecs =
    { codecAuditAction =
        { encoder = \(AuditAction raw) -> Encode.string raw
        , decoder = Object.scalarDecoder |> Decode.map AuditAction
        }
    , codecId =
        { encoder = \(Id raw) -> Encode.string raw
        , decoder = Object.scalarDecoder |> Decode.map Id
        }
    , codecMap =
        { encoder = \(Map raw) -> Encode.string raw
        , decoder = Object.scalarDecoder |> Decode.map Map
        }
    , codecReconcilerName =
        { encoder = \(ReconcilerName raw) -> Encode.string raw
        , decoder = Object.scalarDecoder |> Decode.map ReconcilerName
        }
    , codecRoleName =
        { encoder = \(RoleName raw) -> Encode.string raw
        , decoder = Object.scalarDecoder |> Decode.map RoleName
        }
    , codecSlug =
        { encoder = \(Slug raw) -> Encode.string raw
        , decoder = Object.scalarDecoder |> Decode.map Slug
        }
    , codecSystemName =
        { encoder = \(SystemName raw) -> Encode.string raw
        , decoder = Object.scalarDecoder |> Decode.map SystemName
        }
    , codecTime =
        { encoder = \(Time raw) -> Encode.string raw
        , decoder = Object.scalarDecoder |> Decode.map Time
        }
    , codecUuid =
        { encoder = \(Uuid raw) -> Encode.string raw
        , decoder = Object.scalarDecoder |> Decode.map Uuid
        }
    }
