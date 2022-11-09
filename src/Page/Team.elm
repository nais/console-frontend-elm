module Page.Team exposing (..)

import Api.Do exposing (query)
import Api.Error exposing (errorToString)
import Api.Team exposing (AuditLogData, KeyValueData, SyncErrorData, TeamData, TeamMemberData, addMemberToTeam, getTeam, removeMemberFromTeam, roleString, setTeamMemberRole, updateTeam)
import Api.User exposing (UserData)
import Backend.Enum.TeamRole exposing (TeamRole(..))
import Backend.Scalar exposing (RoleName(..), Slug)
import Graphql.Http exposing (RawError(..))
import Graphql.OptionalArgument
import Html exposing (Html, button, datalist, div, em, form, h2, h3, input, li, option, p, select, strong, table, tbody, td, text, th, thead, tr, ul)
import Html.Attributes exposing (class, classList, colspan, disabled, id, list, selected, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import ISO8601
import List exposing (member)
import RemoteData exposing (RemoteData(..))
import Session exposing (Session, User(..))


type EditMode
    = View
    | EditMain (Maybe (Graphql.Http.Error TeamData))
    | EditMembers (Maybe (Graphql.Http.Error TeamData))


type MemberChange
    = Unchanged TeamMemberData
    | Remove TeamMemberData
    | Add TeamRole TeamMemberData
    | ChangeRole TeamRole TeamMemberData


type alias Model =
    { team : RemoteData (Graphql.Http.Error TeamData) TeamData
    , edit : EditMode
    , userList : RemoteData (Graphql.Http.Error (List UserData)) (List UserData)
    , memberChanges : List MemberChange
    , session : Session
    , addMemberQuery : String
    , addMemberError : String
    }


type Msg
    = GotTeamResponse (RemoteData (Graphql.Http.Error TeamData) TeamData)
    | GotSaveOverviewResponse (RemoteData (Graphql.Http.Error TeamData) TeamData)
    | GotSaveTeamMembersResponse (RemoteData (Graphql.Http.Error TeamData) TeamData)
    | ClickedEditMain
    | ClickedEditMembers
    | ClickedSaveOverview TeamData
    | ClickedSaveTeamMembers TeamData (List MemberChange)
    | PurposeChanged String
    | AddMemberQueryChanged String
    | RemoveMember MemberChange
    | Undo MemberChange
    | RoleDropDownClicked TeamRole MemberChange
    | GotUserListResponse (RemoteData (Graphql.Http.Error (List UserData)) (List UserData))
    | OnSubmitAddMember


init : Session -> Backend.Scalar.Slug -> ( Model, Cmd Msg )
init session slug =
    ( { team = NotAsked
      , session = session
      , edit = View
      , userList = NotAsked
      , memberChanges = []
      , addMemberQuery = ""
      , addMemberError = ""
      }
    , Cmd.batch [ fetchTeam slug, getUserList ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotTeamResponse r ->
            ( { model | team = r, memberChanges = initMembers r }, Cmd.none )

        GotSaveOverviewResponse r ->
            case r of
                Success _ ->
                    ( { model | team = r, edit = View }, Cmd.none )

                Failure error ->
                    ( { model | edit = EditMain (Just error) }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ClickedEditMain ->
            ( { model | edit = EditMain Nothing }, Cmd.none )

        ClickedEditMembers ->
            ( { model | edit = EditMembers Nothing }, Cmd.none )

        PurposeChanged s ->
            ( mapTeam (\team -> { team | purpose = s }) model, Cmd.none )

        ClickedSaveOverview team ->
            ( model, saveOverview team )

        AddMemberQueryChanged s ->
            ( { model | addMemberQuery = s }, Cmd.none )

        RemoveMember m ->
            ( { model | memberChanges = List.map (mapMember Remove (memberData m)) model.memberChanges }, Cmd.none )

        Undo m ->
            ( { model
                | memberChanges =
                    case m of
                        Add _ _ ->
                            removeMember (memberData m) model.memberChanges

                        _ ->
                            List.map (mapMember Unchanged (memberData m)) model.memberChanges
              }
            , Cmd.none
            )

        RoleDropDownClicked role member ->
            let
                op =
                    case member of
                        Add _ _ ->
                            Add role

                        Remove _ ->
                            Remove

                        Unchanged _ ->
                            ChangeRole role

                        ChangeRole _ _ ->
                            ChangeRole role
            in
            ( { model | memberChanges = List.map (mapMember op (memberData member)) model.memberChanges }, Cmd.none )

        GotUserListResponse r ->
            ( { model | userList = r }, Cmd.none )

        OnSubmitAddMember ->
            case model.userList of
                Success userList ->
                    case List.head (List.filter (\u -> nameAndEmail u == model.addMemberQuery) userList) of
                        Just u ->
                            ( { model | addMemberQuery = "", memberChanges = addMember u model.memberChanges }, Cmd.none )

                        Nothing ->
                            ( { model | addMemberError = "no user found in userlist" }, Cmd.none )

                _ ->
                    ( { model | addMemberError = "failed to fetch userlist" }, Cmd.none )

        ClickedSaveTeamMembers team changes ->
            ( model, Cmd.batch (List.concatMap (mapMemberChangeToCmds team) changes) )

        GotSaveTeamMembersResponse r ->
            case r of
                Success _ ->
                    ( { model | team = r, edit = View }, Cmd.none )

                Failure error ->
                    ( { model | edit = EditMembers (Just error) }, Cmd.none )

                _ ->
                    ( model, Cmd.none )


mapMemberChangeToCmds : TeamData -> MemberChange -> List (Cmd Msg)
mapMemberChangeToCmds team change =
    case change of
        Add r m ->
            [ Api.Do.mutate (addMemberToTeam team m.user) (RemoteData.fromResult >> GotSaveTeamMembersResponse)
            , Api.Do.mutate (setTeamMemberRole team m r) (RemoteData.fromResult >> GotSaveTeamMembersResponse)
            ]

        Remove m ->
            [ Api.Do.mutate (removeMemberFromTeam team m.user) (RemoteData.fromResult >> GotSaveTeamMembersResponse) ]

        ChangeRole r m ->
            [ Api.Do.mutate (setTeamMemberRole team m r) (RemoteData.fromResult >> GotSaveTeamMembersResponse) ]

        Unchanged _ ->
            []


initMembers : RemoteData (Graphql.Http.Error TeamData) TeamData -> List MemberChange
initMembers response =
    case response of
        Success t ->
            List.map Unchanged t.members

        _ ->
            []


memberData : MemberChange -> TeamMemberData
memberData member =
    case member of
        Unchanged m ->
            m

        ChangeRole _ m ->
            m

        Add _ m ->
            m

        Remove m ->
            m


removeMember : TeamMemberData -> List MemberChange -> List MemberChange
removeMember member members =
    List.filter (\m -> not (member.user.email == (memberData m).user.email)) members


isMember : List MemberChange -> TeamMemberData -> Bool
isMember members member =
    List.filter (\m -> member.user.email == (memberData m).user.email) members
        |> List.isEmpty
        |> not


addMember : UserData -> List MemberChange -> List MemberChange
addMember user members =
    let
        role =
            Backend.Enum.TeamRole.Member

        member =
            { user = user, role = role }
    in
    if not (isMember members member) then
        Add role member :: members

    else
        members


mapMember : (TeamMemberData -> MemberChange) -> TeamMemberData -> MemberChange -> MemberChange
mapMember typ memberToChange m =
    if (memberData m).user.email == memberToChange.user.email then
        typ (memberData m)

    else
        m


saveOverview : TeamData -> Cmd Msg
saveOverview team =
    Api.Do.mutate
        (updateTeam
            team.slug
            { purpose = Graphql.OptionalArgument.Present team.purpose
            }
        )
        (GotSaveOverviewResponse << RemoteData.fromResult)


mapTeam : (TeamData -> TeamData) -> Model -> Model
mapTeam fn model =
    case model.team of
        Success team ->
            { model | team = Success <| fn team }

        _ ->
            model


fetchTeam : Slug -> Cmd Msg
fetchTeam slug =
    query (getTeam slug) (RemoteData.fromResult >> GotTeamResponse)


slugstr : Backend.Scalar.Slug -> String
slugstr (Backend.Scalar.Slug u) =
    u


timestr : ISO8601.Time -> String
timestr u =
    let
        pad len int =
            String.fromInt int |> String.padLeft len '0'
    in
    pad 4 u.year
        ++ "-"
        ++ pad 2 u.month
        ++ "-"
        ++ pad 2 u.day
        ++ " "
        ++ pad 2 u.hour
        ++ ":"
        ++ pad 2 u.minute
        ++ ":"
        ++ pad 2 u.second


actionstr : Backend.Scalar.AuditAction -> String
actionstr (Backend.Scalar.AuditAction u) =
    u


memberRow : TeamMemberData -> Html Msg
memberRow member =
    tr []
        [ td [] [ text member.user.email ]
        , td [ classList [ ( "team-owner", member.role == Owner ) ] ] [ text <| roleString member.role ]
        ]


logLine : ISO8601.Time -> String -> String -> Html msg
logLine ts actor message =
    li []
        [ p [] [ text message ]
        , div [ class "meta" ]
            [ p [] [ text (timestr ts) ]
            , p [] [ text actor ]
            ]
        ]


errorLine : SyncErrorData -> Html Msg
errorLine log =
    logLine log.timestamp log.reconcilerName log.message


auditLogLine : AuditLogData -> Html Msg
auditLogLine log =
    let
        actor =
            case log.actor of
                Nothing ->
                    actionstr log.action

                Just s ->
                    s
    in
    logLine log.createdAt actor log.message


simpleRow : String -> String -> Html msg
simpleRow header content =
    tr []
        [ td [] [ text header ]
        , td [] [ text content ]
        ]


metadataRow : KeyValueData -> Html msg
metadataRow kv =
    case kv.value of
        Just v ->
            simpleRow kv.key v

        Nothing ->
            simpleRow kv.key ""


editorButton : Msg -> User -> TeamData -> List (Html Msg)
editorButton msg user team =
    if editor team user then
        [ div [ class "small button", onClick msg ] [ text "Edit" ] ]

    else
        []


viewSyncErrors : TeamData -> Html Msg
viewSyncErrors team =
    let
        syncSuccess =
            case team.lastSuccessfulSync of
                Nothing ->
                    Html.text ""

                Just ts ->
                    p []
                        [ em [] [ text <| "The last successful synchronization was on " ++ timestr ts ++ "." ]
                        ]
    in
    case team.syncErrors of
        [] ->
            text ""

        _ ->
            div [ class "card error" ]
                [ h2 [] [ text "Synchronization error" ]
                , p [] [ text "Console failed to synchronize team ", strong [] [ text (slugstr team.slug) ], text " with external systems. The operations will be automatically retried. The messages below indicate what went wrong." ]
                , p [] [ text "If errors are caused by network outage, they will resolve automatically. If they persist for more than a few hours, please NAIS support." ]
                , syncSuccess
                , h3 [] [ text "Error messages" ]
                , ul [ class "logs" ] (List.map errorLine team.syncErrors)
                ]


viewTeamMetaTable : List KeyValueData -> Html msg
viewTeamMetaTable metadata =
    case metadata of
        [] ->
            text ""

        _ ->
            table []
                [ thead []
                    [ tr []
                        [ th [] [ text "Key" ]
                        , th [] [ text "Value" ]
                        ]
                    ]
                , tbody []
                    (List.map metadataRow metadata)
                ]


viewTeamOverview : User -> TeamData -> Html Msg
viewTeamOverview user team =
    div [ class "card" ]
        [ div [ class "title" ]
            (h2 [] [ text ("Team " ++ slugstr team.slug) ]
                :: editorButton ClickedEditMain user team
            )
        , p [] [ text team.purpose ]
        , viewTeamMetaTable team.metadata
        ]


viewEditTeamOverview : TeamData -> Maybe (Graphql.Http.Error TeamData) -> Html Msg
viewEditTeamOverview team error =
    let
        errorMessage =
            case error of
                Nothing ->
                    text ""

                Just err ->
                    div [ class "error" ] [ text <| Api.Error.errorToString err ]
    in
    div [ class "card" ]
        [ h2 [] [ text ("Team " ++ slugstr team.slug) ]
        , input [ type_ "text", Html.Attributes.placeholder "Describe team's purpose", onInput PurposeChanged, value team.purpose ] []
        , errorMessage
        , button [ onClick (ClickedSaveOverview team) ] [ text "Save changes" ]
        , viewTeamMetaTable team.metadata
        ]


viewMembers : User -> TeamData -> Html Msg
viewMembers user team =
    div [ class "card" ]
        [ div [ class "title" ]
            (h2 [] [ text "Members" ]
                :: editorButton ClickedEditMembers user team
            )
        , table []
            [ thead []
                [ tr []
                    [ th [] [ text "Email" ]
                    , th [] [ text "Role" ]
                    ]
                ]
            , tbody [] (List.map memberRow team.members)
            ]
        ]


nameAndEmail : UserData -> String
nameAndEmail user =
    user.name ++ " <" ++ user.email ++ ">"


addUserCandidateOption : UserData -> Html msg
addUserCandidateOption user =
    option [] [ text (nameAndEmail user) ]


editMemberRow : User -> MemberChange -> Html Msg
editMemberRow currentUser member =
    case member of
        Unchanged m ->
            tr []
                [ td [] [ text (m.user.email ++ " unchanged") ]
                , td [] [ roleSelector currentUser member False ]
                , td [] [ button [ class "red", onClick (RemoveMember member) ] [ text "Remove" ] ]
                ]

        Remove m ->
            tr []
                [ td [ class "strikethrough" ] [ text (m.user.email ++ " remove") ]
                , td [] [ roleSelector currentUser member True ]
                , td [] [ button [ class "red", onClick (Undo member) ] [ text "Undo" ] ]
                ]

        Add _ m ->
            tr []
                [ td [] [ text (m.user.email ++ " add") ]
                , td [] [ roleSelector currentUser member False ]
                , td [] [ button [ class "red", onClick (Undo member) ] [ text "Undo" ] ]
                ]

        ChangeRole _ m ->
            tr []
                [ td [] [ text (m.user.email ++ " rolechange") ]
                , td [] [ roleSelector currentUser member False, text "*" ]
                , td [] [ button [ class "red", onClick (Undo member) ] [ text "Undo" ] ]
                ]


userIsMember : User -> TeamMemberData -> Bool
userIsMember currentUser member =
    case currentUser of
        LoggedIn u ->
            u.id == member.user.id

        _ ->
            False


roleSelector : User -> MemberChange -> Bool -> Html Msg
roleSelector currentUser member disable =
    let
        currentUserIsMember =
            userIsMember currentUser (memberData member)

        isAdmin =
            (memberData member).role == Owner

        isGlobalAdmin =
            Session.isGlobalAdmin currentUser
    in
    select [ disabled (currentUserIsMember && isAdmin && not isGlobalAdmin || disable) ] (Backend.Enum.TeamRole.list |> List.map (roleOption member))


roleOption : MemberChange -> TeamRole -> Html Msg
roleOption member role =
    let
        roleID =
            Backend.Enum.TeamRole.toString role

        roleStr =
            roleString role

        newRole =
            case member of
                ChangeRole r _ ->
                    r

                _ ->
                    (memberData member).role
    in
    option
        [ onClick (RoleDropDownClicked role member)
        , selected (role == newRole)
        , value roleID
        ]
        [ text roleStr ]


viewEditMembers : Model -> TeamData -> Maybe (Graphql.Http.Error TeamData) -> Html Msg
viewEditMembers model team err =
    div [ class "card" ]
        (case model.userList of
            NotAsked ->
                [ text "userlist not asked for" ]

            Failure f ->
                [ text "failed" ]

            Loading ->
                [ text "loading" ]

            Success userList ->
                [ div [ class "title" ]
                    (h2 [] [ text "Members" ]
                        :: editorButton ClickedEditMembers (Session.user model.session) team
                    )
                , form [ id "addMemberForm", onSubmit OnSubmitAddMember ] []
                , table []
                    [ thead []
                        [ tr []
                            [ th [] [ text "Email" ]
                            , th [] [ text "Role" ]
                            , th [] [ text "" ]
                            ]
                        ]
                    , tbody []
                        (tr []
                            [ td []
                                [ input [ list "userCandidates", Html.Attributes.form "addMemberForm", type_ "text", value model.addMemberQuery, onInput AddMemberQueryChanged ] []
                                , datalist [ id "userCandidates" ] (List.map addUserCandidateOption userList)
                                , p [] [ text model.addMemberError ]
                                ]
                            , td [ colspan 2 ] [ button [ type_ "submit", Html.Attributes.form "addMemberForm" ] [ text "add" ] ]
                            ]
                            :: List.map (editMemberRow (Session.user model.session)) model.memberChanges
                        )
                    ]
                , button [ onClick (ClickedSaveTeamMembers team model.memberChanges) ] [ text "Save changes" ]
                ]
        )


viewLogs : TeamData -> Html Msg
viewLogs team =
    div [ class "card" ]
        [ h2 [] [ text "Logs" ]
        , ul [ class "logs" ] (List.map auditLogLine team.auditLogs)
        ]


viewCards : Model -> TeamData -> Html Msg
viewCards model team =
    let
        user =
            Session.user model.session
    in
    div [ class "cards" ]
        (case model.edit of
            View ->
                [ viewTeamOverview user team
                , viewSyncErrors team
                , viewMembers user team
                , viewLogs team
                ]

            EditMain err ->
                [ viewEditTeamOverview team err
                , viewSyncErrors team
                , viewMembers user team
                , viewLogs team
                ]

            EditMembers err ->
                [ viewTeamOverview user team
                , viewSyncErrors team
                , viewEditMembers model team err
                , viewLogs team
                ]
        )


view : Model -> Html Msg
view model =
    case model.team of
        Success team ->
            viewCards model team

        Failure err ->
            div [ class "card error" ] [ text <| errorToString err ]

        Loading ->
            div [ class "card" ] [ text "Loading data..." ]

        NotAsked ->
            div [ class "card" ] [ text "No data loaded" ]


teamRoleForUser : TeamData -> User -> Maybe TeamRole
teamRoleForUser team user =
    case user of
        LoggedIn u ->
            List.head (List.filter (\m -> m.user.id == u.id) team.members)
                |> Maybe.map (\m -> m.role)

        Anonymous ->
            Nothing

        Unknown ->
            Nothing


editor : TeamData -> User -> Bool
editor team user =
    List.any (\b -> b)
        [ Session.isGlobalAdmin user
        , teamRoleForUser team user == Just Owner
        ]


getUserList : Cmd Msg
getUserList =
    Api.Do.query
        Api.User.getAllUsers
        (RemoteData.fromResult >> GotUserListResponse)
