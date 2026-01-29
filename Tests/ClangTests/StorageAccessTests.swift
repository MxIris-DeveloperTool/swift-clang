import Testing
import Foundation
@testable import CclangWrapper
@testable import Clang

@Suite("Storage and Access")
struct StorageAccessTests {
    @Test("Storage class for static variable")
    func staticStorageClass() throws {
        let src = "static int x = 0;"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        var found = false
        unit.visitChildren { cursor in
            if cursor is VarDecl {
                #expect(cursor.storageClass == .static)
                found = true
            }
            return .recurse
        }
        #expect(found)
    }

    @Test("Storage class for extern variable")
    func externStorageClass() throws {
        let src = "extern int x;"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        var found = false
        unit.visitChildren { cursor in
            if cursor is VarDecl {
                #expect(cursor.storageClass == .extern)
                found = true
            }
            return .recurse
        }
        #expect(found)
    }

    @Test("C++ access specifier")
    func cxxAccessSpecifier() throws {
        let src = """
        class Foo {
        public:
            int pub;
        private:
            int priv;
        };
        """
        let unit = try TranslationUnit(clangSource: src, language: .cPlusPlus)
        var accessMap = [String: CXXAccessSpecifierKind]()
        unit.visitChildren { cursor in
            if cursor is FieldDecl, let access = cursor.accessSpecifier {
                accessMap[cursor.description] = access
            }
            return .recurse
        }
        #expect(accessMap["pub"] == .public)
        #expect(accessMap["priv"] == .private)
    }

    @Test("TemplateArgumentKind for C++ template specialization")
    func templateArgumentKind() throws {
        let src = """
        template<typename T> class Box { T value; };
        Box<int> intBox;
        """
        let unit = try TranslationUnit(clangSource: src, language: .cPlusPlus)
        var foundTemplate = false
        unit.visitChildren { cursor in
            if cursor is ClassTemplate {
                foundTemplate = true
            }
            return .recurse
        }
        #expect(foundTemplate)
    }

    @Test("Storage class for regular variable is none")
    func noneStorageClass() throws {
        let src = "int x = 0;"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        var found = false
        unit.visitChildren { cursor in
            if cursor is VarDecl {
                #expect(cursor.storageClass == StorageClass.none)
                found = true
            }
            return .recurse
        }
        #expect(found)
    }
}
