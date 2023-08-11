module CreateGroupPage exposing
    ( CreateGroupError(..)
    , GroupFormValidated
    , Model
    , Msg
    , OutMsg(..)
    , descriptionInputId
    , groupVisibilityId
    , init
    , nameInputId
    , submitButtonId
    , submitFailed
    , update
    , view
    )

import Description exposing (Description)
import Effect.Browser.Dom exposing (HtmlId)
import Element exposing (Element)
import Group exposing (GroupVisibility(..))
import GroupName exposing (GroupName)
import HtmlId
import List.Nonempty exposing (Nonempty(..))
import MyUi
import Route
import UserConfig exposing (UserConfig)


type Model
    = Editting Form
    | Submitting GroupFormValidated
    | SubmitFailed CreateGroupError Form


type alias GroupFormValidated =
    { name : GroupName
    , description : Description
    , visibility : GroupVisibility
    }


validatedToForm : GroupFormValidated -> Form
validatedToForm validated =
    { pressedSubmit = False
    , name = GroupName.toString validated.name
    , description = Description.toString validated.description
    , visibility = Just validated.visibility
    }


type Msg
    = FormChanged Form
    | PressedSubmit


type alias Form =
    { pressedSubmit : Bool
    , name : String
    , description : String
    , visibility : Maybe GroupVisibility
    }


init : Model
init =
    Editting initForm


initForm : Form
initForm =
    { pressedSubmit = False
    , name = ""
    , description = ""
    , visibility = Nothing
    }


validate : Form -> Maybe GroupFormValidated
validate form =
    case ( GroupName.fromString form.name, Description.fromString form.description, form.visibility ) of
        ( Ok groupName, Ok description, Just visibility ) ->
            { name = groupName
            , description = description
            , visibility = visibility
            }
                |> Just

        _ ->
            Nothing


type OutMsg
    = Submitted GroupFormValidated
    | NoChange


update : Msg -> Model -> ( Model, OutMsg )
update msg model =
    case model of
        Editting form ->
            updateForm Editting msg form

        Submitting _ ->
            ( model, NoChange )

        SubmitFailed error form ->
            updateForm (SubmitFailed error) msg form


updateForm : (Form -> Model) -> Msg -> Form -> ( Model, OutMsg )
updateForm wrapper msg form =
    case msg of
        FormChanged newForm ->
            ( wrapper newForm, NoChange )

        PressedSubmit ->
            case validate form of
                Just validated ->
                    ( Submitting validated, Submitted validated )

                Nothing ->
                    ( wrapper { form | pressedSubmit = True }, NoChange )


view : UserConfig -> Bool -> Bool -> Model -> Element Msg
view ({ texts } as userConfig) isMobile isFirstGroup model =
    case model of
        Editting form ->
            formView userConfig isMobile isFirstGroup Nothing False form

        Submitting validated ->
            formView userConfig isMobile isFirstGroup Nothing True (validatedToForm validated)

        SubmitFailed error form ->
            formView
                userConfig
                isMobile
                isFirstGroup
                (case error of
                    GroupNameAlreadyInUse ->
                        Just texts.sorryThatGroupNameIsAlreadyBeingUsed
                )
                False
                form


type CreateGroupError
    = GroupNameAlreadyInUse


submitFailed : CreateGroupError -> Model -> Model
submitFailed error model =
    case model of
        Editting _ ->
            model

        Submitting validated ->
            SubmitFailed error (validatedToForm validated)

        SubmitFailed createGroupError form ->
            SubmitFailed createGroupError form


formView : UserConfig -> Bool -> Bool -> Maybe String -> Bool -> Form -> Element Msg
formView { theme, texts } isMobile firstGroup maybeSubmitError isSubmitting form =
    Element.column
        (Element.width Element.fill
            :: Element.spacing 20
            :: MyUi.pageContentAttributes
        )
        [ MyUi.title texts.createGroup
        , MyUi.textInput
            theme
            nameInputId
            (\a -> FormChanged { form | name = a })
            form.name
            texts.whatSTheNameOfYourGroup
            (case ( form.pressedSubmit, GroupName.fromString form.name ) of
                ( True, Err error ) ->
                    case error of
                        GroupName.GroupNameTooShort ->
                            Just (texts.nameMustBeAtLeast GroupName.minLength)

                        GroupName.GroupNameTooLong ->
                            Just (texts.nameMustBeAtMost GroupName.maxLength)

                _ ->
                    Nothing
            )
        , MyUi.multiline
            theme
            descriptionInputId
            (\a -> FormChanged { form | description = a })
            form.description
            texts.describeWhatYourGroupIsAboutYouCanFillOutThisLater
            (case ( form.pressedSubmit, Description.fromString form.description ) of
                ( True, Err error ) ->
                    Description.errorToString texts form.description error |> Just

                _ ->
                    Nothing
            )
        , MyUi.radioGroup
            theme
            groupVisibilityId
            (\a -> FormChanged { form | visibility = Just a })
            (Nonempty PublicGroup [ UnlistedGroup ])
            form.visibility
            (\visibility ->
                case visibility of
                    UnlistedGroup ->
                        texts.iWantThisGroupToBeUnlistedPeopleCanOnlyFindItIfYouLinkItToThem

                    PublicGroup ->
                        texts.iWantThisGroupToBePubliclyVisible
            )
            (case ( form.pressedSubmit, form.visibility ) of
                ( True, Nothing ) ->
                    Just texts.pickAVisibilitySetting

                _ ->
                    Nothing
            )
        , if firstGroup then
            Element.column
                [ Element.spacing 4 ]
                [ Element.paragraph
                    []
                    [ Element.text texts.sinceThisIsYourFirstGroupWeRecommendYouReadThe
                    , MyUi.routeLinkNewTab theme Route.CodeOfConductRoute texts.codeOfConduct
                    , Element.text "."
                    ]
                ]

          else
            Element.none
        , Element.column
            [ Element.spacing 8, Element.paddingXY 0 16, Element.width Element.fill ]
            [ case maybeSubmitError of
                Just error ->
                    MyUi.formError theme error

                Nothing ->
                    Element.none
            , Element.el
                [ if isMobile then
                    Element.width Element.fill

                  else
                    Element.width (Element.px 200)
                ]
                (MyUi.submitButton theme submitButtonId isSubmitting { onPress = PressedSubmit, label = texts.submit })
            ]
        ]


nameInputId : HtmlId
nameInputId =
    HtmlId.textInputId "createGroupName"


descriptionInputId : HtmlId
descriptionInputId =
    HtmlId.textInputId "createGroupDescription"


submitButtonId : HtmlId
submitButtonId =
    HtmlId.buttonId "createGroupSubmit"


groupVisibilityId : GroupVisibility -> HtmlId
groupVisibilityId =
    HtmlId.radioButtonId
        "groupCreateVisibility_"
        (\visibility ->
            case visibility of
                UnlistedGroup ->
                    "UnlistedGroup"

                PublicGroup ->
                    "PublicGroup"
        )
