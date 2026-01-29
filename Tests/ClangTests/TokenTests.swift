import Testing
import Foundation
@testable import CclangWrapper
@testable import Clang

@Suite("Tokens")
struct TokenTests {
    @Test("Tokenize simple expression")
    func tokenizeSimple() throws {
        let unit = try TranslationUnit(clangSource: "int x = 1;", language: .c)
        let tokens = unit.tokens(in: unit.cursor.range)
        let spellings = tokens.map { $0.spelling(in: unit) }
        #expect(spellings == ["int", "x", "=", "1", ";"])
    }

    @Test("Token types")
    func tokenTypes() throws {
        let unit = try TranslationUnit(clangSource: "int x = 42;", language: .c)
        let tokens = unit.tokens(in: unit.cursor.range)
        #expect(tokens.count == 5)
        #expect(tokens[0] is KeywordToken)      // int
        #expect(tokens[1] is IdentifierToken)    // x
        #expect(tokens[2] is PunctuationToken)   // =
        #expect(tokens[3] is LiteralToken)       // 42
        #expect(tokens[4] is PunctuationToken)   // ;
    }

    @Test("Token location")
    func tokenLocation() throws {
        let unit = try TranslationUnit(clangSource: "int x;", language: .c)
        let tokens = unit.tokens(in: unit.cursor.range)
        let first = try #require(tokens.first)
        let loc = first.location(in: unit)
        #expect(loc.line == 1)
        #expect(loc.column == 1)
    }

    @Test("Token range")
    func tokenRange() throws {
        let unit = try TranslationUnit(clangSource: "int x;", language: .c)
        let tokens = unit.tokens(in: unit.cursor.range)
        let first = try #require(tokens.first)
        let range = first.range(in: unit)
        #expect(range.start.column == 1)
    }

    @Test("Annotate tokens")
    func annotateTokens() throws {
        let src = "int x = 1;"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        let tokens = unit.tokens(in: unit.cursor.range)
        let cursors = unit.annotate(tokens: tokens)
        #expect(!cursors.isEmpty)
    }

    @Test("Empty range produces no tokens")
    func emptyRangeNoTokens() throws {
        let unit = try TranslationUnit(clangSource: "", language: .c)
        let tokens = unit.tokens(in: unit.cursor.range)
        #expect(tokens.isEmpty)
    }

    @Test("Comment token type")
    func commentTokenType() throws {
        let src = "/* a comment */ int x;"
        let unit = try TranslationUnit(
            clangSource: src, language: .c,
            options: [.detailedPreprocessingRecord]
        )
        let tokens = unit.tokens(in: unit.cursor.range)
        let hasComment = tokens.contains { $0 is CommentToken }
        #expect(hasComment)
    }
}
