module Route exposing (..)

import Backend.Scalar exposing (Slug(..), Uuid(..))
import Browser.Navigation as Nav
import Html exposing (Html, a)
import Html.Attributes exposing (href)
import String
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser, oneOf, s, string)


type Route
    = Home
    | ReconcilerAdmin
    | Teams
    | CreateTeam
    | Team Backend.Scalar.Slug
    | EditTeam Backend.Scalar.Slug


parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Home Parser.top
        , Parser.map ReconcilerAdmin (s "admin" </> s "synchronization")
        , Parser.map Teams (s "teams")
        , Parser.map CreateTeam (s "teams" </> s "create")
        , Parser.map (\s -> EditTeam (Slug s)) (s "teams" </> string </> s "edit")
        , Parser.map (\s -> Team (Slug s)) (s "teams" </> string)
        ]



-- PUBLIC HELPERS


link : Route -> List (Html.Attribute msg) -> List (Html msg) -> Html msg
link targetRoute attr body =
    a (href (routeToString targetRoute) :: attr) body


replaceUrl : Nav.Key -> Route -> Cmd msg
replaceUrl key route =
    Nav.replaceUrl key (routeToString route)


fromUrl : Url -> Maybe Route
fromUrl url =
    Parser.parse parser url



-- INTERNAL


routeToString : Route -> String
routeToString page =
    let
        pieces =
            case page of
                Home ->
                    [ "" ]

                ReconcilerAdmin ->
                    [ "admin", "synchronization" ]

                Teams ->
                    [ "teams" ]

                CreateTeam ->
                    [ "teams", "create" ]

                EditTeam (Slug id) ->
                    [ "teams", id, "edit" ]

                Team (Slug id) ->
                    [ "teams", id ]
    in
    "/" ++ String.join "/" pieces
