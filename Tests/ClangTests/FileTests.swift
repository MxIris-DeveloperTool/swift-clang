import Testing
import Foundation
@testable import CclangWrapper
@testable import Clang

@Suite("Files")
struct FileTests {
    @Test("File name")
    func fileName() throws {
        let filename = testFile(for: "init-ast.c")
        let unit = try TranslationUnit(filename: filename)
        let file = try #require(unit.getFile(for: filename))
        #expect(file.name.hasSuffix("init-ast.c"))
    }

    @Test("File last modified date")
    func fileLastModified() throws {
        let filename = testFile(for: "init-ast.c")
        let unit = try TranslationUnit(filename: filename)
        let file = try #require(unit.getFile(for: filename))
        // Date should be valid (non-zero)
        #expect(file.lastModified.timeIntervalSince1970 > 0)
    }

    @Test("File equality")
    func fileEquality() throws {
        let filename = testFile(for: "init-ast.c")
        let unit = try TranslationUnit(filename: filename)
        let file1 = try #require(unit.getFile(for: filename))
        let file2 = try #require(unit.getFile(for: filename))
        #expect(file1 == file2)
    }

    @Test("File hashing consistency")
    func fileHashing() throws {
        let filename = testFile(for: "init-ast.c")
        let unit = try TranslationUnit(filename: filename)
        let file1 = try #require(unit.getFile(for: filename))
        let file2 = try #require(unit.getFile(for: filename))
        #expect(file1.hashValue == file2.hashValue)
    }

    @Test("UniqueFileID equality and hashing")
    func uniqueFileID() throws {
        let filename = testFile(for: "init-ast.c")
        let unit = try TranslationUnit(filename: filename)
        let file = try #require(unit.getFile(for: filename))

        // UniqueFileID may or may not be available depending on the file
        if let id1 = file.uniqueID {
            // If available, it should be consistent
            if let id2 = file.uniqueID {
                #expect(id1 == id2)
                #expect(id1.hashValue == id2.hashValue)
            }
        }
    }
}

// MARK: - UnsavedFile

@Suite("UnsavedFile")
struct UnsavedFileTests {
    @Test("Create and read back UnsavedFile properties")
    func createAndReadBack() {
        let unsavedFile = UnsavedFile(filename: "a.c", contents: "void f(void);")

        #expect(unsavedFile.filename == "a.c")
        #expect(strcmp(unsavedFile.clang.Filename, "a.c") == 0)

        #expect(unsavedFile.contents == "void f(void);")
        #expect(strcmp(unsavedFile.clang.Contents, "void f(void);") == 0)
        #expect(unsavedFile.clang.Length == 13)
    }

    @Test("Mutate UnsavedFile properties")
    func mutateProperties() {
        let unsavedFile = UnsavedFile(filename: "a.c", contents: "void f(void);")

        unsavedFile.filename = "b.c"
        #expect(unsavedFile.filename == "b.c")
        #expect(strcmp(unsavedFile.clang.Filename, "b.c") == 0)

        unsavedFile.contents = "int add(int, int);"
        #expect(unsavedFile.contents == "int add(int, int);")
        #expect(strcmp(unsavedFile.clang.Contents, "int add(int, int);") == 0)
        #expect(unsavedFile.clang.Length == 18)
    }

    @Test("Default UnsavedFile has empty values")
    func defaultUnsavedFile() {
        let unsavedFile = UnsavedFile()
        #expect(unsavedFile.filename == "")
        #expect(unsavedFile.contents == "")
    }
}

// MARK: - Visit Inclusion

@Suite("Visit Inclusion")
struct VisitInclusionTests {
    @Test("Visit inclusions")
    func visitInclusion() throws {
        func fileName(_ file: File) -> String {
            file.name.components(separatedBy: "/").last!
        }

        let unit = try TranslationUnit(filename: testFile(for: "inclusion.c"))
        var inclusion = [[String]]()
        unit.visitInclusion { file, stack in
            let inc = [fileName(file)] + stack.map { fileName($0.file) }
            inclusion.append(inc)
        }
        #expect(inclusion == [
            ["inclusion.c"],
            ["inclusion-header.h", "inclusion.c"],
        ])
    }
}
