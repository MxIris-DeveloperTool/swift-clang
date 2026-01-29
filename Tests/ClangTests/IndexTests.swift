import Testing
import Foundation
@testable import CclangWrapper
@testable import Clang

@Suite("Index")
struct IndexTests {
    @Test("Create index with default parameters")
    func createDefaultIndex() {
        let index = Index()
        // Should not crash
        _ = index.clang
    }

    @Test("Create index with custom parameters")
    func createCustomIndex() {
        let index = Index(excludeDeclarationsFromPCH: false, displayDiagnostics: false)
        _ = index.clang
    }

    @Test("GlobalOptions flag values")
    func globalOptionsFlags() {
        #expect(GlobalOptions.none.rawValue == 0)
        #expect(GlobalOptions.threadBackgroundPriorityForIndexing.rawValue != 0)
        #expect(GlobalOptions.threadBackgroundPriorityForEditing.rawValue != 0)
        #expect(GlobalOptions.threadBackgroundPriorityForAll.rawValue != 0)

        // threadBackgroundPriorityForAll should combine indexing and editing
        let all = GlobalOptions.threadBackgroundPriorityForAll
        #expect(all.contains(.threadBackgroundPriorityForIndexing))
        #expect(all.contains(.threadBackgroundPriorityForEditing))
    }

    @Test("IndexOptFlags flag values")
    func indexOptFlags() {
        #expect(IndexOptFlags.none.rawValue == 0)
        #expect(IndexOptFlags.supressRedundantRefs.rawValue != 0)
        #expect(IndexOptFlags.indexFunctionLocalSymbols.rawValue != 0)
        #expect(IndexOptFlags.indexImplicitTemplateInstantiations.rawValue != 0)
        #expect(IndexOptFlags.supressWarnings.rawValue != 0)
        #expect(IndexOptFlags.skipParsedBodiesInSession.rawValue != 0)

        // Verify combining works
        let combined: IndexOptFlags = [.supressRedundantRefs, .supressWarnings]
        #expect(combined.contains(.supressRedundantRefs))
        #expect(combined.contains(.supressWarnings))
        #expect(!combined.contains(.indexFunctionLocalSymbols))
    }
}

// MARK: - Index Action

@Suite("Index Action")
struct IndexActionTests {
    @Test("Index translation unit finds functions")
    func indexTranslationUnit() throws {
        let filename = testFile(for: "index-action.c")
        let unit = try TranslationUnit(filename: filename)

        let indexerCallbacks = Clang.IndexerCallbacks()
        var functionsFound = Set<String>()
        indexerCallbacks.indexDeclaration = { decl in
            if decl.cursor is FunctionDecl {
                functionsFound.insert(decl.cursor!.description)
            }
        }

        try unit.indexTranslationUnit(
            indexAction: IndexAction(),
            indexerCallbacks: indexerCallbacks,
            options: .none
        )

        #expect(functionsFound == Set(["main", "didLaunch"]))
    }

    @Test("IdxDeclInfo properties")
    func idxDeclInfoProperties() throws {
        let filename = testFile(for: "index-action.c")
        let unit = try TranslationUnit(filename: filename)

        let indexerCallbacks = Clang.IndexerCallbacks()
        var foundDefinition = false
        indexerCallbacks.indexDeclaration = { decl in
            if decl.cursor is FunctionDecl, decl.cursor?.description == "main" {
                #expect(decl.isDefinition)
                #expect(!decl.isRedeclaration)
                foundDefinition = true
            }
        }

        try unit.indexTranslationUnit(
            indexAction: IndexAction(),
            indexerCallbacks: indexerCallbacks,
            options: .none
        )
        #expect(foundDefinition)
    }

    @Test("IndexerCallbacks nil indexDeclaration")
    func indexerCallbacksNilDeclaration() throws {
        let callbacks = Clang.IndexerCallbacks()
        // Setting to nil should not crash
        callbacks.indexDeclaration = nil
        #expect(callbacks.indexDeclaration == nil)
    }
}
