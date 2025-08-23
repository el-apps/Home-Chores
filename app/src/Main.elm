port module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode exposing (Value)
import Time



-- MAIN


main : Program () Model Msg
main =
    Browser.element { init = init, view = view, update = update, subscriptions = subscriptions }



-- PORTS


port pushData : Value -> Cmd msg


port onNewHistory : (Value -> msg) -> Sub msg



-- MODEL


type Chore
    = RepeatedWeekly
        { uuid : String
        , name : String
        , day : Time.Weekday
        }


type alias ChoreCompletion =
    { choreUuid : String
    , timestamp : Time.Posix
    }


type alias Model =
    { chores : List Chore
    , completedChores : List ChoreCompletion
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model
        [ RepeatedWeekly { uuid = "c892a6cb-cfbc-4d05-8888-28b54f0ffe90", name = "Take out the trash", day = Time.Wed }
        , RepeatedWeekly { uuid = "228a6965-28e2-4026-b6a9-6c0cc4a57026", name = "Mow the yard", day = Time.Tue }
        ]
        []
    , Cmd.none
    )



-- UPDATE


type Msg
    = NewHistory Value
    | AddChore Chore


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewHistory _ ->
            -- TODO: incorporate new data from outside
            ( model, Cmd.none )

        AddChore _ ->
            -- TODO: add chore
            ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    node "main"
        [ class "container" ]
        (nav [] [ ul [] [ h1 [] [ text "Chores" ] ] ]
            :: List.map viewChore model.chores
        )


viewChore : Chore -> Html msg
viewChore chore =
    case chore of
        RepeatedWeekly { name, day } ->
            article []
                [ header []
                    [ h2 [] [ text name ]
                    , text ("Weekly - " ++ dayName day)
                    ]
                , div [] [ text "Needs Done" ]

                -- TODO: add button to mark chore done
                -- , button [] [ text "Mark as complete" ]
                ]


dayName : Time.Weekday -> String
dayName day =
    case day of
        Time.Mon ->
            "Monday"

        Time.Tue ->
            "Tuesday"

        Time.Wed ->
            "Wednesday"

        Time.Thu ->
            "Thursday"

        Time.Fri ->
            "Friday"

        Time.Sat ->
            "Saturday"

        Time.Sun ->
            "Sunday"



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    onNewHistory NewHistory
