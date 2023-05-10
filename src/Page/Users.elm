module Page.Users exposing (Model, Msg(..), init, update, view)

import Api.Do exposing (mutateRD)
import Api.Error
import Api.Str exposing (uuidStr)
import Api.User
import Backend.Enum.UserSyncRunStatus exposing (UserSyncRunStatus)
import Backend.Mutation as Mutation
import Backend.Scalar exposing (RoleName(..), Slug(..), Uuid)
import Component.Buttons exposing (smallButton)
import DataModel exposing (AuditLog, Role, User, UserSyncRun)
import Graphql.Http
import Graphql.Operation exposing (RootMutation)
import Graphql.SelectionSet exposing (SelectionSet)
import Html exposing (Html, b, dd, div, dl, dt, h2, i, input, p, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (class, disabled, type_, value)
import ISO8601
import Page.Team exposing (copy)
import RemoteData exposing (RemoteData(..))
import Session exposing (Session)


type alias Model =
    { session : Session
    , error : Maybe String
    , users : RemoteData (Graphql.Http.Error (List User)) (List User)
    , userSyncRuns : RemoteData (Graphql.Http.Error (List UserSyncRun)) (List UserSyncRun)
    , synchronizeUsersCorrelationID : RemoteData (Graphql.Http.Error Uuid) Uuid
    }


type Msg
    = GotUsers (RemoteData (Graphql.Http.Error (List User)) (List User))
    | GotUserSyncRuns (RemoteData (Graphql.Http.Error (List UserSyncRun)) (List UserSyncRun))
    | Copy String
    | GotSynchronizeUsersResponse (RemoteData (Graphql.Http.Error Uuid) Uuid)
    | SynchronizeUsersClicked


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , error = Nothing
      , users = Loading
      , userSyncRuns = Loading
      , synchronizeUsersCorrelationID = NotAsked
      }
    , Cmd.batch [ getUsers, getUserSyncRuns ]
    )


getUsers : Cmd Msg
getUsers =
    Api.Do.queryRD Api.User.getAllUsersWithRoles GotUsers


getUserSyncRuns : Cmd Msg
getUserSyncRuns =
    Api.Do.queryRD Api.User.getAllUserSyncRuns GotUserSyncRuns


view : Model -> Html Msg
view model =
    case model.users of
        Loading ->
            p [] [ text "loading" ]

        Success users ->
            div [ class "cards" ]
                [ viewAdminActions model.synchronizeUsersCorrelationID
                , viewUserSyncRuns model.userSyncRuns
                , div [ class "card" ]
                    [ div [ class "title" ]
                        [ h2 [] [ text "Users" ]
                        ]
                    , table []
                        [ thead []
                            [ tr []
                                [ th [] [ text "Full name" ]
                                , th [] [ text "Email" ]
                                , th [] [ text "External ID" ]
                                , th [] [ text "Roles" ]
                                ]
                            ]
                        , tbody [] (List.map viewUser users)
                        ]
                    ]
                ]

        NotAsked ->
            p [] [ text "NotAsked" ]

        Failure f ->
            p [] [ text (f |> Api.Error.errorToString) ]


viewAdminActions : RemoteData (Graphql.Http.Error Uuid) Uuid -> Html Msg
viewAdminActions synchronizeUsersCorrelationID =
    div [ class "card" ]
        [ div [ class "title" ]
            [ h2 [] [ text "Admin actions" ]
            , smallButton SynchronizeUsersClicked "synchronize" "Synchronize users"
            ]
        , div []
            (case synchronizeUsersCorrelationID of
                Success uuid ->
                    [ text "User sync triggered. Correlation ID: "
                    , input [ type_ "text", class "synchronizeUsersCorrelationID", disabled True, value (uuidStr uuid) ] []
                    , smallButton (Copy (uuidStr uuid)) "copy" "copy"
                    ]

                _ ->
                    [ text "" ]
            )
        ]


viewUserSyncRuns : RemoteData (Graphql.Http.Error (List UserSyncRun)) (List UserSyncRun) -> Html Msg
viewUserSyncRuns userSyncRuns =
    div [ class "card" ]
        [ div [ class "title" ]
            [ h2 [] [ text "User sync logs" ]
            ]
        , div []
            (case userSyncRuns of
                Success runs ->
                    if List.isEmpty runs then
                        [ p [] [ text "There have been no user sync runs since the backend started. Trigger a user sync by clicking on the Synchronize users button above." ] ]

                    else
                        List.map viewUserSyncRun runs

                Loading ->
                    [ text "Loading" ]

                NotAsked ->
                    [ text "NotAsked" ]

                Failure f ->
                    [ text (f |> Api.Error.errorToString) ]
            )
        ]


viewUser : User -> Html Msg
viewUser user =
    tr []
        [ td [] [ text user.name ]
        , td [] [ text user.email ]
        , td [] [ text user.externalId ]
        , td [] [ viewRoleDatas user.roles ]
        ]


viewUserSyncRun : UserSyncRun -> Html Msg
viewUserSyncRun run =
    div [ class "user-sync-run" ]
        [ dl []
            ([ dt [] [ text "Correlation ID:" ]
             , dd [] [ b [] [ text (uuidStr run.correlationID) ] ]
             , dt [] [ text "Started at:" ]
             , dd [] [ text (ISO8601.toString run.startedAt) ]
             , dt [] [ text "Finished at:" ]
             , dd [] [ text (finishedAtToString run.finishedAt) ]
             , dt [] [ text "Status:" ]
             , dd [] [ text (syncStatusToString run.status) ]
             ]
                ++ viewSyncRunError run.error
            )
        , viewUserSyncRunLogEntries run.logEntries
        ]


finishedAtToString : Maybe ISO8601.Time -> String
finishedAtToString finishedAt =
    case finishedAt of
        Just t ->
            ISO8601.toString t

        Nothing ->
            "Not yet finished"


syncStatusToString : UserSyncRunStatus -> String
syncStatusToString status =
    case status of
        Backend.Enum.UserSyncRunStatus.InProgress ->
            "In progress"

        Backend.Enum.UserSyncRunStatus.Success ->
            "Finished"

        Backend.Enum.UserSyncRunStatus.Failure ->
            "Error"


viewSyncRunError : Maybe String -> List (Html Msg)
viewSyncRunError err =
    case err of
        Just msg ->
            [ dt [] [ text "Error message:" ]
            , dd [ class "server-error-message" ] [ text msg ]
            ]

        Nothing ->
            [ text "" ]


viewUserSyncRunLogEntries : List AuditLog -> Html Msg
viewUserSyncRunLogEntries logEntries =
    if List.isEmpty logEntries then
        p [] [ i [] [ text "No log entries exists for this run. This means that there was no changes to be made to the user database, or that the run failed (see potential error message above)." ] ]

    else
        table []
            [ thead []
                [ tr []
                    [ th [] [ text "Created at" ]
                    , th [] [ text "Message" ]
                    ]
                ]
            , tbody [] (List.map viewAuditLogEntry logEntries)
            ]


viewAuditLogEntry : AuditLog -> Html Msg
viewAuditLogEntry entry =
    tr []
        [ td [] [ text (ISO8601.toString entry.createdAt) ]
        , td [] [ text entry.message ]
        ]


roleNameToString : RoleName -> String
roleNameToString (RoleName s) =
    s


slugToString : Slug -> String
slugToString (Slug s) =
    s


viewRoleData : Role -> Html Msg
viewRoleData r =
    tr []
        [ td [] [ text (roleNameToString r.name) ]
        , td []
            [ text
                (if r.isGlobal then
                    "global"

                 else
                    case r.targetTeamSlug of
                        Just slug ->
                            slugToString slug

                        Nothing ->
                            "no target slug - bug?"
                )
            ]
        ]


viewRoleDatas : List Role -> Html Msg
viewRoleDatas roleDatas =
    table [] [ tbody [] (List.map viewRoleData roleDatas) ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotUserSyncRuns r ->
            ( { model | userSyncRuns = r }, Cmd.none )

        GotUsers r ->
            ( { model | users = r }, Cmd.none )

        GotSynchronizeUsersResponse r ->
            ( { model | synchronizeUsersCorrelationID = r }, Cmd.none )

        SynchronizeUsersClicked ->
            ( model, mutateRD synchronizeUsers GotSynchronizeUsersResponse )

        Copy s ->
            ( model, copy s )


synchronizeUsers : SelectionSet Uuid RootMutation
synchronizeUsers =
    Mutation.synchronizeUsers
