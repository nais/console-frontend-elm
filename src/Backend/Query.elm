-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module Backend.Query exposing (..)

import Backend.InputObject
import Backend.Interface
import Backend.Object
import Backend.Scalar
import Backend.ScalarCodecs
import Backend.Union
import Graphql.Internal.Builder.Argument as Argument exposing (Argument)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode as Encode exposing (Value)
import Graphql.Operation exposing (RootMutation, RootQuery, RootSubscription)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Json.Decode as Decode exposing (Decoder)


{-| The currently authenticated user.
-}
me :
    SelectionSet decodesTo Backend.Union.AuthenticatedUser
    -> SelectionSet decodesTo RootQuery
me object____ =
    Object.selectionForCompositeField "me" [] object____ Basics.identity


{-| Get a collection of reconcilers.
-}
reconcilers :
    SelectionSet decodesTo Backend.Object.Reconciler
    -> SelectionSet (List decodesTo) RootQuery
reconcilers object____ =
    Object.selectionForCompositeField "reconcilers" [] object____ (Basics.identity >> Decode.list)


{-| List all roles.
-}
roles : SelectionSet (List Backend.ScalarCodecs.RoleName) RootQuery
roles =
    Object.selectionForField "(List ScalarCodecs.RoleName)" "roles" [] (Backend.ScalarCodecs.codecs |> Backend.Scalar.unwrapCodecs |> .codecRoleName |> .decoder |> Decode.list)


{-| Get a collection of teams.
-}
teams :
    SelectionSet decodesTo Backend.Object.Team
    -> SelectionSet (List decodesTo) RootQuery
teams object____ =
    Object.selectionForCompositeField "teams" [] object____ (Basics.identity >> Decode.list)


type alias TeamRequiredArguments =
    { slug : Backend.ScalarCodecs.Slug }


{-| Get a specific team.

  - slug - Slug of the team.

-}
team :
    TeamRequiredArguments
    -> SelectionSet decodesTo Backend.Object.Team
    -> SelectionSet decodesTo RootQuery
team requiredArgs____ object____ =
    Object.selectionForCompositeField "team" [ Argument.required "slug" requiredArgs____.slug (Backend.ScalarCodecs.codecs |> Backend.Scalar.unwrapEncoder .codecSlug) ] object____ Basics.identity


type alias DeployKeyRequiredArguments =
    { slug : Backend.ScalarCodecs.Slug }


{-| Get deploy key for specific team.

  - slug - Slug of the team.

-}
deployKey :
    DeployKeyRequiredArguments
    -> SelectionSet Backend.ScalarCodecs.DeployKey RootQuery
deployKey requiredArgs____ =
    Object.selectionForField "ScalarCodecs.DeployKey" "deployKey" [ Argument.required "slug" requiredArgs____.slug (Backend.ScalarCodecs.codecs |> Backend.Scalar.unwrapEncoder .codecSlug) ] (Backend.ScalarCodecs.codecs |> Backend.Scalar.unwrapCodecs |> .codecDeployKey |> .decoder)


type alias TeamDeleteKeyRequiredArguments =
    { key : Backend.ScalarCodecs.Uuid }


{-| Get a team delete key.

  - key - The key to get.

-}
teamDeleteKey :
    TeamDeleteKeyRequiredArguments
    -> SelectionSet decodesTo Backend.Object.TeamDeleteKey
    -> SelectionSet decodesTo RootQuery
teamDeleteKey requiredArgs____ object____ =
    Object.selectionForCompositeField "teamDeleteKey" [ Argument.required "key" requiredArgs____.key (Backend.ScalarCodecs.codecs |> Backend.Scalar.unwrapEncoder .codecUuid) ] object____ Basics.identity


{-| Get a collection of users, sorted by name.
-}
users :
    SelectionSet decodesTo Backend.Object.User
    -> SelectionSet (List decodesTo) RootQuery
users object____ =
    Object.selectionForCompositeField "users" [] object____ (Basics.identity >> Decode.list)


type alias UserRequiredArguments =
    { id : Backend.ScalarCodecs.Uuid }


{-| Get a specific user.

  - id - ID of the user.

-}
user :
    UserRequiredArguments
    -> SelectionSet decodesTo Backend.Object.User
    -> SelectionSet decodesTo RootQuery
user requiredArgs____ object____ =
    Object.selectionForCompositeField "user" [ Argument.required "id" requiredArgs____.id (Backend.ScalarCodecs.codecs |> Backend.Scalar.unwrapEncoder .codecUuid) ] object____ Basics.identity


type alias UserByEmailRequiredArguments =
    { email : String }


{-| Get a specific user by email.

  - email - ID of the user.

-}
userByEmail :
    UserByEmailRequiredArguments
    -> SelectionSet decodesTo Backend.Object.User
    -> SelectionSet decodesTo RootQuery
userByEmail requiredArgs____ object____ =
    Object.selectionForCompositeField "userByEmail" [ Argument.required "email" requiredArgs____.email Encode.string ] object____ Basics.identity


{-| Get user sync status and logs.
-}
userSync :
    SelectionSet decodesTo Backend.Object.UserSyncRun
    -> SelectionSet (List decodesTo) RootQuery
userSync object____ =
    Object.selectionForCompositeField "userSync" [] object____ (Basics.identity >> Decode.list)
