import Testing
import Foundation
@testable import CclangWrapper
@testable import Clang

@Suite("Language")
struct LanguageTests {
    @Test("File extension for C")
    func fileExtensionC() {
        #expect(Language.c.fileExtension == ".c")
    }

    @Test("File extension for C++")
    func fileExtensionCPlusPlus() {
        #expect(Language.cPlusPlus.fileExtension == ".cc")
    }

    @Test("File extension for Objective-C")
    func fileExtensionObjC() {
        #expect(Language.objectiveC.fileExtension == ".m")
    }
}
