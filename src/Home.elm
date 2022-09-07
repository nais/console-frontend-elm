module Home exposing (..)

import Backend.Query exposing (me)
import Browser.Navigation
import Graphql.Http
import Html exposing (Html, button, div, h1, p, text)
import Html.Events exposing (onClick)
import Queries.Do exposing (send)
import Queries.UserQueries exposing (UserData, getMeQuery)


type Actor
    = LoggedIn UserData
    | Unauthorized
    | Unknown


type alias Model =
    { user : Actor
    }


type Msg
    = GotMeResponse (Result (Graphql.Http.Error UserData) UserData)
    | LoginClicked
    | LogoutClicked


init : ( Model, Cmd Msg )
init =
    ( { user = Unknown
      }
    , send getMeQuery GotMeResponse
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LoginClicked ->
            ( model, Browser.Navigation.load "http://localhost:3000/oauth2/login" )

        LogoutClicked ->
            ( model, Browser.Navigation.load "http://localhost:3000/oauth2/logout" )

        GotMeResponse r ->
            case r of
                Ok u ->
                    ( { model | user = LoggedIn u }, Cmd.none )

                Err e ->
                    ( { model | user = Unauthorized }, Cmd.none )


view : Model -> Html Msg
view model =
    div []
        [ h1 []
            [ text "nais console" ]
        , case model.user of
            LoggedIn user ->
                div []
                    [ p [] [ text ("Logged in as " ++ user.email) ]
                    , button [ onClick LoginClicked ] [ text "Log out" ] -- fake news logout
                    ]

            Unknown ->
                div [] [ text "Loading..." ]

            Unauthorized ->
                button [ onClick LoginClicked ] [ text "Single sign-on" ]
        ]
