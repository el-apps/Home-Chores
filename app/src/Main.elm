port module Main exposing (..)

import Browser
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode exposing (Value)
import Time



-- MAIN


main : Program () Model Msg
main =
    Browser.element { init = init, view = view, update = update, subscriptions = subscriptions }



-- PORTS


port newEvent : Value -> Cmd msg


port onNewHistory : (Value -> msg) -> Sub msg



-- MODEL


type alias Event =
    { uuid : String
    , timestamp : Time.Posix
    , userUuid : String
    , itemUuid : String
    , action : String
    , payload : String
    }


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


eventsDecoder : Decode.Decoder (List Event)
eventsDecoder =
    Decode.list eventDecoder


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


buildModelFromEvents : List Event -> Model
buildModelFromEvents events =
    let
        sorted =
            List.sortBy (\e -> Time.posixToMillis e.timestamp) events

        step event ( items, completionsAccumulator ) =
            case event.action of
                "addChore" ->
                    ( Dict.update event.itemUuid
                        (\maybe -> Just (Maybe.withDefault Dict.empty maybe))
                        items
                    , completionsAccumulator
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
                            , completionsAccumulator
                            )

                        Err _ ->
                            ( items, completionsAccumulator )

                "completeChore" ->
                    case Decode.decodeString completePayloadDecoder event.payload of
                        Ok ts ->
                            ( items
                            , { choreUuid = event.itemUuid, timestamp = ts } :: completionsAccumulator
                            )

                        Err _ ->
                            ( items, completionsAccumulator )

                _ ->
                    ( items, completionsAccumulator )

        ( choresDict, completions ) =
            List.foldl step ( Dict.empty, [] ) sorted

        toChore ( uuid, attrs ) =
            case Dict.get "type" attrs of
                Just "repeated_weekly" ->
                    let
                        name =
                            Maybe.withDefault "New Chore" (Dict.get "name" attrs)

                        day =
                            Dict.get "day" attrs
                                |> Maybe.andThen weekdayFromString
                                |> Maybe.withDefault Time.Mon
                    in
                    Just ( RepeatedWeekly { uuid = uuid, name = name, day = day } )

                Just "one_time" ->
                    let
                        name =
                            Maybe.withDefault "New Chore" (Dict.get "name" attrs)
                    in
                    Just ( OneTime { uuid = uuid, name = name } )

                _ ->
                    let
                        name =
                            Maybe.withDefault "New Chore" (Dict.get "name" attrs)
                    in
                    Just ( OneTime { uuid = uuid, name = name } )
    in
    { chores = choresDict |> Dict.toList |> List.filterMap toChore
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
