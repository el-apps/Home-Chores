port module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode exposing (Decoder, Value)
import Dict exposing (Dict)
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


type alias Event =
    { uuid : String
    , timestamp : Time.Posix
    , userUuid : String
    , itemUuid : String
    , action : String
    , payload : String
    }


eventDecoder : Decode.Decoder Event
eventDecoder =
    Decode.map6
        (\uuid ts user item action payload ->
            { uuid = uuid
            , timestamp = Time.millisToPosix ts
            , userUuid = user
            , itemUuid = item
            , action = action
            , payload = payload
            }
        )
        (Decode.field "uuid" Decode.string)
        (Decode.field "timestamp" Decode.int)
        (Decode.field "userUuid" Decode.string)
        (Decode.field "itemUuid" Decode.string)
        (Decode.field "action" Decode.string)
        (Decode.field "payload" Decode.string)


eventsDecoder : Decode.Decoder (List Event)
eventsDecoder =
    Decode.list eventDecoder


updatePayloadDecoder : Decode.Decoder ( String, String )
updatePayloadDecoder =
    Decode.map2 Tuple.pair
        (Decode.field "field" Decode.string)
        (Decode.field "value" Decode.string)


completePayloadDecoder : Decode.Decoder Time.Posix
completePayloadDecoder =
    Decode.field "timestamp" Decode.int
        |> Decode.map Time.millisToPosix


weekdayFromString : String -> Maybe Time.Weekday
weekdayFromString s =
    case s of
        "Mon" ->
            Just Time.Mon

        "Tue" ->
            Just Time.Tue

        "Wed" ->
            Just Time.Wed

        "Thu" ->
            Just Time.Thu

        "Fri" ->
            Just Time.Fri

        "Sat" ->
            Just Time.Sat

        "Sun" ->
            Just Time.Sun

        _ ->
            Nothing


type alias Attrs =
    Dict String String


buildModelFromEvents : List Event -> Model
buildModelFromEvents events =
    let
        sorted =
            List.sortBy (\e -> Time.posixToMillis e.timestamp) events

        step event ( items, completionsAcc ) =
            case event.action of
                "addChore" ->
                    ( Dict.update event.itemUuid
                        (\maybe -> Just (Maybe.withDefault Dict.empty maybe))
                        items
                    , completionsAcc
                    )

                "updateChore" ->
                    case Decode.decodeString updatePayloadDecoder event.payload of
                        Ok ( field, value ) ->
                            ( Dict.update event.itemUuid
                                (\maybeAttrs ->
                                    let
                                        attrs =
                                            Maybe.withDefault Dict.empty maybeAttrs
                                    in
                                    Just (Dict.insert field value attrs)
                                )
                                items
                            , completionsAcc
                            )

                        Err _ ->
                            ( items, completionsAcc )

                "completeChore" ->
                    case Decode.decodeString completePayloadDecoder event.payload of
                        Ok ts ->
                            ( items
                            , { choreUuid = event.itemUuid, timestamp = ts } :: completionsAcc
                            )

                        Err _ ->
                            ( items, completionsAcc )

                _ ->
                    ( items, completionsAcc )

        ( itemsDict, completions ) =
            List.foldl step ( Dict.empty, [] ) sorted

        toChore ( uuid, attrs ) =
            case Dict.get "type" attrs of
                Just "repeated_weekly" ->
                    case ( Dict.get "name" attrs, Dict.get "day" attrs ) of
                        ( Just name, Just dayStr ) ->
                            case weekdayFromString dayStr of
                                Just day ->
                                    Just (RepeatedWeekly { uuid = uuid, name = name, day = day })

                                Nothing ->
                                    Nothing

                        _ ->
                            Nothing

                Just "one_time" ->
                    case Dict.get "name" attrs of
                        Just name ->
                            Just (OneTime { uuid = uuid, name = name })

                        _ ->
                            Nothing

                _ ->
                    Nothing
    in
    { chores = itemsDict |> Dict.toList |> List.filterMap toChore
    , completedChores = List.reverse completions
    }


-- UPDATE


type Msg
    = NewHistory Value
    | AddChore Chore


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewHistory value ->
            case Decode.decodeValue eventsDecoder value of
                Ok events ->
                    ( buildModelFromEvents events, Cmd.none )

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
