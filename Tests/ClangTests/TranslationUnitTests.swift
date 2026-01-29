import Testing
import Foundation
@testable import CclangWrapper
@testable import Clang

// MARK: - TranslationUnit Initialization

@Suite("TranslationUnit Initialization")
struct TranslationUnitInitTests {
    @Test("Parse from source string")
    func initUsingStringAsSource() throws {
        let unit = try TranslationUnit(clangSource: "int main() {}", language: .c)
        let lexems = unit.tokens(in: unit.cursor.range).map { $0.spelling(in: unit) }
        #expect(lexems == ["int", "main", "(", ")", "{", "}"])
    }

    @Test("Parse from source string with command-line arguments")
    func initWithArguments() throws {
        let unit = try TranslationUnit(
            clangSource: "int main(void) {int a; return 0;}",
            language: .c,
            commandLineArgs: ["-Wall"]
        )
        #expect(unit.diagnostics.map(\.description) == ["unused variable 'a'"])
    }

    @Test("Parse from file")
    func initFromFile() throws {
        let unit = try TranslationUnit(filename: testFile(for: "init-ast.c"))
        let tokens = unit.tokens(in: unit.cursor.range).map { $0.spelling(in: unit) }
        #expect(tokens == ["int", "main", "(", "void", ")", "{", "return", "0", ";", "}"])
    }

    @Test("Parse from AST file")
    func initFromASTFile() throws {
        let filename = testFile(for: "init-ast.c")
        let astFilename = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".ast").path

        let unit = try TranslationUnit(filename: filename)
        try unit.saveTranslationUnit(in: astFilename, withOptions: unit.defaultSaveOptions)
        defer { try? FileManager.default.removeItem(atPath: astFilename) }

        let unit2 = try TranslationUnit(astFilename: astFilename)
        let tokens = unit2.tokens(in: unit2.cursor.range).map { $0.spelling(in: unit2) }
        #expect(tokens == ["int", "main", "(", "void", ")", "{", "return", "0", ";", "}"])
    }

    @Test("Parse with unsaved file")
    func initWithUnsavedFile() throws {
        let filename = testFile(for: "unsaved-file.c")
        let src = "int main(void) { return 0; }"
        let unsavedFile = UnsavedFile(filename: filename, contents: src)
        let unit = try TranslationUnit(filename: filename, unsavedFiles: [unsavedFile])

        let tokens = unit.tokens(in: unit.cursor.range).map { $0.spelling(in: unit) }
        #expect(tokens == ["int", "main", "(", "void", ")", "{", "return", "0", ";", "}"])
    }

    @Test("Parse C++ source")
    func initCPlusPlusSource() throws {
        let src = "class Foo { public: int bar(); };"
        let unit = try TranslationUnit(clangSource: src, language: .cPlusPlus)
        var foundClass = false
        unit.visitChildren { cursor in
            if cursor is ClassDecl {
                foundClass = true
                #expect(cursor.description == "Foo")
            }
            return .recurse
        }
        #expect(foundClass)
    }

    @Test("Parse Objective-C source")
    func initObjectiveCSource() throws {
        let src = "@interface Foo @end"
        let unit = try TranslationUnit(clangSource: src, language: .objectiveC)
        var foundInterface = false
        unit.visitChildren { cursor in
            if cursor is ObjCInterfaceDecl {
                foundInterface = true
                #expect(cursor.description == "Foo")
            }
            return .recurse
        }
        #expect(foundInterface)
    }

    @Test("Invalid file throws ClangError")
    func initInvalidFile() {
        #expect(throws: ClangError.self) {
            try TranslationUnit(astFilename: "/nonexistent/file.ast")
        }
    }
}

// MARK: - TranslationUnit Operations

@Suite("TranslationUnit Operations")
struct TranslationUnitOperationsTests {
    @Test("Reparse translation unit")
    func reparsing() throws {
        let filename = testFile(for: "reparse.c")
        let index = Index()
        let unit = try TranslationUnit(filename: filename, index: index)

        let src = "int add(int, int);"
        let unsavedFile = UnsavedFile(filename: filename, contents: src)
        try unit.reparseTransaltionUnit(using: [unsavedFile],
                                        options: unit.defaultReparseOptions)

        let tokens = unit.tokens(in: unit.cursor.range).map { $0.spelling(in: unit) }
        #expect(tokens == ["int", "add", "(", "int", ",", "int", ")", ";"])
    }

    @Test("Translation unit spelling")
    func spelling() throws {
        let filename = testFile(for: "init-ast.c")
        let unit = try TranslationUnit(filename: filename)
        #expect(unit.spelling.hasSuffix("init-ast.c"))
    }

    @Test("Get file from translation unit")
    func getFile() throws {
        let fileName = testFile(for: "init-ast.c")
        let unit = try TranslationUnit(filename: fileName)
        #expect(unit.getFile(for: fileName) != nil)
        #expect(unit.getFile(for: "42") == nil)
    }

    @Test("Default reparse and save options are non-nil")
    func defaultOptions() throws {
        let unit = try TranslationUnit(clangSource: "int x;", language: .c)
        // Simply accessing these should not crash
        _ = unit.defaultReparseOptions
        _ = unit.defaultSaveOptions
    }

    @Test("TranslationUnitOptions flag values")
    func translationUnitOptionsFlags() {
        // Verify OptionSet values are distinct and non-zero (except .none)
        #expect(TranslationUnitOptions.none.rawValue == 0)
        #expect(TranslationUnitOptions.detailedPreprocessingRecord.rawValue != 0)
        #expect(TranslationUnitOptions.incomplete.rawValue != 0)
        #expect(TranslationUnitOptions.precompiledPreamble.rawValue != 0)
        #expect(TranslationUnitOptions.cacheCompletionResults.rawValue != 0)
        #expect(TranslationUnitOptions.forSerialization.rawValue != 0)
        #expect(TranslationUnitOptions.skipFunctionBodies.rawValue != 0)
        #expect(TranslationUnitOptions.keepGoing.rawValue != 0)

        // Verify combining works
        let combined: TranslationUnitOptions = [.detailedPreprocessingRecord, .keepGoing]
        #expect(combined.contains(.detailedPreprocessingRecord))
        #expect(combined.contains(.keepGoing))
        #expect(!combined.contains(.incomplete))
    }

    @Test("TranslationUnitSaveOptions flag values")
    func translationUnitSaveOptionsFlags() {
        #expect(TranslationUnitSaveOptions.none.rawValue == 0)
    }
}
