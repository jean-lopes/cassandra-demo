module Main exposing (main)

import Bootstrap.Breadcrumb as Breadcrumb
import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Form.InputGroup as InputGroup
import Bootstrap.Form.Select as Select
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Bootstrap.ListGroup as Listgroup
import Bootstrap.Modal as Modal
import Bootstrap.Navbar as Navbar
import Bootstrap.Text as Text
import Bootstrap.Utilities.Spacing as Spacing
import Browser exposing (UrlRequest)
import Browser.Navigation as Navigation
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http as Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import JsonTree
import List as List
import Random as Random
import Tuple as Tuple
import Url exposing (Url)
import Url.Parser as UrlParser exposing ((</>), Parser, s, top)
import Uuid as Uuid exposing (Uuid)


type Category
    = Van
    | Truck
    | Plane
    | Ship


type alias Boarding =
    { id : String
    , shipper : String
    , category : Category
    , origin : String
    , destiny : String
    , mileage : Int
    , weight : Int
    , collectionDate : String
    }


type alias Flags =
    {}


type alias Model =
    { navKey : Navigation.Key
    , page : Page
    , navState : Navbar.State
    , shipper : String
    , category : Category
    , origin : String
    , destiny : String
    , mileage : Int
    , weight : Int
    , collectionDate : String
    , validShipper : Bool
    , validOrigin : Bool
    , validDestiny : Bool
    , validMileage : Bool
    , validWeight : Bool
    , validCollectionDate : Bool
    , saveDisabled : Bool
    , newBoardingResponse : Result Http.Error Boarding
    }


type Page
    = Home
    | Boardings
    | NewBoarding
    | NotFound


type Msg
    = UrlChange Url
    | ClickedLink UrlRequest
    | NavMsg Navbar.State
    | ChangedShipper String
    | ChangedCategory Category
    | ChangedOrigin String
    | ChangedDestiny String
    | ChangedMileage Int
    | ChangedWeight Int
    | ChangedCollectionDate String
    | Save
    | Created (Result Http.Error Boarding)
    | None


extractBoarding : Model -> Boarding
extractBoarding model =
    { id = ""
    , shipper = model.shipper
    , category = model.category
    , origin = model.origin
    , destiny = model.destiny
    , mileage = model.mileage
    , weight = model.weight
    , collectionDate = model.collectionDate
    }


strToCategory : String -> Maybe Category
strToCategory s =
    case String.toUpper s of
        "VAN" ->
            Just Van

        "TRUCK" ->
            Just Truck

        "PLANE" ->
            Just Plane

        "SHIP" ->
            Just Ship

        _ ->
            Nothing


categoryToStr : Category -> String
categoryToStr category =
    case category of
        Van ->
            "VAN"

        Truck ->
            "TRUCK"

        Plane ->
            "PLANE"

        Ship ->
            "SHIP"


categoryDecoder : Decoder Category
categoryDecoder =
    Decode.string
        |> Decode.andThen
            (\s ->
                case strToCategory s of
                    Nothing ->
                        Decode.fail "Invalid category"

                    Just c ->
                        Decode.succeed c
            )


boardingDecoder : Decoder Boarding
boardingDecoder =
    Decode.map8 Boarding
        (Decode.field "id" Decode.string)
        (Decode.field "shipper" Decode.string)
        (Decode.field "category" categoryDecoder)
        (Decode.field "origin" Decode.string)
        (Decode.field "destiny" Decode.string)
        (Decode.field "weight" Decode.int)
        (Decode.field "mileage" Decode.int)
        (Decode.field "collection_date" Decode.string)


encodeBoarding : Boarding -> Encode.Value
encodeBoarding boarding =
    Encode.object
        [ ( "id", Encode.string boarding.id )
        , ( "shipper", Encode.string boarding.shipper )
        , ( "category", Encode.string <| categoryToStr boarding.category )
        , ( "origin", Encode.string boarding.origin )
        , ( "destiny", Encode.string boarding.destiny )
        , ( "mileage", Encode.int boarding.mileage )
        , ( "weight", Encode.int boarding.weight )
        , ( "collection_date", Encode.string boarding.collectionDate )
        ]


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = ClickedLink
        , onUrlChange = UrlChange
        }


emptyBoarding : Boarding
emptyBoarding =
    { id = ""
    , shipper = ""
    , origin = ""
    , destiny = ""
    , mileage = 0
    , category = Van
    , weight = 0
    , collectionDate = ""
    }


init : Flags -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        ( navState, navCmd ) =
            Navbar.initialState NavMsg

        ( model, urlCmd ) =
            urlUpdate url
                { navKey = key
                , navState = navState
                , page = Home
                , shipper = ""
                , origin = ""
                , destiny = ""
                , mileage = 0
                , category = Van
                , weight = 0
                , collectionDate = ""
                , validShipper = True
                , validOrigin = True
                , validDestiny = True
                , validMileage = True
                , validWeight = True
                , validCollectionDate = True
                , saveDisabled = True
                , newBoardingResponse = Ok emptyBoarding
                }
    in
    ( model, Cmd.batch [ urlCmd, navCmd ] )


subscriptions : Model -> Sub Msg
subscriptions model =
    Navbar.subscriptions model.navState NavMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedLink req ->
            case req of
                Browser.Internal url ->
                    ( model, Navigation.pushUrl model.navKey <| Url.toString url )

                Browser.External href ->
                    ( model, Navigation.load href )

        UrlChange url ->
            urlUpdate url model

        NavMsg state ->
            ( { model | navState = state }
            , Cmd.none
            )

        ChangedShipper value ->
            ( toggleSave
                { model
                    | validShipper = isNonBlank value
                    , shipper = value
                }
            , Cmd.none
            )

        ChangedCategory value ->
            ( toggleSave { model | category = value }
            , Cmd.none
            )

        ChangedOrigin value ->
            ( toggleSave
                { model
                    | validOrigin = isNonBlank value
                    , origin = value
                }
            , Cmd.none
            )

        ChangedDestiny value ->
            ( toggleSave
                { model
                    | validDestiny = isNonBlank value
                    , destiny = value
                }
            , Cmd.none
            )

        ChangedMileage value ->
            ( toggleSave
                { model
                    | validMileage = value > 0
                    , mileage = value
                }
            , Cmd.none
            )

        ChangedWeight value ->
            ( toggleSave
                { model
                    | validWeight = value > 0
                    , weight = value
                }
            , Cmd.none
            )

        ChangedCollectionDate value ->
            ( toggleSave
                { model
                    | validCollectionDate = isNonBlank value
                    , collectionDate = value
                }
            , Cmd.none
            )

        Save ->
            ( model
            , Http.post
                { url = "http://localhost:8080/boardings"
                , body = Http.jsonBody <| encodeBoarding <| extractBoarding model
                , expect = Http.expectJson Created boardingDecoder
                }
            )

        Created httpResponse ->
            ( { model | newBoardingResponse = httpResponse }, Cmd.none )

        None ->
            ( model, Cmd.none )


toggleSave : Model -> Model
toggleSave m =
    { m
        | saveDisabled =
            isBlank m.shipper
                || isBlank m.origin
                || isBlank m.destiny
                || (m.mileage <= 0)
                || (m.weight <= 0)
                || isBlank m.collectionDate
    }


isBlank : String -> Bool
isBlank =
    String.isEmpty << String.trim


isNonBlank : String -> Bool
isNonBlank s =
    not <| isBlank s


urlUpdate : Url -> Model -> ( Model, Cmd Msg )
urlUpdate url model =
    case decode url of
        Nothing ->
            ( { model | page = NotFound }, Cmd.none )

        Just route ->
            ( { model | page = route }, Cmd.none )


decode : Url -> Maybe Page
decode url =
    { url | path = Maybe.withDefault "" url.fragment, fragment = Nothing }
        |> UrlParser.parse routeParser


routeParser : Parser (Page -> a) a
routeParser =
    UrlParser.oneOf
        [ UrlParser.map Home top
        , UrlParser.map Boardings (s "boardings")
        , UrlParser.map NewBoarding (s "boardings" </> s "new")
        ]


view : Model -> Browser.Document Msg
view model =
    { title = "Services"
    , body =
        [ div []
            [ menu model
            , mainContent model
            ]
        ]
    }


menu : Model -> Html Msg
menu model =
    Navbar.config NavMsg
        |> Navbar.withAnimation
        |> Navbar.container
        |> Navbar.brand [ href "#" ] [ text "Services" ]
        |> Navbar.items
            [ Navbar.itemLink [ href "#/boardings/new" ] [ text "Boarding" ] ]
        |> Navbar.view model.navState


mainContent : Model -> Html Msg
mainContent model =
    Grid.container [] <|
        case model.page of
            Home ->
                pageHome model

            Boardings ->
                pageBoardings model

            NewBoarding ->
                pageNewBoarding model

            NotFound ->
                pageNotFound


pageHome : Model -> List (Html Msg)
pageHome _ =
    []


pageBoardings : Model -> List (Html Msg)
pageBoardings _ =
    []


pageNewBoarding : Model -> List (Html Msg)
pageNewBoarding model =
    [ Breadcrumb.container
        [ Breadcrumb.item [] [ a [ href "#/" ] [ text "home" ] ]
        , Breadcrumb.item [] [ text "boardings" ]
        , Breadcrumb.item [] [ text "new" ]
        ]
    , Form.form
        []
        [ Grid.container []
            [ Grid.row []
                [ Grid.col [ Col.sm12, Col.lg6 ]
                    [ Form.group []
                        [ Form.label [] [ text "Shipper" ]
                        , Input.text
                            (if model.validShipper then
                                [ Input.onInput ChangedShipper ]

                             else
                                [ Input.onInput ChangedShipper, Input.danger ]
                            )
                        , Form.invalidFeedback [] [ text "Invalid shipper" ]
                        ]
                    ]
                , Grid.col [ Col.sm12, Col.lg6 ]
                    [ Form.group []
                        [ Form.label [] [ text "Category" ]
                        , Select.select
                            [ Select.onChange
                                (\s ->
                                    ChangedCategory <|
                                        Maybe.withDefault Van <|
                                            strToCategory s
                                )
                            ]
                            [ Select.item [ value "van" ] [ text "Van" ]
                            , Select.item [ value "truck" ] [ text "Truck" ]
                            , Select.item [ value "plane" ] [ text "Plane" ]
                            , Select.item [ value "ship" ] [ text "Ship" ]
                            ]
                        ]
                    ]
                ]
            , Grid.row []
                [ Grid.col [ Col.sm12, Col.lg6 ]
                    [ Form.group []
                        [ Form.label [] [ text "Origin" ]
                        , Input.text
                            (if model.validOrigin then
                                [ Input.onInput ChangedOrigin ]

                             else
                                [ Input.onInput ChangedOrigin, Input.danger ]
                            )
                        , Form.invalidFeedback [] [ text "Invalid origin" ]
                        ]
                    ]
                , Grid.col [ Col.sm12, Col.lg6 ]
                    [ Form.group []
                        [ Form.label [] [ text "Destiny" ]
                        , Input.text
                            (if model.validDestiny then
                                [ Input.onInput ChangedDestiny ]

                             else
                                [ Input.onInput ChangedDestiny, Input.danger ]
                            )
                        , Form.invalidFeedback [] [ text "Invalid destiny" ]
                        ]
                    ]
                ]
            , Grid.row []
                [ Grid.col [ Col.sm12, Col.lg4 ]
                    [ Form.group []
                        [ Form.label [] [ text "Mileage" ]
                        , InputGroup.config
                            (InputGroup.number <|
                                List.append
                                    [ Input.placeholder "0"
                                    , Input.onInput (\s -> ChangedMileage <| numberOnInput s)
                                    , Input.attrs
                                        [ Html.Attributes.min "0"
                                        , Html.Attributes.step "1"
                                        ]
                                    ]
                                    (if model.validMileage then
                                        []

                                     else
                                        List.singleton Input.danger
                                    )
                            )
                            |> InputGroup.successors
                                [ InputGroup.span [] [ text "km" ] ]
                            |> InputGroup.view
                        , Form.invalidFeedback [] [ text "Invalid mileage" ]
                        ]
                    ]
                , Grid.col [ Col.sm12, Col.lg4 ]
                    [ Form.group []
                        [ Form.label [] [ text "Weight" ]
                        , InputGroup.config
                            (InputGroup.number <|
                                List.append
                                    [ Input.placeholder "0"
                                    , Input.onInput (\s -> ChangedWeight <| numberOnInput s)
                                    , Input.attrs
                                        [ Html.Attributes.min "0"
                                        , Html.Attributes.step "1"
                                        ]
                                    ]
                                    (if model.validWeight then
                                        []

                                     else
                                        List.singleton Input.danger
                                    )
                            )
                            |> InputGroup.successors
                                [ InputGroup.span [] [ text "kg" ] ]
                            |> InputGroup.view
                        , Form.invalidFeedback [] [ text "Invalid weight" ]
                        ]
                    ]
                , Grid.col [ Col.sm12, Col.lg4 ]
                    [ Form.group []
                        [ Form.label [] [ text "Collection date and time" ]
                        , Input.datetimeLocal [ Input.onInput ChangedCollectionDate ]
                        , Form.invalidFeedback [] [ text "Invalid collection date" ]
                        ]
                    ]
                ]
            , Grid.row [ Row.rightXs ]
                [ Grid.col
                    [ Col.xs12
                    , Col.sm6
                    , Col.lg2
                    , Col.attrs
                        [ Spacing.mb1
                        , Spacing.mb0Sm
                        ]
                    ]
                    [ Button.button
                        [ Button.primary
                        , Button.block
                        , Button.onClick Save
                        , Button.disabled model.saveDisabled
                        ]
                        [ text "Save" ]
                    ]
                ]
            , Grid.row [ Row.attrs [ Spacing.mt1 ] ]
                [ Grid.col []
                    [ h5 [] [ text "Result:" ]
                    , case model.newBoardingResponse of
                        Err e ->
                            case e of
                                Http.BadUrl s ->
                                    text <| "bad url: " ++ s

                                Http.Timeout ->
                                    text "timeout"

                                Http.NetworkError ->
                                    text "network error"

                                Http.BadStatus code ->
                                    text <| "Status code: " ++ String.fromInt code

                                Http.BadBody body ->
                                    text <| "bad body: " ++ body

                        Ok boarding ->
                            boardingToHtml boarding
                    ]
                ]
            ]
        ]
    ]


boardingToHtml : Boarding -> Html Msg
boardingToHtml boarding =
    encodeBoarding boarding
        |> JsonTree.parseValue
        |> Result.map (\tree -> JsonTree.view tree jsonTreeCfg JsonTree.defaultState)
        |> Result.withDefault (text "Failed to parse JSON")


jsonTreeCfg =
    { onSelect = Nothing, toMsg = always None }


numberOnInput : String -> Int
numberOnInput s =
    Maybe.withDefault 0 <| String.toInt s


pageNotFound : List (Html Msg)
pageNotFound =
    [ h1 [] [ text "Not found" ]
    , text "Sorry couldn't find that page"
    ]
