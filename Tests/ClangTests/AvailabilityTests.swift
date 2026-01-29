import Testing
import Foundation
@testable import CclangWrapper
@testable import Clang

@Suite("Availability")
struct AvailabilityTests {
    @Test("Cursor availability for normal declaration")
    func cursorAvailability() throws {
        let src = "void foo(void) {}"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        var found = false
        unit.visitChildren { cursor in
            if cursor is FunctionDecl {
                let avail = cursor.availability
                #expect(!avail.alwaysDeprecated)
                #expect(!avail.alwaysUnavailable)
                found = true
            }
            return .recurse
        }
        #expect(found)
    }

    @Test("Version zero")
    func versionZero() {
        let v = Version.zero
        #expect(v.major == 0)
        #expect(v.minor == 0)
        #expect(v.subminor == 0)
    }

    @Test("Version init")
    func versionInit() {
        let v = Version(major: 10, minor: 7, subminor: 3)
        #expect(v.major == 10)
        #expect(v.minor == 7)
        #expect(v.subminor == 3)
    }

    @Test("Availability messages are nil for normal functions")
    func availabilityMessages() throws {
        let src = "void bar(void) {}"
        let unit = try TranslationUnit(clangSource: src, language: .c)
        var found = false
        unit.visitChildren { cursor in
            if cursor is FunctionDecl {
                let avail = cursor.availability
                #expect(avail.deprecationMessage == nil)
                #expect(avail.unavailableMessage == nil)
                #expect(avail.platforms.isEmpty)
                found = true
            }
            return .recurse
        }
        #expect(found)
    }
}
