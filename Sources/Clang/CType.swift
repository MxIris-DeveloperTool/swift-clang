package import CclangWrapper

/// The type of an element in the abstract syntax tree.
public protocol CType: CustomStringConvertible {
}

public enum TypeLayoutError: Error, Sendable {
    /// The type was invalid
    case invalid

    /// The type was a dependent type
    case dependent

    /// The type was incomplete
    case incomplete

    /// The type did not have a constant size
    case notConstantSize

    /// The field specified was not found or invalid
    case invalidFieldName

    internal init?(clang: CXTypeLayoutError) {
        switch clang {
        case CXTypeLayoutError_Dependent:
            self = .dependent
        case CXTypeLayoutError_Invalid:
            self = .invalid
        case CXTypeLayoutError_Incomplete:
            self = .incomplete
        case CXTypeLayoutError_NotConstantSize:
            self = .notConstantSize
        case CXTypeLayoutError_InvalidFieldName:
            self = .invalidFieldName
        default:
            return nil
        }
    }
}

/// Represents a CType that's backed by a CXType directly
protocol ClangTypeBacked {
    var clang: CXType { get }
}

extension ClangTypeBacked {
    func asClang() -> CXType {
        return clang
    }
}

extension CXType: @retroactive CustomStringConvertible {}
extension CXType: CType {
    func asClang() -> CXType {
        return self
    }
}

/// Determines if two C types are equal to each other.
public func == (lhs: CType, rhs: CType) -> Bool {
    return clang_equalTypes(lhs.clangType, rhs.clangType) != 0
}

extension CType {
    /// Internal accessor for the underlying CXType
    var clangType: CXType {
        if let backed = self as? ClangTypeBacked {
            return backed.clang
        }
        return (self as! CXType)
    }
}

extension CType {
    /// Computes the size of a type in bytes as per C++ [expr.sizeof] standard.
    /// - returns: The size of the type in bytes.
    /// - throws:
    ///     - `TypeLayoutError.invalid` if the type declaration is invalid.
    ///     - `TypeLayoutError.incomplete` if the type declaration is an
    ///       incomplete type
    ///     - `TypeLayoutError.dependent` if the type declaration is dependent
    public func sizeOf() throws -> Int {
        let val = clang_Type_getSizeOf(clangType)
        if let error = TypeLayoutError(clang: CXTypeLayoutError(rawValue: Int32(val))) {
            throw error
        }
        return Int(val)
    }

    /// Computes the alignment of a type in bytes as per C++[expr.alignof]
    /// standard.
    /// - returns: The alignment of the given type, in bytes.
    /// - throws:
    ///     - `TypeLayoutError.invalid` if the type declaration is invalid.
    ///     - `TypeLayoutError.incomplete` if the type declaration is an
    ///       incomplete type
    ///     - `TypeLayoutError.dependent` if the type declaration is dependent
    ///     - `TypeLayoutError.nonConstantSize` if the type is not a constant
    ///       size
    public func alignOf() throws -> Int {
        let val = clang_Type_getAlignOf(clangType)
        if let error = TypeLayoutError(clang: CXTypeLayoutError(rawValue: Int32(val))) {
            throw error
        }
        return Int(val)
    }

    /// Pretty-print the underlying type using the rules of the language of the
    /// translation unit from which it came.
    /// - note: If the type is invalid, an empty string is returned.
    public var description: String {
        return clang_getTypeSpelling(clangType).asSwift()
    }

    /// Retrieves the cursor for the declaration of the receiver.
    public var declaration: Cursor? {
        return convertCursor(clang_getTypeDeclaration(clangType))
    }

    /// Retrieves the Objective-C type encoding for the receiver.
    public var objcEncoding: String {
        return clang_Type_getObjCEncoding(clangType).asSwift()
    }

    /// Return the canonical type for a CType.
    /// Clang's type system explicitly models typedefs and all the ways a
    /// specific type can be represented. The canonical type is the underlying
    /// type with all the "sugar" removed. For example, if 'T' is a typedef for
    /// 'int', the canonical type for 'T' would be 'int'.
    public var canonicalType: CType {
        get throws {
            guard let type = convertType(clang_getCanonicalType(clangType)) else {
                throw ClangError.unexpectedValue
            }
            return type
        }
    }

    /// Retrieve the ref-qualifier kind of a function or method.
    /// The ref-qualifier is returned for C++ functions or methods. For other
    /// types or non-C++ declarations, nil is returned.
    public var cxxRefQualifier: RefQualifier? {
        return RefQualifier(clang: clang_Type_getCXXRefQualifier(clangType))
    }
}

extension CType {
    /// Whether this type is an unsigned integer type.
    public var isUnsignedIntegerType: Bool {
        self is Char_UType || self is UCharType || self is UShortType ||
        self is UIntType || self is ULongType || self is ULongLongType || self is UInt128Type
    }

    /// Whether this type is a signed integer type.
    public var isSignedIntegerType: Bool {
        self is Char_SType || self is SCharType || self is ShortType ||
        self is IntType || self is LongType || self is LongLongType || self is Int128Type
    }

    /// Whether this type is an integer type (signed or unsigned).
    public var isIntegerType: Bool {
        isSignedIntegerType || isUnsignedIntegerType
    }
}

/// Represents the qualifier for C++ methods that determines how the
/// implicit `this` parameter is used in the method.
public enum RefQualifier: Sendable {
    /// An l-value ref qualifier (&)
    case lvalue

    /// An r-value ref qualifier (&&)
    case rvalue

    internal init?(clang: CXRefQualifierKind) {
        switch clang {
        case CXRefQualifier_LValue: self = .lvalue
        case CXRefQualifier_RValue: self = .rvalue
        default: return nil
        }
    }
}
