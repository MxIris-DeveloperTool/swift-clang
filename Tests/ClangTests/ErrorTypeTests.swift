import Testing
import Foundation
@testable import CclangWrapper
@testable import Clang

@Suite("Error Types")
struct ErrorTypeTests {
    @Test("ClangError cases")
    func clangErrorCases() {
        #expect(ClangError(clang: CXError_Failure) == .failure)
        #expect(ClangError(clang: CXError_Crashed) == .crashed)
        #expect(ClangError(clang: CXError_ASTReadError) == .astRead)
        #expect(ClangError(clang: CXError_InvalidArguments) == .invalidArguments)
        #expect(ClangError(clang: CXError_Success) == nil)
    }

    @Test("ClangSaveError cases")
    func clangSaveErrorCases() {
        #expect(ClangSaveError(clang: CXSaveError_Unknown) == .unknown)
        #expect(ClangSaveError(clang: CXSaveError_TranslationErrors) == .translationErrors)
        #expect(ClangSaveError(clang: CXSaveError_InvalidTU) == .invalidTranslationUnit)
    }
}
