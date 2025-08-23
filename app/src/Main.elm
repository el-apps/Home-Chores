port module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode exposing (Decoder, Value)
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
    | OneTime
        { uuid : String
        , name : String
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
    ( Model [] []
    , Cmd.none
    )



-- DECODERS


weekdayDecoder : Decode.Decoder Time.Weekday
weekdayDecoder =
    Decode.string
        |> Decode.andThen
            (\s ->
                case s of
                    "Mon" ->
                        Decode.succeed Time.Mon

                    "Tue" ->
                        Decode.succeed Time.Tue

                    "Wed" ->
                        Decode.succeed Time.Wed

                    "Thu" ->
                        Decode.succeed Time.Thu

                    "Fri" ->
                        Decode.succeed Time.Fri

                    "Sat" ->
                        Decode.succeed Time.Sat

                    "Sun" ->
                        Decode.succeed Time.Sun

                    _ ->
                        Decode.fail ("Invalid weekday: " ++ s)
            )


choreDecoder : Decode.Decoder Chore
choreDecoder =
    Decode.field "type" Decode.string
        |> Decode.andThen
            (\typ ->
                case typ of
                    "repeated_weekly" ->
                        Decode.map3
                            (\uuid name day ->
                                RepeatedWeekly { uuid = uuid, name = name, day = day }
                            )
                            (Decode.field "uuid" Decode.string)
                            (Decode.field "name" Decode.string)
                            (Decode.field "day" weekdayDecoder)

                    "one_time" ->
                        Decode.map2
                            (\uuid name ->
                                OneTime { uuid = uuid, name = name }
                            )
                            (Decode.field "uuid" Decode.string)
                            (Decode.field "name" Decode.string)

                    _ ->
                        Decode.fail ("Unknown chore type: " ++ typ)
            )


choreCompletionDecoder : Decode.Decoder ChoreCompletion
choreCompletionDecoder =
    Decode.map2
        (\choreUuid timestampMillis ->
            { choreUuid = choreUuid, timestamp = Time.millisToPosix timestampMillis }
        )
        (Decode.field "choreUuid" Decode.string)
        (Decode.field "timestamp" Decode.int)


modelDecoder : Decode.Decoder Model
modelDecoder =
    Decode.map2
        (\chores completedChores ->
            { chores = chores, completedChores = completedChores }
        )
        (Decode.field "chores" (Decode.list choreDecoder))
        (Decode.field "completedChores" (Decode.list choreCompletionDecoder))


-- UPDATE


type Msg
    = NewHistory Value
    | AddChore Chore


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewHistory value ->
            case Decode.decodeValue modelDecoder value of
                Ok newModel ->
                    ( newModel, Cmd.none )

                Err _ ->
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

        OneTime { name } ->
            article []
                [ header []
                    [ h2 [] [ text name ] ]
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
