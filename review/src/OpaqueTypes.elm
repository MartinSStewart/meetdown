module OpaqueTypes exposing (rule)

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Expression exposing (Expression(..), LetDeclaration(..), RecordSetter)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Pattern exposing (Pattern(..))
import Elm.Syntax.Range exposing (Location, Range)
import Elm.Syntax.TypeAnnotation exposing (TypeAnnotation(..))
import Review.ModuleNameLookupTable exposing (ModuleNameLookupTable)
import Review.Rule as Rule exposing (ModuleKey, Rule)
import Set exposing (Set)


rule : Rule
rule =
    Rule.newProjectRuleSchema "OpaqueTypes" initialContext
        |> Rule.withModuleVisitor moduleVisitor
        |> Rule.withContextFromImportedModules
        |> Rule.withModuleContextUsingContextCreator conversion
        |> Rule.fromProjectRuleSchema


initModuleContext : ModuleName -> ModuleNameLookupTable -> ProjectContext -> ModuleContext
initModuleContext moduleName lookupTable context =
    { opaqueTypes = context.opaqueTypes
    , opaqueFunctionsAndValues = context.opaqueFunctionsAndValues
    , moduleName = moduleName
    , lookupTable = lookupTable
    }


conversion :
    { fromProjectToModule : Rule.ContextCreator ProjectContext ModuleContext
    , fromModuleToProject : Rule.ContextCreator ModuleContext ProjectContext
    , foldProjectContexts : ProjectContext -> ProjectContext -> ProjectContext
    }
conversion =
    { fromProjectToModule =
        Rule.initContextCreator initModuleContext
            |> Rule.withModuleName
            |> Rule.withModuleNameLookupTable
    , fromModuleToProject = Rule.initContextCreator fromModuleToProject
    , foldProjectContexts = foldProjectContexts
    }


foldProjectContexts : ProjectContext -> ProjectContext -> ProjectContext
foldProjectContexts l r =
    { opaqueTypes = Set.union l.opaqueTypes r.opaqueTypes
    , opaqueFunctionsAndValues = Set.union l.opaqueFunctionsAndValues r.opaqueFunctionsAndValues
    }


fromModuleToProject : ModuleContext -> ProjectContext
fromModuleToProject moduleContext =
    { opaqueTypes = moduleContext.opaqueTypes
    , opaqueFunctionsAndValues = moduleContext.opaqueFunctionsAndValues
    }


moduleVisitor :
    Rule.ModuleRuleSchema {} ModuleContext
    -> Rule.ModuleRuleSchema { hasAtLeastOneVisitor : () } ModuleContext
moduleVisitor visitor =
    visitor
        |> Rule.withExpressionEnterVisitor expressionVisitor
        |> Rule.withDeclarationExitVisitor declarationVisitor


type alias ProjectContext =
    { opaqueTypes : Set ( ModuleName, String )
    , opaqueFunctionsAndValues : Set ( ModuleName, String )
    }


type alias ModuleContext =
    { opaqueTypes : Set ( ModuleName, String )
    , opaqueFunctionsAndValues : Set ( ModuleName, String )
    , moduleName : ModuleName
    , lookupTable : ModuleNameLookupTable
    }


initialContext : ProjectContext
initialContext =
    { opaqueTypes = Set.empty
    , opaqueFunctionsAndValues = Set.empty
    }


opaqueKeyword : String
opaqueKeyword =
    "Opaque"


opaqueVariantsKeyword : String
opaqueVariantsKeyword =
    "OpaqueVariants"


declarationVisitor : Node Declaration -> ModuleContext -> ( List (Rule.Error {}), ModuleContext )
declarationVisitor declaration context =
    case Node.value declaration of
        AliasDeclaration typeAlias ->
            case typeAlias.documentation of
                Just (Node range text) ->
                    let
                        text2 =
                            stringDropPrefix "{-|" text |> String.trim
                    in
                    if String.startsWith opaqueVariantsKeyword text2 then
                        ( [ Rule.error
                                { message =
                                    opaqueVariantsKeyword
                                        ++ " isn't valid for type aliases. It can only be used for custom types. Remove this or use "
                                        ++ opaqueKeyword
                                        ++ " instead."
                                , details = []
                                }
                                range
                          ]
                        , context
                        )

                    else if String.startsWith opaqueKeyword text2 then
                        ( []
                        , { context
                            | opaqueTypes =
                                Set.insert
                                    ( context.moduleName, Node.value typeAlias.name )
                                    context.opaqueTypes
                            , opaqueFunctionsAndValues =
                                case Node.value typeAlias.typeAnnotation of
                                    Elm.Syntax.TypeAnnotation.Record _ ->
                                        Set.insert
                                            ( context.moduleName, Node.value typeAlias.name )
                                            context.opaqueFunctionsAndValues

                                    _ ->
                                        context.opaqueFunctionsAndValues
                          }
                        )

                    else
                        ( [], context )

                Nothing ->
                    ( [], context )

        Destructuring pattern _ ->
            ( [], context )

        FunctionDeclaration function ->
            let
                errors : List (Rule.Error {})
                errors =
                    case function.signature of
                        Just (Node _ signature) ->
                            typeAnnotationVisitor context signature.typeAnnotation

                        Nothing ->
                            []
            in
            case function.documentation of
                Just (Node range text) ->
                    let
                        text2 =
                            stringDropPrefix "{-|" text |> String.trim
                    in
                    if String.startsWith opaqueVariantsKeyword text2 then
                        ( Rule.error
                            { message =
                                opaqueVariantsKeyword
                                    ++ " isn't valid for functions. It can only be used for custom types. Remove this or use "
                                    ++ opaqueKeyword
                                    ++ " instead."
                            , details = []
                            }
                            range
                            :: errors
                        , context
                        )

                    else if String.startsWith opaqueKeyword text2 then
                        ( errors
                        , { context
                            | opaqueFunctionsAndValues =
                                Set.insert
                                    ( context.moduleName
                                    , function.declaration |> Node.value |> .name |> Node.value
                                    )
                                    context.opaqueFunctionsAndValues
                          }
                        )

                    else
                        ( errors, context )

                Nothing ->
                    ( errors, context )

        CustomTypeDeclaration customType ->
            case customType.documentation of
                Just (Node _ text) ->
                    let
                        text2 =
                            stringDropPrefix "{-|" text |> String.trim
                    in
                    if String.startsWith opaqueVariantsKeyword text2 then
                        ( []
                        , { context
                            | opaqueFunctionsAndValues =
                                List.foldl
                                    (\(Node _ constructor) set ->
                                        Set.insert ( context.moduleName, Node.value constructor.name ) set
                                    )
                                    context.opaqueFunctionsAndValues
                                    customType.constructors
                          }
                        )

                    else if String.startsWith opaqueKeyword text2 then
                        ( []
                        , { context
                            | opaqueTypes =
                                Set.insert
                                    ( context.moduleName, Node.value customType.name )
                                    context.opaqueTypes
                            , opaqueFunctionsAndValues =
                                List.foldl
                                    (\(Node _ constructor) set ->
                                        Set.insert ( context.moduleName, Node.value constructor.name ) set
                                    )
                                    context.opaqueFunctionsAndValues
                                    customType.constructors
                          }
                        )

                    else
                        ( [], context )

                Nothing ->
                    ( [], context )

        PortDeclaration _ ->
            ( [], context )

        InfixDeclaration _ ->
            ( [], context )


stringDropPrefix : String -> String -> String
stringDropPrefix prefix text =
    if String.startsWith prefix text then
        String.dropLeft (String.length prefix) text

    else
        text


typeAnnotationVisitor : ModuleContext -> Node TypeAnnotation -> List (Rule.Error {})
typeAnnotationVisitor context typeAnnotation =
    case Node.value typeAnnotation of
        GenericType _ ->
            []

        Typed (Node range ( _, name )) nodes ->
            let
                error : List (Rule.Error {})
                error =
                    case Review.ModuleNameLookupTable.moduleNameAt context.lookupTable range of
                        Just actualModuleName ->
                            if actualModuleName == context.moduleName then
                                []

                            else if Set.member ( actualModuleName, name ) context.opaqueTypes then
                                [ opaqueError "type" range ]

                            else
                                []

                        Nothing ->
                            []
            in
            error ++ List.concatMap (typeAnnotationVisitor context) nodes

        Unit ->
            []

        Tupled nodes ->
            List.concatMap (typeAnnotationVisitor context) nodes

        Record fields ->
            List.concatMap (\(Node _ ( _, field )) -> typeAnnotationVisitor context field) fields

        GenericRecord _ (Node _ fields) ->
            List.concatMap (\(Node _ ( _, field )) -> typeAnnotationVisitor context field) fields

        FunctionTypeAnnotation a b ->
            typeAnnotationVisitor context a ++ typeAnnotationVisitor context b


expressionVisitor : Node Expression -> ModuleContext -> ( List (Rule.Error {}), ModuleContext )
expressionVisitor expression context =
    ( case Node.value expression of
        UnitExpr ->
            []

        Application nodes ->
            []

        OperatorApplication _ _ _ _ ->
            []

        FunctionOrValue _ name ->
            case Review.ModuleNameLookupTable.moduleNameFor context.lookupTable expression of
                Just actualModuleName ->
                    if context.moduleName == actualModuleName then
                        []

                    else if Set.member ( actualModuleName, name ) context.opaqueFunctionsAndValues then
                        [ opaqueError
                            (if String.left 1 name == String.toUpper (String.left 1 name) then
                                "custom type variant"

                             else
                                "function"
                            )
                            (Node.range expression)
                        ]

                    else
                        []

                Nothing ->
                    []

        IfBlock _ _ _ ->
            []

        PrefixOperator string ->
            []

        Operator string ->
            []

        Integer int ->
            []

        Hex int ->
            []

        Floatable float ->
            []

        Negation node ->
            []

        Literal string ->
            []

        CharLiteral char ->
            []

        TupledExpression nodes ->
            []

        ParenthesizedExpression node ->
            []

        LetExpression letBlock ->
            List.concatMap
                (\(Node _ declaration) ->
                    case declaration of
                        LetDestructuring pattern _ ->
                            patternVisitor context pattern

                        LetFunction _ ->
                            []
                )
                letBlock.declarations

        CaseExpression caseBlock ->
            List.concatMap (\( pattern, _ ) -> patternVisitor context pattern) caseBlock.cases

        LambdaExpression lambda ->
            List.concatMap (patternVisitor context) lambda.args

        RecordExpr nodes ->
            []

        ListExpr nodes ->
            []

        RecordAccess _ _ ->
            []

        RecordAccessFunction string ->
            []

        RecordUpdateExpression node nodes ->
            []

        GLSLExpression string ->
            []
    , context
    )


patternVisitor : ModuleContext -> Node Pattern -> List (Rule.Error {})
patternVisitor context pattern =
    case Node.value pattern of
        AllPattern ->
            []

        UnitPattern ->
            []

        CharPattern _ ->
            []

        StringPattern _ ->
            []

        IntPattern _ ->
            []

        HexPattern _ ->
            []

        FloatPattern _ ->
            []

        TuplePattern nodes ->
            List.concatMap (patternVisitor context) nodes

        RecordPattern _ ->
            []

        UnConsPattern nodeA nodeB ->
            patternVisitor context nodeA ++ patternVisitor context nodeB

        ListPattern nodes ->
            List.concatMap (patternVisitor context) nodes

        VarPattern _ ->
            []

        NamedPattern qualifiedRef nodes ->
            (case Review.ModuleNameLookupTable.moduleNameFor context.lookupTable pattern of
                Just actualModuleName ->
                    if context.moduleName == actualModuleName then
                        []

                    else if
                        Set.member
                            ( actualModuleName, qualifiedRef.name )
                            context.opaqueFunctionsAndValues
                    then
                        [ opaqueError "type" (Node.range pattern) ]

                    else
                        []

                Nothing ->
                    []
            )
                ++ List.concatMap (patternVisitor context) nodes

        AsPattern node _ ->
            patternVisitor context node

        ParenthesizedPattern node ->
            patternVisitor context node


opaqueError : String -> Range -> Rule.Error {}
opaqueError name range =
    Rule.error
        { message =
            "This " ++ name ++ " is marked as opaque and can't be used outside of the module it's defined in."
        , details = [ "Elm already has it's own syntax for marking types as exposed or opaque but unfortunately Lamdera requires a lot of types to be exposed in order for migrations to work. This is a work around to still have a form of opaque types even if they aren't technically opaque." ]
        }
        range
