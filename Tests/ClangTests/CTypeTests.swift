import Testing
import Foundation
@testable import CclangWrapper
@testable import Clang

@Suite("C Types")
struct CTypeTests {
    @Test("Type description")
    func typeDescription() throws {
        let src = "int x; double y;"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        var types = [String]()
        unit.visitChildren { cursor in
            if cursor is VarDecl, let t = cursor.type {
                types.append(t.description)
            }
            return .recurse
        }
        #expect(types == ["int", "double"])
    }

    @Test("Canonical type")
    func canonicalType() throws {
        let src = "typedef int myint; myint x;"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        unit.visitChildren { cursor in
            if cursor is VarDecl, let t = cursor.type {
                let canonical = try? t.canonicalType
                #expect(canonical != nil)
                #expect(canonical?.description == "int")
            }
            return .recurse
        }
    }

    @Test("Type sizeOf and alignOf")
    func sizeOfAlignOf() throws {
        let src = "struct S { int x; double y; };"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        unit.visitChildren { cursor in
            if cursor is StructDecl, let t = cursor.type {
                let size = try? t.sizeOf()
                let align = try? t.alignOf()
                #expect(size != nil)
                #expect(align != nil)
                #expect(size! > 0)
                #expect(align! > 0)
            }
            return .recurse
        }
    }

    @Test("Pointer type and pointee")
    func pointerType() throws {
        let src = "int *p;"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        var found = false
        unit.visitChildren { cursor in
            if cursor is VarDecl, let t = cursor.type as? PointerType {
                #expect(t.pointee != nil)
                #expect(t.pointee?.description == "int")
                found = true
            }
            return .recurse
        }
        #expect(found)
    }

    @Test("Record type fields and offsetOf")
    func recordTypeFieldsAndOffset() throws {
        let src = "struct S { int x; int y; };"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        var found = false
        unit.visitChildren { cursor in
            if cursor is StructDecl, let t = cursor.type as? RecordType {
                let fields = t.fields()
                #expect(fields.count == 2)
                let offset = try? t.offsetOf(fieldName: "y")
                #expect(offset != nil)
                #expect(offset! > 0)
                found = true
            }
            return .recurse
        }
        #expect(found)
    }

    @Test("Function type result type")
    func functionResultType() throws {
        let src = "double compute(int a) { return (double)a; }"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        var found = false
        unit.visitChildren { cursor in
            if let fn = cursor as? FunctionDecl {
                #expect(fn.resultType?.description == "double")
                found = true
            }
            return .recurse
        }
        #expect(found)
    }

    @Test("Type equality")
    func typeEquality() throws {
        let src = "int a; int b;"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        var types = [CType]()
        unit.visitChildren { cursor in
            if cursor is VarDecl, let t = cursor.type { types.append(t) }
            return .recurse
        }
        #expect(types.count == 2)
        #expect(types[0] == types[1])
    }

    @Test("Array type element")
    func arrayType() throws {
        let src = "int arr[10];"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        var found = false
        unit.visitChildren { cursor in
            if cursor is VarDecl, let t = cursor.type as? ConstantArrayType {
                #expect(t.element?.description == "int")
                found = true
            }
            return .recurse
        }
        #expect(found)
    }

    @Test("TypeLayoutError for incomplete type")
    func typeLayoutErrorIncomplete() throws {
        let src = "struct Incomplete; struct Incomplete *p;"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        var found = false
        unit.visitChildren { cursor in
            if cursor is StructDecl, cursor.description == "Incomplete" {
                if let t = cursor.type {
                    // Forward declared struct should fail sizeOf
                    let size = try? t.sizeOf()
                    #expect(size == nil)
                    found = true
                }
            }
            return .recurse
        }
        #expect(found)
    }

    @Test("TypeLayoutError for invalid field name")
    func typeLayoutErrorInvalidField() throws {
        let src = "struct S { int x; };"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        var found = false
        unit.visitChildren { cursor in
            if cursor is StructDecl, let t = cursor.type as? RecordType {
                do {
                    _ = try t.offsetOf(fieldName: "nonexistent")
                    #expect(Bool(false), "Should have thrown")
                } catch {
                    #expect(error is TypeLayoutError)
                }
                found = true
            }
            return .recurse
        }
        #expect(found)
    }

    @Test("RefQualifier for C++ methods")
    func refQualifier() throws {
        let src = """
        class Foo {
        public:
            void lvalueMethod() &;
            void rvalueMethod() &&;
            void normalMethod();
        };
        """
        let unit = try TranslationUnit(clangSource: src, language: .cPlusPlus)
        var lvalueFound = false
        var rvalueFound = false
        var normalFound = false
        unit.visitChildren { cursor in
            if cursor is CXXMethod, let t = cursor.type {
                if cursor.description == "lvalueMethod" {
                    #expect(t.cxxRefQualifier == .lvalue)
                    lvalueFound = true
                }
                if cursor.description == "rvalueMethod" {
                    #expect(t.cxxRefQualifier == .rvalue)
                    rvalueFound = true
                }
                if cursor.description == "normalMethod" {
                    #expect(t.cxxRefQualifier == nil)
                    normalFound = true
                }
            }
            return .recurse
        }
        #expect(lvalueFound)
        #expect(rvalueFound)
        #expect(normalFound)
    }
}
