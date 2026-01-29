import Testing
import Foundation
@testable import CclangWrapper
@testable import Clang

@Suite("C++ Features")
struct CppTests {
    @Test("Namespace cursor")
    func namespaceCursor() throws {
        let src = "namespace foo { int x; }"
        let unit = try TranslationUnit(clangSource: src, language: .cPlusPlus)
        var found = false
        unit.visitChildren { cursor in
            if cursor is Namespace {
                #expect(cursor.description == "foo")
                found = true
            }
            return .recurse
        }
        #expect(found)
    }

    @Test("Class template cursor")
    func classTemplateCursor() throws {
        let src = "template<typename T> class Box { T value; };"
        let unit = try TranslationUnit(clangSource: src, language: .cPlusPlus)
        var found = false
        unit.visitChildren { cursor in
            if cursor is ClassTemplate {
                #expect(cursor.description == "Box")
                found = true
            }
            return .recurse
        }
        #expect(found)
    }

    @Test("Constructor and destructor cursors")
    func ctorDtor() throws {
        let src = "class Foo { public: Foo(); ~Foo(); };"
        let unit = try TranslationUnit(clangSource: src, language: .cPlusPlus)
        var foundCtor = false
        var foundDtor = false
        unit.visitChildren { cursor in
            if cursor is Constructor { foundCtor = true }
            if cursor is Destructor { foundDtor = true }
            return .recurse
        }
        #expect(foundCtor)
        #expect(foundDtor)
    }

    @Test("CXXMethod cursor")
    func cxxMethod() throws {
        let src = "class Foo { public: void bar(); };"
        let unit = try TranslationUnit(clangSource: src, language: .cPlusPlus)
        var found = false
        unit.visitChildren { cursor in
            if cursor is CXXMethod {
                #expect(cursor.description == "bar")
                found = true
            }
            return .recurse
        }
        #expect(found)
    }
}
