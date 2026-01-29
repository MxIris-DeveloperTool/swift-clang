import Testing
import Foundation
@testable import CclangWrapper
@testable import Clang

@Suite("Concrete Cursor Types")
struct ConcreteCursorTests {
    @Test("FunctionDecl properties")
    func functionDecl() throws {
        let src = "int add(int a, int b) { return a + b; }"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        var found = false
        unit.visitChildren { cursor in
            if let fn = cursor as? FunctionDecl {
                #expect(fn.argumentCount == 2)
                #expect(fn.parameter(at: 0)?.description == "a")
                #expect(fn.parameter(at: 1)?.description == "b")
                #expect(fn.resultType != nil)
                #expect(fn.resultType?.description == "int")
                found = true
            }
            return .recurse
        }
        #expect(found)
    }

    @Test("StructDecl and fields")
    func structDecl() throws {
        let src = "struct Point { int x; int y; };"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        var found = false
        unit.visitChildren { cursor in
            if let s = cursor as? StructDecl {
                let fields = s.fields()
                #expect(fields.count == 2)
                #expect(fields[0].description == "x")
                #expect(fields[1].description == "y")
                found = true
            }
            return .recurse
        }
        #expect(found)
    }

    @Test("EnumDecl and constants")
    func enumDecl() throws {
        let src = "enum Color { Red, Green = 5, Blue };"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        var found = false
        unit.visitChildren { cursor in
            if let e = cursor as? EnumDecl {
                let constants = e.constants()
                #expect(constants.count == 3)
                #expect(constants[0].description == "Red")
                #expect(constants[0].value == 0)
                #expect(constants[1].description == "Green")
                #expect(constants[1].value == 5)
                #expect(constants[2].description == "Blue")
                #expect(constants[2].value == 6)
                found = true
            }
            return .recurse
        }
        #expect(found)
    }

    @Test("EnumDecl integer type")
    func enumDeclIntegerType() throws {
        let src = "enum Color { Red, Green, Blue };"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        var found = false
        unit.visitChildren { cursor in
            if let e = cursor as? EnumDecl {
                let intType = try? e.integerType
                #expect(intType != nil)
                found = true
            }
            return .recurse
        }
        #expect(found)
    }

    @Test("EnumConstantDecl unsigned value")
    func enumConstantUnsignedValue() throws {
        let src = "enum Flags { A = 1, B = 2 };"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        var found = false
        unit.visitChildren { cursor in
            if let c = cursor as? EnumConstantDecl, c.description == "B" {
                #expect(c.unsignedValue == 2)
                found = true
            }
            return .recurse
        }
        #expect(found)
    }

    @Test("TypedefDecl underlying type")
    func typedefDecl() throws {
        let src = "typedef unsigned int uint;"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        var found = false
        unit.visitChildren { cursor in
            if let td = cursor as? TypedefDecl {
                #expect(td.description == "uint")
                #expect(td.underlying != nil)
                found = true
            }
            return .recurse
        }
        #expect(found)
    }

    @Test("VarDecl cursor")
    func varDecl() throws {
        let src = "int global_var = 42;"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        var found = false
        unit.visitChildren { cursor in
            if cursor is VarDecl {
                #expect(cursor.description == "global_var")
                found = true
            }
            return .recurse
        }
        #expect(found)
    }

    @Test("InclusionDirective")
    func inclusionDirective() throws {
        let unit = try TranslationUnit(
            filename: testFile(for: "inclusion.c"),
            options: [.detailedPreprocessingRecord]
        )
        var foundInclude = false
        unit.visitChildren { cursor in
            if let inc = cursor as? InclusionDirective {
                #expect(inc.includedFile != nil)
                foundInclude = true
            }
            return .recurse
        }
        #expect(foundInclude)
    }
}
