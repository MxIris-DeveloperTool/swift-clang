import Testing
import Foundation
@testable import CclangWrapper
@testable import Clang

@Suite("Cursor")
struct CursorTests {
    @Test("Translation unit cursor is not null")
    func translationUnitCursorNotNull() throws {
        let unit = try TranslationUnit(clangSource: "int x;", language: .c)
        let cursor = unit.cursor
        #expect(!cursor.isNull)
        #expect(cursor.isTranslationUnit)
        #expect(cursor is TranslationUnitCursor)
    }

    @Test("Cursor children")
    func children() throws {
        let unit = try TranslationUnit(
            clangSource: "int a; int b;", language: .c
        )
        let children = unit.cursor.children()
        #expect(children.count == 2)
        #expect(children.allSatisfy { $0 is VarDecl })
    }

    @Test("Visit children with abort")
    func visitChildrenAbort() throws {
        let unit = try TranslationUnit(
            clangSource: "int a; int b; int c;", language: .c
        )
        var visited = [String]()
        unit.visitChildren { cursor in
            visited.append(cursor.description)
            return .abort
        }
        #expect(visited.count == 1)
    }

    @Test("Visit children with continue")
    func visitChildrenContinue() throws {
        let src = "struct S { int x; int y; };"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        var topLevelCount = 0
        unit.visitChildren { _ in
            topLevelCount += 1
            return .continue
        }
        #expect(topLevelCount == 1)
    }

    @Test("Cursor description and display name")
    func description() throws {
        let src = "int myFunction(int param) { return param; }"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        var found = false
        unit.visitChildren { cursor in
            if cursor is FunctionDecl {
                #expect(cursor.description == "myFunction")
                #expect(cursor.displayName == "myFunction(int)")
                found = true
            }
            return .recurse
        }
        #expect(found)
    }

    @Test("Cursor USR is non-empty for declarations")
    func usr() throws {
        let unit = try TranslationUnit(clangSource: "void foo(void);", language: .c)
        var found = false
        unit.visitChildren { cursor in
            if cursor is FunctionDecl {
                #expect(!cursor.usr.isEmpty)
                found = true
            }
            return .recurse
        }
        #expect(found)
    }

    @Test("Cursor definition")
    func definition() throws {
        let src = "int foo(void); int foo(void) { return 0; }"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        var declarations = [Cursor]()
        unit.visitChildren { cursor in
            if cursor is FunctionDecl { declarations.append(cursor) }
            return .recurse
        }
        #expect(declarations.count == 2)
        // The definition of the first declaration should point to the second
        let def = declarations[0].definition
        #expect(def != nil)
        #expect(def!.isDefinition)
    }

    @Test("Cursor boolean properties")
    func booleanProperties() throws {
        let src = """
        int global;
        void func(void) {}
        """
        let unit = try TranslationUnit(clangSource: src, language: .c)
        unit.visitChildren { cursor in
            if cursor is VarDecl {
                #expect(cursor.isDeclaration)
                #expect(!cursor.isExpression)
                #expect(!cursor.isReference)
                #expect(!cursor.isPreprocessing)
                #expect(!cursor.isInvalid)
                #expect(!cursor.isUnexposed)
            }
            if cursor is FunctionDecl {
                #expect(cursor.isDeclaration)
                #expect(cursor.isDefinition)
            }
            return .recurse
        }
    }

    @Test("Cursor language detection")
    func language() throws {
        let unit = try TranslationUnit(clangSource: "int x;", language: .c)
        unit.visitChildren { cursor in
            if cursor is VarDecl {
                #expect(cursor.language == .c)
            }
            return .recurse
        }
    }

    @Test("Null cursor")
    func nullCursor() {
        let null = clang_getNullCursor()
        #expect(clang_Cursor_isNull(null) != 0)
        // convertCursor returns nil for null cursors
        #expect(convertCursor(null) == nil)
    }

    @Test("Cursor equality")
    func equality() throws {
        let unit = try TranslationUnit(clangSource: "int x;", language: .c)
        let cursor1 = unit.cursor
        let cursor2 = unit.cursor
        #expect(cursor1 == cursor2)
    }

    @Test("Cursor translationUnit does not double-dispose")
    func translationUnitDoesNotDoubleFree() throws {
        let filename = testFile(for: "init-ast.c")
        let unit = try TranslationUnit(filename: filename)
        let cursor = unit.cursor
        for _ in 0 ..< 2 {
            _ = cursor.translationUnit
        }
    }

    @Test("Cursor range")
    func range() throws {
        let unit = try TranslationUnit(clangSource: "int x;", language: .c)
        let range = unit.cursor.range
        _ = range.start
        _ = range.end
    }

    @Test("Lexical and semantic parent")
    func parentCursors() throws {
        let src = "struct S { int x; };"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        unit.visitChildren { cursor in
            if cursor is FieldDecl {
                #expect(cursor.lexicalParent is StructDecl)
                #expect(cursor.semanticParent is StructDecl)
            }
            return .recurse
        }
    }

    @Test("Visibility kind for function")
    func visibilityKind() throws {
        let src = "void foo(void) {}"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        var found = false
        unit.visitChildren { cursor in
            if cursor is FunctionDecl {
                // Default visibility for a regular function
                let vis = cursor.visiblity
                #expect(vis == .default)
                found = true
            }
            return .recurse
        }
        #expect(found)
    }
}
