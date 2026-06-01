internal import CclangWrapper

// MARK: Customized Types

internal protocol FunctionLikeDecl: ClangCursorBacked {}

public struct FunctionDecl: Cursor, ClangCursorBacked, FunctionLikeCursor {
    let clang: CXCursor

    init(clang: CXCursor) {
        self.clang = clang
    }

    /// Tells if the function declaration is inlined.
    public var isInlined: Bool {
        return clang_Cursor_isFunctionInlined(clang) != 0
    }
}

/// Common protocol for cursor kinds that represent a callable function-like
/// declaration (regular function, ObjC method, C++ method, ObjC message
/// expression, function call expression).
public protocol FunctionLikeCursor: Cursor {}

extension FunctionLikeCursor {
    /// Retrieve the number of arguments declared on this function-like cursor.
    /// Returns 0 for cursors that do not have a parameter list.
    public var argumentCount: Int {
        return Int(clang_Cursor_getNumArguments(clangCursor))
    }

    /// Retrieve the parameter cursor at `index`, or `nil` when out of range.
    public func parameter(at index: Int) -> Cursor? {
        return convertCursor(clang_Cursor_getArgument(clangCursor, UInt32(index)))
    }

    /// All parameter cursors, in declaration order.
    public var parameters: [Cursor] {
        let count = argumentCount
        var result: [Cursor] = []
        result.reserveCapacity(count)
        for index in 0..<count {
            if let parameter = parameter(at: index) {
                result.append(parameter)
            }
        }
        return result
    }

    /// The return / result type of the function-like cursor, when available.
    public var resultType: CType? {
        return convertType(clang_getCursorResultType(clangCursor))
    }

    /// Whether the function-like cursor accepts a variadic argument list.
    public var isVariadic: Bool {
        return clang_Cursor_isVariadic(clangCursor) != 0
    }
}

/// Common protocol for cursor kinds that represent ObjC or C++ method
/// declarations.
public protocol MethodDecl: FunctionLikeCursor {}
extension MethodDecl {
    /// Determine the set of methods that are overridden by the given method.
    /// In both Objective-C and C++, a method (aka virtual member function, in
    /// C++) can override a virtual method in a base class. For Objective-C, a
    /// method is said to override any method in the class's base class, its
    /// protocols, or its categories' protocols, that has the same selector and
    /// is of the same kind (class or instance). If no such method exists, the
    /// search continues to the class's superclass, its protocols, and its
    /// categories, and so on. A method from an Objective-C implementation is
    /// considered to override the same methods as its corresponding method in
    /// the interface.
    ///
    /// For C++, a virtual member function overrides any virtual member function
    /// with the same signature that occurs in its base classes. With multiple
    /// inheritance, a virtual member function can override several virtual
    /// member functions coming from different base classes.
    ///
    /// In all cases, this will return the immediate overridden method,
    /// rather than all of the overridden methods. For example, if a method is
    /// originally declared in a class A, then overridden in B (which in
    /// inherits from A) and also in C (which inherited from B), then the only
    /// overridden method returned from this function when invoked on C's method
    /// will be B's method. The client may then invoke this function again,
    /// given the previously-found overridden methods, to map out the complete
    /// method-override set.
    public var overrides: [Cursor] {
        var overridden: UnsafeMutablePointer<CXCursor>?
        var overrideCount = 0 as UInt32
        clang_getOverriddenCursors(clangCursor, &overridden, &overrideCount)
        guard let overriddenPtr = overridden else { return [] }
        var overrides = [Cursor]()
        for i in 0 ..< Int(overrideCount) {
            if let cursor = convertCursor(overriddenPtr[i]) {
                overrides.append(cursor)
            }
        }
        clang_disposeOverriddenCursors(overridden)
        return overrides
    }
}

/// A `#include` directive.
public struct InclusionDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor

    /// Retrieve the file that is included by the given inclusion directive.
    public var includedFile: File? {
        clang_getIncludedFile(clangCursor).map { File(clang: $0) }
    }
}

/// Common protocol for "record types", i.e. structs, classes, and Objective-C
/// classes.
protocol RecordDecl: Cursor, ClangCursorBacked {}
extension RecordDecl {
    /// Retrieves an array of all the fields of this record type.
    public func fields() -> [Cursor] {
        guard let type = type as? RecordType else { return [] }
        return type.fields()
    }
}

public struct StructDecl: Cursor, RecordDecl {
    let clang: CXCursor
}

public struct ClassDecl: Cursor, RecordDecl {
    let clang: CXCursor
}

public struct EnumConstantDecl: Cursor, ClangCursorBacked {
    let clang: CXCursor

    /// Retrieve the integer value of an enum constant declaration as an `Int`.
    public var value: Int {
        return Int(clang_getEnumConstantDeclValue(clang))
    }

    /// Retrieve the integer value of an enum constant declaration as a `UInt`.
    public var unsignedValue: UInt {
        return UInt(clang_getEnumConstantDeclUnsignedValue(clang))
    }
}

protocol MacroCursor: ClangCursorBacked {}
extension MacroCursor {
    /// Determine whether a macro is function like.
    public var isFunctionLike: Bool {
        return clang_Cursor_isMacroFunctionLike(clang) != 0
    }

    /// Determine whether a macro is a built-in macro.
    public var isBuiltin: Bool {
        return clang_Cursor_isMacroBuiltin(clang) != 0
    }
}

public struct MacroExpansion: Cursor, MacroCursor {
    let clang: CXCursor
}

public struct MacroInstantiation: Cursor, MacroCursor {
    let clang: CXCursor
}

public struct MacroDefinition: Cursor, MacroCursor {
    let clang: CXCursor
}

/// An access specifier.
public struct CXXAccessSpecifier: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct EnumDecl: Cursor, ClangCursorBacked {
    let clang: CXCursor

    /// Retrieves an array of all the constants as part of this enum.
    public func constants() -> [EnumConstantDecl] {
        return children().compactMap { $0 as? EnumConstantDecl }
    }

    /// Retrieve the integer type of an enum declaration.
    public var integerType: CType {
        get throws {
            guard let type = convertType(clang_getEnumDeclIntegerType(clang)) else {
                throw ClangError.unexpectedValue
            }
            return type
        }
    }
}

protocol TypeAliasCursor: ClangCursorBacked {}
extension TypeAliasCursor {
    /// Retrieve the underlying type of a typedef declaration.
    public var underlying: CType? {
        return convertType(clang_getTypedefDeclUnderlyingType(clang))
    }
}

public struct TypedefDecl: Cursor, TypeAliasCursor { let clang: CXCursor }
public struct TypeAliasDecl: Cursor, TypeAliasCursor { let clang: CXCursor }
public struct UsingDirective: Cursor, TypeAliasCursor { let clang: CXCursor }
public struct UsingDeclaration: Cursor, TypeAliasCursor { let clang: CXCursor }

// MARK: Standard Types

/// Unexposed declarations have the same operations as any other kind of
/// declaration; one can extract their location information, spelling, find
/// their definitions, etc. However, the specific kind of the declaration is not
/// reported.
/// A declaration whose specific kind is not exposed via this interface.
public struct UnexposedDecl: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A C or C++ union.
public struct UnionDecl: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A field (in C) or non-static data member (in C++) in a struct, union, or C++
/// class.
public struct FieldDecl: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A variable.
public struct VarDecl: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A function or method parameter.
public struct ParmDecl: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// An Objective-C @interface.
public struct ObjCInterfaceDecl: Cursor, ClangCursorBacked {
    let clang: CXCursor

    /// The superclass reference cursor, when this interface has a declared
    /// superclass. Returns `nil` for root classes (e.g. `NSObject`).
    public var superclassReference: ObjCSuperClassRef? {
        firstChild(of: self)
    }

    /// Spelling of the superclass, when present (e.g. `"NSResponder"`).
    public var superclassName: String? {
        return superclassReference?.description
    }

    /// All protocols this interface conforms to, in source order.
    public var conformedProtocolReferences: [ObjCProtocolRef] {
        childrenOfType(of: self)
    }

    /// Spellings of all protocols this interface conforms to, in source order.
    public var conformedProtocolNames: [String] {
        return conformedProtocolReferences.map(\.description)
    }
}

/// An Objective-C @interface for a category.
public struct ObjCCategoryDecl: Cursor, ClangCursorBacked {
    let clang: CXCursor

    /// The class the category extends, or `nil` if not resolvable.
    public var declaringClassReference: ObjCClassRef? {
        firstChild(of: self)
    }

    /// Spelling of the class the category extends, or `nil` when missing.
    public var declaringClassName: String? {
        return declaringClassReference?.description
    }

    /// The protocols this category brings in, in source order.
    public var conformedProtocolReferences: [ObjCProtocolRef] {
        childrenOfType(of: self)
    }

    /// Spellings of the protocols this category brings in, in source order.
    public var conformedProtocolNames: [String] {
        return conformedProtocolReferences.map(\.description)
    }
}

/// An Objective-C @protocol declaration.
public struct ObjCProtocolDecl: Cursor, ClangCursorBacked {
    let clang: CXCursor

    /// Protocols this protocol inherits from, in source order.
    public var inheritedProtocolReferences: [ObjCProtocolRef] {
        childrenOfType(of: self)
    }

    /// Spellings of protocols this protocol inherits from, in source order.
    public var inheritedProtocolNames: [String] {
        return inheritedProtocolReferences.map(\.description)
    }
}

/// An Objective-C @property declaration.
public struct ObjCPropertyDecl: Cursor, ClangCursorBacked {
    let clang: CXCursor

    public var attributes: ObjCPropertyAttributes {
        return ObjCPropertyAttributes(rawValue:
            clang_Cursor_getObjCPropertyAttributes(clang, 0))
    }

    /// The custom getter selector (e.g. `isHidden`), when the property uses
    /// `getter=`. Returns `nil` if the property uses the default getter.
    public var customGetterName: String? {
        guard attributes.contains(.getter) else { return nil }
        let spelling = clang_Cursor_getObjCPropertyGetterName(clang).asSwift()
        return spelling.isEmpty ? nil : spelling
    }

    /// The custom setter selector (e.g. `setHidden:`), when the property uses
    /// `setter=`. Returns `nil` if the property uses the default setter.
    public var customSetterName: String? {
        guard attributes.contains(.setter) else { return nil }
        let spelling = clang_Cursor_getObjCPropertySetterName(clang).asSwift()
        return spelling.isEmpty ? nil : spelling
    }

    /// Raw bitmask of Objective-C-specific declaration qualifiers (`in`,
    /// `inout`, `bycopy`, etc.). Returns 0 when none apply.
    public var declQualifiers: UInt32 {
        return clang_Cursor_getObjCDeclQualifiers(clang)
    }
}

/// An Objective-C instance variable.
public struct ObjCIvarDecl: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// An Objective-C instance method.
public struct ObjCInstanceMethodDecl: Cursor, ClangCursorBacked, MethodDecl {
    let clang: CXCursor
}

/// An Objective-C class method.
public struct ObjCClassMethodDecl: Cursor, ClangCursorBacked, MethodDecl {
    let clang: CXCursor
}

/// An Objective-C @implementation.
public struct ObjCImplementationDecl: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// An Objective-C @implementation for a category.
public struct ObjCCategoryImplDecl: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A C++ class method.
public struct CXXMethod: Cursor, ClangCursorBacked, MethodDecl {
    let clang: CXCursor
}

/// A C++ namespace.
public struct Namespace: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A linkage specification, e.g. 'extern "C"'.
public struct LinkageSpec: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A C++ constructor.
public struct Constructor: Cursor, ClangCursorBacked, MethodDecl {
    let clang: CXCursor
}

/// A C++ destructor.
public struct Destructor: Cursor, ClangCursorBacked, MethodDecl {
    let clang: CXCursor
}

/// A C++ conversion function.
public struct ConversionFunction: Cursor, ClangCursorBacked, MethodDecl {
    let clang: CXCursor
}

/// A C++ template type parameter.
public struct TemplateTypeParameter: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A C++ non-type template parameter.
public struct NonTypeTemplateParameter: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A C++ template template parameter.
public struct TemplateTemplateParameter: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A C++ function template.
public struct FunctionTemplate: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A C++ class template.
public struct ClassTemplate: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A C++ class template partial specialization.
public struct ClassTemplatePartialSpecialization: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A C++ namespace alias declaration.
public struct NamespaceAlias: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// An Objective-C @synthesize definition.
public struct ObjCSynthesizeDecl: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// An Objective-C @dynamic definition.
public struct ObjCDynamicDecl: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct ObjCSuperClassRef: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct ObjCProtocolRef: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct ObjCClassRef: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A reference to a type declaration.
/// A type reference occurs anywhere where a type is named but not declared. For
/// example, given:
/// ```
/// typedef unsigned size_type;
/// size_type size;
/// ```
/// The typedef is a declaration of size_type (CXCursor_TypedefDecl), while the
/// type of the variable "size" is referenced. The cursor referenced by the type
/// of size is the typedef for size_type.
public struct TypeRef: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct CXXBaseSpecifier: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A reference to a class template, function template, template
/// parameter, or class template partial specialization.
public struct TemplateRef: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A reference to a namespace or namespace alias.
public struct NamespaceRef: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A reference to a member of a struct, union, or class that occurs in some
/// non-expression context, e.g., a designated initializer.
public struct MemberRef: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A reference to a labeled statement.
/// This cursor kind is used to describe the jump to "start_over" in the goto
/// statement in the following example:
/// ```
/// start_over:
/// ++counter;
///
/// goto start_over;
/// ```
/// A label reference cursor refers to a label statement.
public struct LabelRef: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A reference to a set of overloaded functions or function templates that has
/// not yet been resolved to a specific function or function template.
/// An overloaded declaration reference cursor occurs in C++ templates where a
/// dependent name refers to a function. For example:
/// ```
/// template<typename T> void swap(T&, T&);
///
/// struct Y { };
/// void swap(Y&, Y&);
/// ```
/// Here, the identifier "swap" is associated with an overloaded declaration
/// reference. In the template definition, "swap" refers to either of the two
/// "swap" functions declared above, so both results will be available. At
/// instantiation time, "swap" may also refer to other functions found via
/// argument-dependent lookup (e.g., the "swap" function at the end of the
/// example).
public struct OverloadedDeclRef: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A reference to a variable that occurs in some non-expression context, e.g.,
/// a C++ lambda capture list.
public struct VariableRef: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct InvalidFile: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct NoDeclFound: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct NotImplemented: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct InvalidCode: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// An expression whose specific kind is not exposed via this interface.
/// Unexposed expressions have the same operations as any other kind of
/// expression; one can extract their location information, spelling, children,
/// etc. However, the specific kind of the expression is not reported.
public struct UnexposedExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// An expression that refers to some value declaration, such as a function,
/// variable, or enumerator.
public struct DeclRefExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// An expression that refers to a member of a struct, union, class, Objective-C
/// class, etc.
public struct MemberRefExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// An expression that calls a function.
public struct CallExpr: Cursor, ClangCursorBacked, FunctionLikeCursor {
    let clang: CXCursor
}

/// An expression that sends a message to an Objective-C object or class.
public struct ObjCMessageExpr: Cursor, ClangCursorBacked, FunctionLikeCursor {
    let clang: CXCursor
}

/// An expression that represents a block literal.
public struct BlockExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// An integer literal.
public struct IntegerLiteral: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A floating point number literal.
public struct FloatingLiteral: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// An imaginary number literal.
public struct ImaginaryLiteral: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A string literal.
public struct StringLiteral: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A character literal.
public struct CharacterLiteral: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A parenthesized expression, e.g. "(1)".
/// - note: This AST node is only formed if full location information is
///         requested.
public struct ParenExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// This represents the unary-expression's (except sizeof and alignof).
public struct UnaryOperator: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// [C99 6.5.2.1] Array Subscripting.
public struct ArraySubscriptExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A builtin binary operation expression such as "x + y" or "x <= y".
public struct BinaryOperator: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// Compound assignment such as "+=".
public struct CompoundAssignOperator: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// The ?: ternary operator.
public struct ConditionalOperator: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// An explicit cast in C (C99 6.5.4) or a C-style cast in C++ (C++
/// [expr.cast]), which uses the syntax (Type)expr.
/// For example: `(int)f`.
public struct CStyleCastExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// [C99 6.5.2.5]
public struct CompoundLiteralExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// Describes an C or C++ initializer list.
public struct InitListExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// The GNU address of label extension, representing &&label.
public struct AddrLabelExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// This is the GNU Statement Expression extension: ({int X=4; X;})
public struct StmtExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// Represents a C11 generic selection.
public struct GenericSelectionExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// Implements the GNU `__null` extension, which is a name for a null pointer
/// constant that has integral type (e.g., int or long) and is the same size and
/// alignment as a pointer.
/// The `__null extension` is typically only used by system headers, which define
/// `NULL` as `__null` in C++ rather than using 0 (which is an integer that may
/// not match the size of a pointer).
public struct GNUNullExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// C++'s static_cast<> expression.
public struct CXXStaticCastExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// C++'s dynamic_cast<> expression.
public struct CXXDynamicCastExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// C++'s reinterpret_cast<> expression.
public struct CXXReinterpretCastExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// C++'s const_cast<> expression.
public struct CXXConstCastExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// Represents an explicit C++ type conversion that uses "functional" notion
/// (C++ [expr.type.conv]).
/// Example:
/// ```
/// x = int(0.5);
/// ```
public struct CXXFunctionalCastExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A C++ typeid expression (C++ [expr.typeid]).
public struct CXXTypeidExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// [C++ 2.13.5] C++ Boolean Literal.
public struct CXXBoolLiteralExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// [C++0x 2.14.7] C++ Pointer Literal.
public struct CXXNullPtrLiteralExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// Represents the "this" expression in C++
public struct CXXThisExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// This handles 'throw' and 'throw' assignment-expression. When
/// assignment-expression isn't present, Op will be null.
/// [C++ 15] C++ Throw Expression.
public struct CXXThrowExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A new expression for memory allocation and constructor calls, e.g: "new
/// CXXNewExpr(foo)".
public struct CXXNewExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A delete expression for memory deallocation and destructor calls, e.g.
/// "delete[] pArray".
public struct CXXDeleteExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A unary expression. (noexcept, sizeof, or other traits)
public struct UnaryExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// An Objective-C string literal i.e. "foo".
public struct ObjCStringLiteral: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// An Objective-C @encode expression.
public struct ObjCEncodeExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// An Objective-C @selector expression.
public struct ObjCSelectorExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// An Objective-C @protocol expression.
public struct ObjCProtocolExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// An Objective-C "bridged" cast expression, which casts between Objective-C
/// pointers and C pointers, transferring ownership in the process.
/// ```
/// NSString *str = (__bridge_transfer NSString *)CFCreateString();
/// ```
public struct ObjCBridgedCastExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// Represents a C++0x pack expansion that produces a sequence of expressions.
/// A pack expansion expression contains a pattern (which itself is an
/// expression) followed by an ellipsis. For example:
/// ```
/// template<typename F, typename ...Types>
/// void forward(F f, Types &&...args) {
/// f(static_cast<Types&&>(args)...);
/// }
/// ```
public struct PackExpansionExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// Represents an expression that computes the length of a parameter pack.
/// ```
/// template<typename ...Types>
/// struct count {
/// static const unsigned value = sizeof...(Types);
/// };
/// ```
public struct SizeOfPackExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct LambdaExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// Objective-c Boolean Literal.
public struct ObjCBoolLiteralExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// Represents the "self" expression in an Objective-C method.
public struct ObjCSelfExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP 4.0 [2.4, Array Section].
public struct OMPArraySectionExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// Represents an @available(...) check.
public struct ObjCAvailabilityCheckExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// Unexposed statements have the same operations as any other kind of
/// statement; one can extract their location information, spelling, children,
/// etc. However, the specific kind of the statement is not reported.
/// A statement whose specific kind is not exposed via this interface.
public struct UnexposedStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A labelled statement in a function.
/// This cursor kind is used to describe the "start_over:" label statement in
/// the following example:
/// ```
/// start_over:
/// ++counter;
/// ```
public struct LabelStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A group of statements like { stmt stmt }.
/// This cursor kind is used to describe compound statements, e.g. function
/// bodies.
public struct CompoundStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A case statement.
public struct CaseStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A default statement.
public struct DefaultStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// An if statement
public struct IfStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A switch statement.
public struct SwitchStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A while statement.
public struct WhileStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A do statement.
public struct DoStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A for statement.
public struct ForStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A goto statement.
public struct GotoStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// An indirect goto statement.
public struct IndirectGotoStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A continue statement.
public struct ContinueStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A break statement.
public struct BreakStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A return statement.
public struct ReturnStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A GCC inline assembly statement extension.
public struct GCCAsmStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A GCC inline assembly statement extension.
public struct AsmStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// Objective-C's overall @try-@catch-@finally statement.
public struct ObjCAtTryStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// Objective-C's @catch statement.
public struct ObjCAtCatchStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// Objective-C's @finally statement.
public struct ObjCAtFinallyStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// Objective-C's @throw statement.
public struct ObjCAtThrowStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// Objective-C's @synchronized statement.
public struct ObjCAtSynchronizedStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// Objective-C's autorelease pool statement.
public struct ObjCAutoreleasePoolStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// Objective-C's collection statement.
public struct ObjCForCollectionStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// C++'s catch statement.
public struct CXXCatchStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// C++'s try statement.
public struct CXXTryStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// C++'s for (* : *) statement.
public struct CXXForRangeStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// Windows Structured Exception Handling's try statement.
public struct SEHTryStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// Windows Structured Exception Handling's except statement.
public struct SEHExceptStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// Windows Structured Exception Handling's finally statement.
public struct SEHFinallyStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A MS inline assembly statement extension.
public struct MSAsmStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// This cursor kind is used to describe the null statement.
/// The null statement ";": C99 6.8.3p3.
public struct NullStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// Adaptor class for mixing declarations with statements and expressions.
public struct DeclStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP parallel directive.
public struct OMPParallelDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP SIMD directive.
public struct OMPSimdDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP for directive.
public struct OMPForDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP sections directive.
public struct OMPSectionsDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP section directive.
public struct OMPSectionDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP single directive.
public struct OMPSingleDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP parallel for directive.
public struct OMPParallelForDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP parallel sections directive.
public struct OMPParallelSectionsDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP task directive.
public struct OMPTaskDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP master directive.
public struct OMPMasterDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP critical directive.
public struct OMPCriticalDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP taskyield directive.
public struct OMPTaskyieldDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP barrier directive.
public struct OMPBarrierDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP taskwait directive.
public struct OMPTaskwaitDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP flush directive.
public struct OMPFlushDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// Windows Structured Exception Handling's leave statement.
public struct SEHLeaveStmt: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP ordered directive.
public struct OMPOrderedDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP atomic directive.
public struct OMPAtomicDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP for SIMD directive.
public struct OMPForSimdDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP parallel for SIMD directive.
public struct OMPParallelForSimdDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP target directive.
public struct OMPTargetDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP teams directive.
public struct OMPTeamsDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP taskgroup directive.
public struct OMPTaskgroupDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP cancellation point directive.
public struct OMPCancellationPointDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP cancel directive.
public struct OMPCancelDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP target data directive.
public struct OMPTargetDataDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP taskloop directive.
public struct OMPTaskLoopDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP taskloop simd directive.
public struct OMPTaskLoopSimdDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP distribute directive.
public struct OMPDistributeDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP target enter data directive.
public struct OMPTargetEnterDataDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP target exit data directive.
public struct OMPTargetExitDataDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP target parallel directive.
public struct OMPTargetParallelDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP target parallel for directive.
public struct OMPTargetParallelForDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP target update directive.
public struct OMPTargetUpdateDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP distribute parallel for directive.
public struct OMPDistributeParallelForDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP distribute parallel for simd directive.
public struct OMPDistributeParallelForSimdDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP distribute simd directive.
public struct OMPDistributeSimdDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// OpenMP target parallel for simd directive.
public struct OMPTargetParallelForSimdDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// Cursor that represents the translation unit itself.
/// The translation unit cursor exists primarily to act as the root cursor for
/// traversing the contents of a translation unit.
public struct TranslationUnitCursor: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct UnexposedAttr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct IBActionAttr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct IBOutletAttr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct IBOutletCollectionAttr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct CXXFinalAttr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct CXXOverrideAttr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct AnnotateAttr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct AsmLabelAttr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct PackedAttr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct PureAttr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct ConstAttr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct NoDuplicateAttr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct CUDAConstantAttr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct CUDADeviceAttr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct CUDAGlobalAttr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct CUDAHostAttr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct CUDASharedAttr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct VisibilityAttr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct DLLExport: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct DLLImport: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct PreprocessingDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A module import declaration.
public struct ModuleImportDecl: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

public struct TypeAliasTemplateDecl: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A static_assert or _Static_assert node
public struct StaticAssert: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A code completion overload candidate.
public struct OverloadCandidate: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

// MARK: Attribute Types

/// A aligned  attr.
public struct AlignedAttr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A convergent  attr.
public struct ConvergentAttr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A warn  unused  attr.
public struct WarnUnusedAttr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A warn  unused  result  attr.
public struct WarnUnusedResultAttr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

// MARK: Declaration Types

/// A concept  decl.
public struct ConceptDecl: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A friend  decl.
public struct FriendDecl: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

// MARK: Directive Types

/// A omp  assume  directive.
public struct OMPAssumeDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  depobj  directive.
public struct OMPDepobjDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  dispatch  directive.
public struct OMPDispatchDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  error  directive.
public struct OMPErrorDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  generic  loop  directive.
public struct OMPGenericLoopDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  interchange  directive.
public struct OMPInterchangeDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  interop  directive.
public struct OMPInteropDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  masked  directive.
public struct OMPMaskedDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  masked  task  loop  directive.
public struct OMPMaskedTaskLoopDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  masked  task  loop  simd  directive.
public struct OMPMaskedTaskLoopSimdDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  master  task  loop  directive.
public struct OMPMasterTaskLoopDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  master  task  loop  simd  directive.
public struct OMPMasterTaskLoopSimdDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  meta  directive.
public struct OMPMetaDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  parallel  generic  loop  directive.
public struct OMPParallelGenericLoopDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  parallel  masked  directive.
public struct OMPParallelMaskedDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  parallel  masked  task  loop  directive.
public struct OMPParallelMaskedTaskLoopDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  parallel  masked  task  loop  simd  directive.
public struct OMPParallelMaskedTaskLoopSimdDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  parallel  master  directive.
public struct OMPParallelMasterDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  parallel  master  task  loop  directive.
public struct OMPParallelMasterTaskLoopDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  parallel  master  task  loop  simd  directive.
public struct OMPParallelMasterTaskLoopSimdDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  reverse  directive.
public struct OMPReverseDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  scan  directive.
public struct OMPScanDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  scope  directive.
public struct OMPScopeDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  target  parallel  generic  loop  directive.
public struct OMPTargetParallelGenericLoopDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  target  simd  directive.
public struct OMPTargetSimdDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  target  teams  directive.
public struct OMPTargetTeamsDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  target  teams  distribute  directive.
public struct OMPTargetTeamsDistributeDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  target  teams  distribute  parallel  for  directive.
public struct OMPTargetTeamsDistributeParallelForDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  target  teams  distribute  parallel  for  simd  directive.
public struct OMPTargetTeamsDistributeParallelForSimdDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  target  teams  distribute  simd  directive.
public struct OMPTargetTeamsDistributeSimdDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  target  teams  generic  loop  directive.
public struct OMPTargetTeamsGenericLoopDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  teams  distribute  directive.
public struct OMPTeamsDistributeDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  teams  distribute  parallel  for  directive.
public struct OMPTeamsDistributeParallelForDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  teams  distribute  parallel  for  simd  directive.
public struct OMPTeamsDistributeParallelForSimdDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  teams  distribute  simd  directive.
public struct OMPTeamsDistributeSimdDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  teams  generic  loop  directive.
public struct OMPTeamsGenericLoopDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  tile  directive.
public struct OMPTileDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  unroll  directive.
public struct OMPUnrollDirective: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

// MARK: Expression Types

/// A array  section  expr.
public struct ArraySectionExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A builtin  bit  cast  expr.
public struct BuiltinBitCastExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A cxx  addrspace  cast  expr.
public struct CXXAddrspaceCastExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A cxx  paren  list  init  expr.
public struct CXXParenListInitExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A concept  specialization  expr.
public struct ConceptSpecializationExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  array  shaping  expr.
public struct OMPArrayShapingExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  iterator  expr.
public struct OMPIteratorExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A pack  indexing  expr.
public struct PackIndexingExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A requires  expr.
public struct RequiresExpr: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

// MARK: Literal Types

/// A fixed  point  literal.
public struct FixedPointLiteral: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A flag  enum.
public struct FlagEnum: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A ns  consumed.
public struct NSConsumed: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A ns  consumes  self.
public struct NSConsumesSelf: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A ns  returns  autoreleased.
public struct NSReturnsAutoreleased: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A ns  returns  not  retained.
public struct NSReturnsNotRetained: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A ns  returns  retained.
public struct NSReturnsRetained: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A omp  canonical  loop.
public struct OMPCanonicalLoop: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A obj c  boxable.
public struct ObjCBoxable: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A obj c  designated  initializer.
public struct ObjCDesignatedInitializer: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A obj c  exception.
public struct ObjCException: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A obj c  explicit  protocol  impl.
public struct ObjCExplicitProtocolImpl: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A obj c  independent  class.
public struct ObjCIndependentClass: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A obj cns  object.
public struct ObjCNSObject: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A obj c  precise  lifetime.
public struct ObjCPreciseLifetime: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A obj c  requires  super.
public struct ObjCRequiresSuper: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A obj c  returns  inner  pointer.
public struct ObjCReturnsInnerPointer: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A obj c  root  class.
public struct ObjCRootClass: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A obj c  runtime  visible.
public struct ObjCRuntimeVisible: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A obj c  subclassing  restricted.
public struct ObjCSubclassingRestricted: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A open acc  compute  construct.
public struct OpenACCComputeConstruct: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// A open acc  loop  construct.
public struct OpenACCLoopConstruct: Cursor, ClangCursorBacked {
    let clang: CXCursor
}

/// Converts a CXCursor to a Cursor, returning `nil` if it was unsuccessful
func convertCursor(_ clang: CXCursor) -> Cursor? {
    if clang_Cursor_isNull(clang) != 0 { return nil }
    switch clang.kind {
    case CXCursor_UnexposedDecl: return UnexposedDecl(clang: clang)
    case CXCursor_StructDecl: return StructDecl(clang: clang)
    case CXCursor_UnionDecl: return UnionDecl(clang: clang)
    case CXCursor_ClassDecl: return ClassDecl(clang: clang)
    case CXCursor_EnumDecl: return EnumDecl(clang: clang)
    case CXCursor_FieldDecl: return FieldDecl(clang: clang)
    case CXCursor_EnumConstantDecl: return EnumConstantDecl(clang: clang)
    case CXCursor_FunctionDecl: return FunctionDecl(clang: clang)
    case CXCursor_VarDecl: return VarDecl(clang: clang)
    case CXCursor_ParmDecl: return ParmDecl(clang: clang)
    case CXCursor_ObjCInterfaceDecl: return ObjCInterfaceDecl(clang: clang)
    case CXCursor_ObjCCategoryDecl: return ObjCCategoryDecl(clang: clang)
    case CXCursor_ObjCProtocolDecl: return ObjCProtocolDecl(clang: clang)
    case CXCursor_ObjCPropertyDecl: return ObjCPropertyDecl(clang: clang)
    case CXCursor_ObjCIvarDecl: return ObjCIvarDecl(clang: clang)
    case CXCursor_ObjCInstanceMethodDecl: return ObjCInstanceMethodDecl(clang: clang)
    case CXCursor_ObjCClassMethodDecl: return ObjCClassMethodDecl(clang: clang)
    case CXCursor_ObjCImplementationDecl: return ObjCImplementationDecl(clang: clang)
    case CXCursor_ObjCCategoryImplDecl: return ObjCCategoryImplDecl(clang: clang)
    case CXCursor_TypedefDecl: return TypedefDecl(clang: clang)
    case CXCursor_CXXMethod: return CXXMethod(clang: clang)
    case CXCursor_Namespace: return Namespace(clang: clang)
    case CXCursor_LinkageSpec: return LinkageSpec(clang: clang)
    case CXCursor_Constructor: return Constructor(clang: clang)
    case CXCursor_Destructor: return Destructor(clang: clang)
    case CXCursor_ConversionFunction: return ConversionFunction(clang: clang)
    case CXCursor_TemplateTypeParameter: return TemplateTypeParameter(clang: clang)
    case CXCursor_NonTypeTemplateParameter: return NonTypeTemplateParameter(clang: clang)
    case CXCursor_TemplateTemplateParameter: return TemplateTemplateParameter(clang: clang)
    case CXCursor_FunctionTemplate: return FunctionTemplate(clang: clang)
    case CXCursor_ClassTemplate: return ClassTemplate(clang: clang)
    case CXCursor_ClassTemplatePartialSpecialization: return ClassTemplatePartialSpecialization(clang: clang)
    case CXCursor_NamespaceAlias: return NamespaceAlias(clang: clang)
    case CXCursor_UsingDirective: return UsingDirective(clang: clang)
    case CXCursor_UsingDeclaration: return UsingDeclaration(clang: clang)
    case CXCursor_TypeAliasDecl: return TypeAliasDecl(clang: clang)
    case CXCursor_ObjCSynthesizeDecl: return ObjCSynthesizeDecl(clang: clang)
    case CXCursor_ObjCDynamicDecl: return ObjCDynamicDecl(clang: clang)
    case CXCursor_CXXAccessSpecifier: return CXXAccessSpecifier(clang: clang)
    case CXCursor_ObjCSuperClassRef: return ObjCSuperClassRef(clang: clang)
    case CXCursor_ObjCProtocolRef: return ObjCProtocolRef(clang: clang)
    case CXCursor_ObjCClassRef: return ObjCClassRef(clang: clang)
    case CXCursor_TypeRef: return TypeRef(clang: clang)
    case CXCursor_CXXBaseSpecifier: return CXXBaseSpecifier(clang: clang)
    case CXCursor_TemplateRef: return TemplateRef(clang: clang)
    case CXCursor_NamespaceRef: return NamespaceRef(clang: clang)
    case CXCursor_MemberRef: return MemberRef(clang: clang)
    case CXCursor_LabelRef: return LabelRef(clang: clang)
    case CXCursor_OverloadedDeclRef: return OverloadedDeclRef(clang: clang)
    case CXCursor_VariableRef: return VariableRef(clang: clang)
    case CXCursor_InvalidFile: return InvalidFile(clang: clang)
    case CXCursor_NoDeclFound: return NoDeclFound(clang: clang)
    case CXCursor_NotImplemented: return NotImplemented(clang: clang)
    case CXCursor_InvalidCode: return InvalidCode(clang: clang)
    case CXCursor_UnexposedExpr: return UnexposedExpr(clang: clang)
    case CXCursor_DeclRefExpr: return DeclRefExpr(clang: clang)
    case CXCursor_MemberRefExpr: return MemberRefExpr(clang: clang)
    case CXCursor_CallExpr: return CallExpr(clang: clang)
    case CXCursor_ObjCMessageExpr: return ObjCMessageExpr(clang: clang)
    case CXCursor_BlockExpr: return BlockExpr(clang: clang)
    case CXCursor_IntegerLiteral: return IntegerLiteral(clang: clang)
    case CXCursor_FloatingLiteral: return FloatingLiteral(clang: clang)
    case CXCursor_ImaginaryLiteral: return ImaginaryLiteral(clang: clang)
    case CXCursor_StringLiteral: return StringLiteral(clang: clang)
    case CXCursor_CharacterLiteral: return CharacterLiteral(clang: clang)
    case CXCursor_ParenExpr: return ParenExpr(clang: clang)
    case CXCursor_UnaryOperator: return UnaryOperator(clang: clang)
    case CXCursor_ArraySubscriptExpr: return ArraySubscriptExpr(clang: clang)
    case CXCursor_BinaryOperator: return BinaryOperator(clang: clang)
    case CXCursor_CompoundAssignOperator: return CompoundAssignOperator(clang: clang)
    case CXCursor_ConditionalOperator: return ConditionalOperator(clang: clang)
    case CXCursor_CStyleCastExpr: return CStyleCastExpr(clang: clang)
    case CXCursor_CompoundLiteralExpr: return CompoundLiteralExpr(clang: clang)
    case CXCursor_InitListExpr: return InitListExpr(clang: clang)
    case CXCursor_AddrLabelExpr: return AddrLabelExpr(clang: clang)
    case CXCursor_StmtExpr: return StmtExpr(clang: clang)
    case CXCursor_GenericSelectionExpr: return GenericSelectionExpr(clang: clang)
    case CXCursor_GNUNullExpr: return GNUNullExpr(clang: clang)
    case CXCursor_CXXStaticCastExpr: return CXXStaticCastExpr(clang: clang)
    case CXCursor_CXXDynamicCastExpr: return CXXDynamicCastExpr(clang: clang)
    case CXCursor_CXXReinterpretCastExpr: return CXXReinterpretCastExpr(clang: clang)
    case CXCursor_CXXConstCastExpr: return CXXConstCastExpr(clang: clang)
    case CXCursor_CXXFunctionalCastExpr: return CXXFunctionalCastExpr(clang: clang)
    case CXCursor_CXXTypeidExpr: return CXXTypeidExpr(clang: clang)
    case CXCursor_CXXBoolLiteralExpr: return CXXBoolLiteralExpr(clang: clang)
    case CXCursor_CXXNullPtrLiteralExpr: return CXXNullPtrLiteralExpr(clang: clang)
    case CXCursor_CXXThisExpr: return CXXThisExpr(clang: clang)
    case CXCursor_CXXThrowExpr: return CXXThrowExpr(clang: clang)
    case CXCursor_CXXNewExpr: return CXXNewExpr(clang: clang)
    case CXCursor_CXXDeleteExpr: return CXXDeleteExpr(clang: clang)
    case CXCursor_UnaryExpr: return UnaryExpr(clang: clang)
    case CXCursor_ObjCStringLiteral: return ObjCStringLiteral(clang: clang)
    case CXCursor_ObjCEncodeExpr: return ObjCEncodeExpr(clang: clang)
    case CXCursor_ObjCSelectorExpr: return ObjCSelectorExpr(clang: clang)
    case CXCursor_ObjCProtocolExpr: return ObjCProtocolExpr(clang: clang)
    case CXCursor_ObjCBridgedCastExpr: return ObjCBridgedCastExpr(clang: clang)
    case CXCursor_PackExpansionExpr: return PackExpansionExpr(clang: clang)
    case CXCursor_SizeOfPackExpr: return SizeOfPackExpr(clang: clang)
    case CXCursor_LambdaExpr: return LambdaExpr(clang: clang)
    case CXCursor_ObjCBoolLiteralExpr: return ObjCBoolLiteralExpr(clang: clang)
    case CXCursor_ObjCSelfExpr: return ObjCSelfExpr(clang: clang)
//    case CXCursor_OMPArraySectionExpr: return OMPArraySectionExpr(clang: clang)
    case CXCursor_ObjCAvailabilityCheckExpr: return ObjCAvailabilityCheckExpr(clang: clang)
    case CXCursor_UnexposedStmt: return UnexposedStmt(clang: clang)
    case CXCursor_LabelStmt: return LabelStmt(clang: clang)
    case CXCursor_CompoundStmt: return CompoundStmt(clang: clang)
    case CXCursor_CaseStmt: return CaseStmt(clang: clang)
    case CXCursor_DefaultStmt: return DefaultStmt(clang: clang)
    case CXCursor_IfStmt: return IfStmt(clang: clang)
    case CXCursor_SwitchStmt: return SwitchStmt(clang: clang)
    case CXCursor_WhileStmt: return WhileStmt(clang: clang)
    case CXCursor_DoStmt: return DoStmt(clang: clang)
    case CXCursor_ForStmt: return ForStmt(clang: clang)
    case CXCursor_GotoStmt: return GotoStmt(clang: clang)
    case CXCursor_IndirectGotoStmt: return IndirectGotoStmt(clang: clang)
    case CXCursor_ContinueStmt: return ContinueStmt(clang: clang)
    case CXCursor_BreakStmt: return BreakStmt(clang: clang)
    case CXCursor_ReturnStmt: return ReturnStmt(clang: clang)
    case CXCursor_GCCAsmStmt: return GCCAsmStmt(clang: clang)
    case CXCursor_AsmStmt: return AsmStmt(clang: clang)
    case CXCursor_ObjCAtTryStmt: return ObjCAtTryStmt(clang: clang)
    case CXCursor_ObjCAtCatchStmt: return ObjCAtCatchStmt(clang: clang)
    case CXCursor_ObjCAtFinallyStmt: return ObjCAtFinallyStmt(clang: clang)
    case CXCursor_ObjCAtThrowStmt: return ObjCAtThrowStmt(clang: clang)
    case CXCursor_ObjCAtSynchronizedStmt: return ObjCAtSynchronizedStmt(clang: clang)
    case CXCursor_ObjCAutoreleasePoolStmt: return ObjCAutoreleasePoolStmt(clang: clang)
    case CXCursor_ObjCForCollectionStmt: return ObjCForCollectionStmt(clang: clang)
    case CXCursor_CXXCatchStmt: return CXXCatchStmt(clang: clang)
    case CXCursor_CXXTryStmt: return CXXTryStmt(clang: clang)
    case CXCursor_CXXForRangeStmt: return CXXForRangeStmt(clang: clang)
    case CXCursor_SEHTryStmt: return SEHTryStmt(clang: clang)
    case CXCursor_SEHExceptStmt: return SEHExceptStmt(clang: clang)
    case CXCursor_SEHFinallyStmt: return SEHFinallyStmt(clang: clang)
    case CXCursor_MSAsmStmt: return MSAsmStmt(clang: clang)
    case CXCursor_NullStmt: return NullStmt(clang: clang)
    case CXCursor_DeclStmt: return DeclStmt(clang: clang)
    case CXCursor_OMPParallelDirective: return OMPParallelDirective(clang: clang)
    case CXCursor_OMPSimdDirective: return OMPSimdDirective(clang: clang)
    case CXCursor_OMPForDirective: return OMPForDirective(clang: clang)
    case CXCursor_OMPSectionsDirective: return OMPSectionsDirective(clang: clang)
    case CXCursor_OMPSectionDirective: return OMPSectionDirective(clang: clang)
    case CXCursor_OMPSingleDirective: return OMPSingleDirective(clang: clang)
    case CXCursor_OMPParallelForDirective: return OMPParallelForDirective(clang: clang)
    case CXCursor_OMPParallelSectionsDirective: return OMPParallelSectionsDirective(clang: clang)
    case CXCursor_OMPTaskDirective: return OMPTaskDirective(clang: clang)
    case CXCursor_OMPMasterDirective: return OMPMasterDirective(clang: clang)
    case CXCursor_OMPCriticalDirective: return OMPCriticalDirective(clang: clang)
    case CXCursor_OMPTaskyieldDirective: return OMPTaskyieldDirective(clang: clang)
    case CXCursor_OMPBarrierDirective: return OMPBarrierDirective(clang: clang)
    case CXCursor_OMPTaskwaitDirective: return OMPTaskwaitDirective(clang: clang)
    case CXCursor_OMPFlushDirective: return OMPFlushDirective(clang: clang)
    case CXCursor_SEHLeaveStmt: return SEHLeaveStmt(clang: clang)
    case CXCursor_OMPOrderedDirective: return OMPOrderedDirective(clang: clang)
    case CXCursor_OMPAtomicDirective: return OMPAtomicDirective(clang: clang)
    case CXCursor_OMPForSimdDirective: return OMPForSimdDirective(clang: clang)
    case CXCursor_OMPParallelForSimdDirective: return OMPParallelForSimdDirective(clang: clang)
    case CXCursor_OMPTargetDirective: return OMPTargetDirective(clang: clang)
    case CXCursor_OMPTeamsDirective: return OMPTeamsDirective(clang: clang)
    case CXCursor_OMPTaskgroupDirective: return OMPTaskgroupDirective(clang: clang)
    case CXCursor_OMPCancellationPointDirective: return OMPCancellationPointDirective(clang: clang)
    case CXCursor_OMPCancelDirective: return OMPCancelDirective(clang: clang)
    case CXCursor_OMPTargetDataDirective: return OMPTargetDataDirective(clang: clang)
    case CXCursor_OMPTaskLoopDirective: return OMPTaskLoopDirective(clang: clang)
    case CXCursor_OMPTaskLoopSimdDirective: return OMPTaskLoopSimdDirective(clang: clang)
    case CXCursor_OMPDistributeDirective: return OMPDistributeDirective(clang: clang)
    case CXCursor_OMPTargetEnterDataDirective: return OMPTargetEnterDataDirective(clang: clang)
    case CXCursor_OMPTargetExitDataDirective: return OMPTargetExitDataDirective(clang: clang)
    case CXCursor_OMPTargetParallelDirective: return OMPTargetParallelDirective(clang: clang)
    case CXCursor_OMPTargetParallelForDirective: return OMPTargetParallelForDirective(clang: clang)
    case CXCursor_OMPTargetUpdateDirective: return OMPTargetUpdateDirective(clang: clang)
    case CXCursor_OMPDistributeParallelForDirective: return OMPDistributeParallelForDirective(clang: clang)
    case CXCursor_OMPDistributeParallelForSimdDirective: return OMPDistributeParallelForSimdDirective(clang: clang)
    case CXCursor_OMPDistributeSimdDirective: return OMPDistributeSimdDirective(clang: clang)
    case CXCursor_OMPTargetParallelForSimdDirective: return OMPTargetParallelForSimdDirective(clang: clang)
    case CXCursor_TranslationUnit: return TranslationUnitCursor(clang: clang)
    case CXCursor_UnexposedAttr: return UnexposedAttr(clang: clang)
    case CXCursor_IBActionAttr: return IBActionAttr(clang: clang)
    case CXCursor_IBOutletAttr: return IBOutletAttr(clang: clang)
    case CXCursor_IBOutletCollectionAttr: return IBOutletCollectionAttr(clang: clang)
    case CXCursor_CXXFinalAttr: return CXXFinalAttr(clang: clang)
    case CXCursor_CXXOverrideAttr: return CXXOverrideAttr(clang: clang)
    case CXCursor_AnnotateAttr: return AnnotateAttr(clang: clang)
    case CXCursor_AsmLabelAttr: return AsmLabelAttr(clang: clang)
    case CXCursor_PackedAttr: return PackedAttr(clang: clang)
    case CXCursor_PureAttr: return PureAttr(clang: clang)
    case CXCursor_ConstAttr: return ConstAttr(clang: clang)
    case CXCursor_NoDuplicateAttr: return NoDuplicateAttr(clang: clang)
    case CXCursor_CUDAConstantAttr: return CUDAConstantAttr(clang: clang)
    case CXCursor_CUDADeviceAttr: return CUDADeviceAttr(clang: clang)
    case CXCursor_CUDAGlobalAttr: return CUDAGlobalAttr(clang: clang)
    case CXCursor_CUDAHostAttr: return CUDAHostAttr(clang: clang)
    case CXCursor_CUDASharedAttr: return CUDASharedAttr(clang: clang)
    case CXCursor_VisibilityAttr: return VisibilityAttr(clang: clang)
    case CXCursor_DLLExport: return DLLExport(clang: clang)
    case CXCursor_DLLImport: return DLLImport(clang: clang)
    case CXCursor_PreprocessingDirective: return PreprocessingDirective(clang: clang)
    case CXCursor_MacroDefinition: return MacroDefinition(clang: clang)
    case CXCursor_MacroExpansion: return MacroExpansion(clang: clang)
    case CXCursor_MacroInstantiation: return MacroInstantiation(clang: clang)
    case CXCursor_InclusionDirective: return InclusionDirective(clang: clang)
    case CXCursor_ModuleImportDecl: return ModuleImportDecl(clang: clang)
    case CXCursor_TypeAliasTemplateDecl: return TypeAliasTemplateDecl(clang: clang)
    case CXCursor_StaticAssert: return StaticAssert(clang: clang)
    case CXCursor_OverloadCandidate: return OverloadCandidate(clang: clang)
        
    case CXCursor_AlignedAttr: return AlignedAttr(clang: clang)
    case CXCursor_ArraySectionExpr: return ArraySectionExpr(clang: clang)
    case CXCursor_BuiltinBitCastExpr: return BuiltinBitCastExpr(clang: clang)
    case CXCursor_CXXAddrspaceCastExpr: return CXXAddrspaceCastExpr(clang: clang)
    case CXCursor_CXXParenListInitExpr: return CXXParenListInitExpr(clang: clang)
    case CXCursor_ConceptDecl: return ConceptDecl(clang: clang)
    case CXCursor_ConceptSpecializationExpr: return ConceptSpecializationExpr(clang: clang)
    case CXCursor_ConvergentAttr: return ConvergentAttr(clang: clang)
    case CXCursor_FixedPointLiteral: return FixedPointLiteral(clang: clang)
    case CXCursor_FlagEnum: return FlagEnum(clang: clang)
    case CXCursor_FriendDecl: return FriendDecl(clang: clang)
    case CXCursor_NSConsumed: return NSConsumed(clang: clang)
    case CXCursor_NSConsumesSelf: return NSConsumesSelf(clang: clang)
    case CXCursor_NSReturnsAutoreleased: return NSReturnsAutoreleased(clang: clang)
    case CXCursor_NSReturnsNotRetained: return NSReturnsNotRetained(clang: clang)
    case CXCursor_NSReturnsRetained: return NSReturnsRetained(clang: clang)
    case CXCursor_OMPArrayShapingExpr: return OMPArrayShapingExpr(clang: clang)
    case CXCursor_OMPAssumeDirective: return OMPAssumeDirective(clang: clang)
    case CXCursor_OMPCanonicalLoop: return OMPCanonicalLoop(clang: clang)
    case CXCursor_OMPDepobjDirective: return OMPDepobjDirective(clang: clang)
    case CXCursor_OMPDispatchDirective: return OMPDispatchDirective(clang: clang)
    case CXCursor_OMPErrorDirective: return OMPErrorDirective(clang: clang)
    case CXCursor_OMPGenericLoopDirective: return OMPGenericLoopDirective(clang: clang)
    case CXCursor_OMPInterchangeDirective: return OMPInterchangeDirective(clang: clang)
    case CXCursor_OMPInteropDirective: return OMPInteropDirective(clang: clang)
    case CXCursor_OMPIteratorExpr: return OMPIteratorExpr(clang: clang)
    case CXCursor_OMPMaskedDirective: return OMPMaskedDirective(clang: clang)
    case CXCursor_OMPMaskedTaskLoopDirective: return OMPMaskedTaskLoopDirective(clang: clang)
    case CXCursor_OMPMaskedTaskLoopSimdDirective: return OMPMaskedTaskLoopSimdDirective(clang: clang)
    case CXCursor_OMPMasterTaskLoopDirective: return OMPMasterTaskLoopDirective(clang: clang)
    case CXCursor_OMPMasterTaskLoopSimdDirective: return OMPMasterTaskLoopSimdDirective(clang: clang)
    case CXCursor_OMPMetaDirective: return OMPMetaDirective(clang: clang)
    case CXCursor_OMPParallelGenericLoopDirective: return OMPParallelGenericLoopDirective(clang: clang)
    case CXCursor_OMPParallelMaskedDirective: return OMPParallelMaskedDirective(clang: clang)
    case CXCursor_OMPParallelMaskedTaskLoopDirective: return OMPParallelMaskedTaskLoopDirective(clang: clang)
    case CXCursor_OMPParallelMaskedTaskLoopSimdDirective: return OMPParallelMaskedTaskLoopSimdDirective(clang: clang)
    case CXCursor_OMPParallelMasterDirective: return OMPParallelMasterDirective(clang: clang)
    case CXCursor_OMPParallelMasterTaskLoopDirective: return OMPParallelMasterTaskLoopDirective(clang: clang)
    case CXCursor_OMPParallelMasterTaskLoopSimdDirective: return OMPParallelMasterTaskLoopSimdDirective(clang: clang)
    case CXCursor_OMPReverseDirective: return OMPReverseDirective(clang: clang)
    case CXCursor_OMPScanDirective: return OMPScanDirective(clang: clang)
    case CXCursor_OMPScopeDirective: return OMPScopeDirective(clang: clang)
    case CXCursor_OMPTargetParallelGenericLoopDirective: return OMPTargetParallelGenericLoopDirective(clang: clang)
    case CXCursor_OMPTargetSimdDirective: return OMPTargetSimdDirective(clang: clang)
    case CXCursor_OMPTargetTeamsDirective: return OMPTargetTeamsDirective(clang: clang)
    case CXCursor_OMPTargetTeamsDistributeDirective: return OMPTargetTeamsDistributeDirective(clang: clang)
    case CXCursor_OMPTargetTeamsDistributeParallelForDirective: return OMPTargetTeamsDistributeParallelForDirective(clang: clang)
    case CXCursor_OMPTargetTeamsDistributeParallelForSimdDirective: return OMPTargetTeamsDistributeParallelForSimdDirective(clang: clang)
    case CXCursor_OMPTargetTeamsDistributeSimdDirective: return OMPTargetTeamsDistributeSimdDirective(clang: clang)
    case CXCursor_OMPTargetTeamsGenericLoopDirective: return OMPTargetTeamsGenericLoopDirective(clang: clang)
    case CXCursor_OMPTeamsDistributeDirective: return OMPTeamsDistributeDirective(clang: clang)
    case CXCursor_OMPTeamsDistributeParallelForDirective: return OMPTeamsDistributeParallelForDirective(clang: clang)
    case CXCursor_OMPTeamsDistributeParallelForSimdDirective: return OMPTeamsDistributeParallelForSimdDirective(clang: clang)
    case CXCursor_OMPTeamsDistributeSimdDirective: return OMPTeamsDistributeSimdDirective(clang: clang)
    case CXCursor_OMPTeamsGenericLoopDirective: return OMPTeamsGenericLoopDirective(clang: clang)
    case CXCursor_OMPTileDirective: return OMPTileDirective(clang: clang)
    case CXCursor_OMPUnrollDirective: return OMPUnrollDirective(clang: clang)
    case CXCursor_ObjCBoxable: return ObjCBoxable(clang: clang)
    case CXCursor_ObjCDesignatedInitializer: return ObjCDesignatedInitializer(clang: clang)
    case CXCursor_ObjCException: return ObjCException(clang: clang)
    case CXCursor_ObjCExplicitProtocolImpl: return ObjCExplicitProtocolImpl(clang: clang)
    case CXCursor_ObjCIndependentClass: return ObjCIndependentClass(clang: clang)
    case CXCursor_ObjCNSObject: return ObjCNSObject(clang: clang)
    case CXCursor_ObjCPreciseLifetime: return ObjCPreciseLifetime(clang: clang)
    case CXCursor_ObjCRequiresSuper: return ObjCRequiresSuper(clang: clang)
    case CXCursor_ObjCReturnsInnerPointer: return ObjCReturnsInnerPointer(clang: clang)
    case CXCursor_ObjCRootClass: return ObjCRootClass(clang: clang)
    case CXCursor_ObjCRuntimeVisible: return ObjCRuntimeVisible(clang: clang)
    case CXCursor_ObjCSubclassingRestricted: return ObjCSubclassingRestricted(clang: clang)
    case CXCursor_OpenACCComputeConstruct: return OpenACCComputeConstruct(clang: clang)
    case CXCursor_OpenACCLoopConstruct: return OpenACCLoopConstruct(clang: clang)
    case CXCursor_PackIndexingExpr: return PackIndexingExpr(clang: clang)
    case CXCursor_RequiresExpr: return RequiresExpr(clang: clang)
    case CXCursor_WarnUnusedAttr: return WarnUnusedAttr(clang: clang)
    case CXCursor_WarnUnusedResultAttr: return WarnUnusedResultAttr(clang: clang)
    default: return nil
    }
}


// MARK: - Internal cursor walk helpers

@inline(__always)
internal func firstChild<Match: Cursor>(of parent: Cursor) -> Match? {
    var found: Match?
    parent.visitChildren { child in
        if let typed = child as? Match {
            found = typed
            return .abort
        }
        return .continue
    }
    return found
}

@inline(__always)
internal func childrenOfType<Match: Cursor>(of parent: Cursor) -> [Match] {
    var matches: [Match] = []
    parent.visitChildren { child in
        if let typed = child as? Match {
            matches.append(typed)
        }
        return .continue
    }
    return matches
}
