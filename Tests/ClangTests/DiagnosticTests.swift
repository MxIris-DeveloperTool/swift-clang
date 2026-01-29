import Testing
import Foundation
@testable import CclangWrapper
@testable import Clang

@Suite("Diagnostics")
struct DiagnosticTests {
    @Test("Diagnostic count")
    func diagnosticCount() throws {
        let src = "void main() {int a = \"\"; return 0}"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        #expect(unit.diagnostics.count == 4)
    }

    @Test("Diagnostic severity")
    func diagnosticSeverity() throws {
        let unit = try TranslationUnit(
            clangSource: "int main(void) {int a; return 0;}",
            language: .c,
            commandLineArgs: ["-Wall"]
        )
        let diag = try #require(unit.diagnostics.first)
        let severity = try diag.severity
        #expect(severity == .warning)
    }

    @Test("Diagnostic description")
    func diagnosticDescription() throws {
        let unit = try TranslationUnit(
            clangSource: "int main(void) {int unused_var; return 0;}",
            language: .c,
            commandLineArgs: ["-Wall"]
        )
        let diag = try #require(unit.diagnostics.first)
        #expect(diag.description.contains("unused"))
    }

    @Test("Diagnostic format with options")
    func diagnosticFormat() throws {
        let unit = try TranslationUnit(
            clangSource: "int main(void) {int a; return 0;}",
            language: .c,
            commandLineArgs: ["-Wall"]
        )
        let diag = try #require(unit.diagnostics.first)
        let formatted = diag.format(options: [.option])
        #expect(!formatted.isEmpty)
    }

    @Test("No diagnostics for valid code")
    func noDiagnostics() throws {
        let unit = try TranslationUnit(
            clangSource: "int main(void) { return 0; }",
            language: .c
        )
        #expect(unit.diagnostics.isEmpty)
    }

    @Test("DiagnosticDisplayOptions flag values")
    func diagnosticDisplayOptionsFlags() {
        #expect(DiagnosticDisplayOptions.sourceLocation.rawValue != 0)
        #expect(DiagnosticDisplayOptions.column.rawValue != 0)
        #expect(DiagnosticDisplayOptions.sourceRanges.rawValue != 0)
        #expect(DiagnosticDisplayOptions.option.rawValue != 0)
        #expect(DiagnosticDisplayOptions.categoryId.rawValue != 0)
        #expect(DiagnosticDisplayOptions.categoryName.rawValue != 0)

        // Verify combining works
        let combined: DiagnosticDisplayOptions = [.sourceLocation, .column, .option]
        #expect(combined.contains(.sourceLocation))
        #expect(combined.contains(.column))
        #expect(combined.contains(.option))
        #expect(!combined.contains(.categoryName))
    }

    @Test("Diagnostic ranges")
    func diagnosticRanges() throws {
        let src = "void foo() { int x = \"hello\"; }"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        let diags = unit.diagnostics
        #expect(!diags.isEmpty)
        // At least one diagnostic should exist; ranges may or may not be present
        for diag in diags {
            _ = diag.ranges
        }
    }

    @Test("FixIt from diagnostic")
    func fixItFromDiagnostic() throws {
        // Semicolon missing should produce a fix-it
        let src = "int x = 1"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        let diags = unit.diagnostics
        let allFixits = diags.flatMap { $0.fixits }
        // There should be at least one fix-it suggesting a semicolon
        #expect(!allFixits.isEmpty)
        let semicolonFixit = allFixits.first { $0.fixit == ";" }
        #expect(semicolonFixit != nil)
    }

    @Test("LoadDiagError cases")
    func loadDiagErrorCases() {
        #expect(LoadDiagError(clang: CXLoadDiag_None) == nil)
        #expect(LoadDiagError(clang: CXLoadDiag_Unknown) == .unknown)
        #expect(LoadDiagError(clang: CXLoadDiag_CannotLoad) == .cannotLoad)
        #expect(LoadDiagError(clang: CXLoadDiag_InvalidFile) == .invalidFile)
    }
}
