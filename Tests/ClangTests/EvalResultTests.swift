import Testing
import Foundation
@testable import CclangWrapper
@testable import Clang

@Suite("Eval Result")
struct EvalResultTests {
    @Test("Evaluate integer constant")
    func evaluateIntConstant() throws {
        let filename = testFile(for: "eval.c")
        let unit = try TranslationUnit(filename: filename)
        var found = false
        unit.visitChildren { cursor in
            if cursor is VarDecl, cursor.description == "MAGIC" {
                if let result = cursor.evaluate() {
                    if case .int(let value) = result {
                        #expect(value == 42)
                        found = true
                    }
                }
            }
            return .recurse
        }
        #expect(found)
    }

    @Test("Evaluate float constant")
    func evaluateFloatConstant() throws {
        let filename = testFile(for: "eval.c")
        let unit = try TranslationUnit(filename: filename)
        var found = false
        unit.visitChildren { cursor in
            if cursor is VarDecl, cursor.description == "PI" {
                if let result = cursor.evaluate() {
                    if case .float(let value) = result {
                        #expect(abs(value - 3.14159) < 0.001)
                        found = true
                    }
                }
            }
            return .recurse
        }
        #expect(found)
    }

    @Test("Evaluate string literal")
    func evaluateStringLiteral() throws {
        let filename = testFile(for: "eval.c")
        let unit = try TranslationUnit(filename: filename)
        var found = false
        unit.visitChildren { cursor in
            if cursor is VarDecl, cursor.description == "GREETING" {
                if let result = cursor.evaluate() {
                    if case .stringLiteral(let value) = result {
                        #expect(value == "hello")
                        found = true
                    }
                }
            }
            return .recurse
        }
        #expect(found)
    }

    @Test("Evaluate enum constant")
    func evaluateEnumConstant() throws {
        let filename = testFile(for: "eval.c")
        let unit = try TranslationUnit(filename: filename)
        var found = false
        unit.visitChildren { cursor in
            if let ec = cursor as? EnumConstantDecl, ec.description == "FLAG_C" {
                #expect(ec.value == 4)
                found = true
            }
            return .recurse
        }
        #expect(found)
    }
}
