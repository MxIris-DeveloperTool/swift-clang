internal import CclangWrapper

// MARK: Special Types

public struct RecordType: CType, ClangTypeBacked {
    let clang: CXType
    /// Computes the offset of a named field in a record of the given type
    /// in bytes as it would be returned by __offsetof__ as per C++11[18.2p4]
    /// - returns: The offset of a field with the given name in the type.
    /// - throws:
    ///     - `TypeLayoutError.invalid` if the type declaration is not a record
    ///        field.
    ///     - `TypeLayoutError.incomplete` if the type declaration is an
    ///       incomplete type
    ///     - `TypeLayoutError.dependent` if the type declaration is dependent
    ///     - `TypeLayoutError.invalidFieldName` if the field is not found in
    ///       the receiving type.
    public func offsetOf(fieldName: String) throws -> Int {
        let val = clang_Type_getOffsetOf(clangType, fieldName)
        if let error = TypeLayoutError(clang: CXTypeLayoutError(rawValue: Int32(val))) {
            throw error
        }
        return Int(val)
    }

    /// Gathers and returns all the fields of this record.
    public func fields() -> [Cursor] {
        let fields = Box([Cursor]())
        let fieldsRef = Unmanaged.passUnretained(fields)
        let opaque = fieldsRef.toOpaque()
        _ = clang_Type_visitFields(clangType, { child, opaque -> CXVisitorResult in
            let fieldsRef = Unmanaged<Box<[Cursor]>>.fromOpaque(opaque!)
            let fields = fieldsRef.takeUnretainedValue()
            if let cursor = convertCursor(child) {
                fields.value.append(cursor)
            }
            return CXVisit_Continue
        }, opaque)
        return fields.value
    }
}

// MARK: Standard Types

/// A type whose specific kind is not exposed via this interface.
public struct UnexposedType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct VoidType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct BoolType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct Char_UType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct UCharType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct Char16Type: CType, ClangTypeBacked {
    let clang: CXType
}

public struct Char32Type: CType, ClangTypeBacked {
    let clang: CXType
}

public struct UShortType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct UIntType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct ULongType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct ULongLongType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct UInt128Type: CType, ClangTypeBacked {
    let clang: CXType
}

public struct Char_SType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct SCharType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct WCharType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct ShortType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct IntType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct LongType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct LongLongType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct Int128Type: CType, ClangTypeBacked {
    let clang: CXType
}

public struct FloatType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct DoubleType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct LongDoubleType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct NullPtrType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct OverloadType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct DependentType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct ObjCIdType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct ObjCClassType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct ObjCSelType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct Float128Type: CType, ClangTypeBacked {
    let clang: CXType
}

public struct ComplexType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct PointerType: CType, ClangTypeBacked {
    let clang: CXType

    public var pointee: CType? {
        return convertType(clang_getPointeeType(clang))
    }
}

public struct BlockPointerType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct LValueReferenceType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct RValueReferenceType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct EnumType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct TypedefType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct ObjCInterfaceType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct ObjCTypeParam: CType, ClangTypeBacked {
    let clang: CXType
}

public struct ObjCObjectPointerType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct FunctionNoProtoType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct FunctionProtoType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct ConstantArrayType: CType, ClangTypeBacked {
    let clang: CXType

    public var element: CType? {
        return convertType(clang_getArrayElementType(clang))
    }

    public var count: Int32 {
        return clang_getNumArgTypes(clang)
    }
}

public struct VectorType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct IncompleteArrayType: CType, ClangTypeBacked {
    let clang: CXType

    public var element: CType? {
        return convertType(clang_getArrayElementType(clang))
    }
}

public struct VariableArrayType: CType, ClangTypeBacked {
    let clang: CXType

    public var element: CType? {
        return convertType(clang_getArrayElementType(clang))
    }
}

public struct DependentSizedArrayType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct MemberPointerType: CType, ClangTypeBacked {
    let clang: CXType
}

public struct AutoType: CType, ClangTypeBacked {
    let clang: CXType
}

/// Represents a type that was referred to using an elaborated type keyword.
public struct ElaboratedType: CType, ClangTypeBacked {
    let clang: CXType
}

/// Converts a CXType to a CType, returning `nil` if it was unsuccessful
func convertType(_ clang: CXType) -> CType? {
    switch clang.kind {
    case CXType_Invalid: return nil
    case CXType_Unexposed: return UnexposedType(clang: clang)
    case CXType_Void: return VoidType(clang: clang)
    case CXType_Bool: return BoolType(clang: clang)
    case CXType_Char_U: return Char_UType(clang: clang)
    case CXType_UChar: return UCharType(clang: clang)
    case CXType_Char16: return Char16Type(clang: clang)
    case CXType_Char32: return Char32Type(clang: clang)
    case CXType_UShort: return UShortType(clang: clang)
    case CXType_UInt: return UIntType(clang: clang)
    case CXType_ULong: return ULongType(clang: clang)
    case CXType_ULongLong: return ULongLongType(clang: clang)
    case CXType_UInt128: return UInt128Type(clang: clang)
    case CXType_Char_S: return Char_SType(clang: clang)
    case CXType_SChar: return SCharType(clang: clang)
    case CXType_WChar: return WCharType(clang: clang)
    case CXType_Short: return ShortType(clang: clang)
    case CXType_Int: return IntType(clang: clang)
    case CXType_Long: return LongType(clang: clang)
    case CXType_LongLong: return LongLongType(clang: clang)
    case CXType_Int128: return Int128Type(clang: clang)
    case CXType_Float: return FloatType(clang: clang)
    case CXType_Double: return DoubleType(clang: clang)
    case CXType_LongDouble: return LongDoubleType(clang: clang)
    case CXType_NullPtr: return NullPtrType(clang: clang)
    case CXType_Overload: return OverloadType(clang: clang)
    case CXType_Dependent: return DependentType(clang: clang)
    case CXType_ObjCId: return ObjCIdType(clang: clang)
    case CXType_ObjCClass: return ObjCClassType(clang: clang)
    case CXType_ObjCSel: return ObjCSelType(clang: clang)
    case CXType_Float128: return Float128Type(clang: clang)
    case CXType_Complex: return ComplexType(clang: clang)
    case CXType_Pointer: return PointerType(clang: clang)
    case CXType_BlockPointer: return BlockPointerType(clang: clang)
    case CXType_LValueReference: return LValueReferenceType(clang: clang)
    case CXType_RValueReference: return RValueReferenceType(clang: clang)
    case CXType_Record: return RecordType(clang: clang)
    case CXType_Enum: return EnumType(clang: clang)
    case CXType_Typedef: return TypedefType(clang: clang)
    case CXType_ObjCInterface: return ObjCInterfaceType(clang: clang)
    case CXType_ObjCObjectPointer: return ObjCObjectPointerType(clang: clang)
    case CXType_ObjCTypeParam: return ObjCTypeParam(clang: clang)
    case CXType_FunctionNoProto: return FunctionNoProtoType(clang: clang)
    case CXType_FunctionProto: return FunctionProtoType(clang: clang)
    case CXType_ConstantArray: return ConstantArrayType(clang: clang)
    case CXType_Vector: return VectorType(clang: clang)
    case CXType_IncompleteArray: return IncompleteArrayType(clang: clang)
    case CXType_VariableArray: return VariableArrayType(clang: clang)
    case CXType_DependentSizedArray: return DependentSizedArrayType(clang: clang)
    case CXType_MemberPointer: return MemberPointerType(clang: clang)
    case CXType_Auto: return AutoType(clang: clang)
    case CXType_Elaborated: return ElaboratedType(clang: clang)
    default: return nil
    }
}
