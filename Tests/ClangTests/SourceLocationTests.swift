import Testing
import Foundation
@testable import CclangWrapper
@testable import Clang

@Suite("Source Locations")
struct SourceLocationTests {
    @Test("Location from line and column")
    func locationFromLineAndColumn() throws {
        let filename = testFile(for: "locations.c")
        let unit = try TranslationUnit(filename: filename)
        let file = File(clang: CclangWrapper.clang_getFile(unit.clang, filename)!)

        let start = SourceLocation(translationUnit: unit, file: file, line: 2, column: 3)
        let end = SourceLocation(translationUnit: unit, file: file, line: 4, column: 17)
        let range = SourceRange(start: start, end: end)

        let tokens = unit.tokens(in: range).map { $0.spelling(in: unit) }
        #expect(tokens == [
            "int", "a", "=", "1", ";",
            "int", "b", "=", "1", ";",
            "int", "c", "=", "a", "+", "b", ";"
        ])
    }

    @Test("Location from offset")
    func locationFromOffset() throws {
        let filename = testFile(for: "locations.c")
        let unit = try TranslationUnit(filename: filename)
        let file = unit.getFile(for: unit.spelling)!

        let start = SourceLocation(translationUnit: unit, file: file, offset: 19)
        let end = SourceLocation(translationUnit: unit, file: file, offset: 59)
        let range = SourceRange(start: start, end: end)

        let tokens = unit.tokens(in: range).map { $0.spelling(in: unit) }
        #expect(tokens == [
            "int", "a", "=", "1", ";",
            "int", "b", "=", "1", ";",
            "int", "c", "=", "a", "+", "b", ";"
        ])
    }

    @Test("Location is from main file")
    func isFromMainFile() throws {
        let unit = try TranslationUnit(filename: testFile(for: "is-from-main-file.c"))
        var functions = [Cursor]()
        unit.visitChildren { cursor in
            if cursor is FunctionDecl, cursor.range.start.isFromMainFile {
                functions.append(cursor)
            }
            return .recurse
        }
        #expect(functions.map(\.description) == ["main"])
    }

    @Test("SourceRange start and end")
    func sourceRangeStartEnd() throws {
        let unit = try TranslationUnit(clangSource: "int x;", language: .c)
        let range = unit.cursor.range
        let start = range.start
        let end = range.end
        #expect(start.offset <= end.offset)
    }

    @Test("SourceLocation line, column, offset properties")
    func locationProperties() throws {
        let filename = testFile(for: "init-ast.c")
        let unit = try TranslationUnit(filename: filename)
        let loc = unit.cursor.range.start
        #expect(loc.line >= 1)
        #expect(loc.column >= 1)
    }

    @Test("SourceLocation asClang round-trip")
    func locationAsClang() throws {
        let unit = try TranslationUnit(clangSource: "int x;", language: .c)
        let loc = unit.cursor.range.start
        let clangLoc = loc.asClang()
        let roundTrip = SourceLocation(clang: clangLoc)
        #expect(roundTrip.offset == loc.offset)
    }

    @Test("SourceRange asClang round-trip")
    func rangeAsClang() throws {
        let unit = try TranslationUnit(clangSource: "int x;", language: .c)
        let range = unit.cursor.range
        let clangRange = range.asClang()
        let roundTrip = SourceRange(clang: clangRange)
        #expect(roundTrip.start.offset == range.start.offset)
        #expect(roundTrip.end.offset == range.end.offset)
    }
}
