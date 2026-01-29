import Testing
import Foundation
@testable import CclangWrapper
@testable import Clang

@Suite("Comments")
struct CommentTests {
    @Test("Full comment from documented function")
    func fullComment() throws {
        let filename = testFile(for: "comments.c")
        let unit = try TranslationUnit(
            filename: filename,
            commandLineArgs: ["-fparse-all-comments"]
        )
        var foundComment = false
        unit.visitChildren { cursor in
            if cursor is FunctionDecl, cursor.description == "add" {
                if let comment = cursor.fullComment {
                    let html = comment.html
                    #expect(!html.isEmpty)
                    foundComment = true
                }
            }
            return .recurse
        }
        #expect(foundComment)
    }

    @Test("Raw comment text")
    func rawComment() throws {
        let filename = testFile(for: "comments.c")
        let unit = try TranslationUnit(filename: filename)
        var found = false
        unit.visitChildren { cursor in
            if cursor is FunctionDecl, cursor.description == "add" {
                if let raw = cursor.rawComment {
                    #expect(raw.contains("Adds two integers"))
                    found = true
                }
            }
            return .recurse
        }
        #expect(found)
    }

    @Test("Brief comment text")
    func briefComment() throws {
        let filename = testFile(for: "comments.c")
        let unit = try TranslationUnit(filename: filename)
        var found = false
        unit.visitChildren { cursor in
            if cursor is FunctionDecl, cursor.description == "add" {
                if let brief = cursor.briefComment {
                    #expect(brief.contains("Adds"))
                    found = true
                }
            }
            return .recurse
        }
        #expect(found)
    }

    @Test("Full comment children include text and paragraphs")
    func fullCommentChildren() throws {
        let filename = testFile(for: "comments.c")
        let unit = try TranslationUnit(
            filename: filename,
            commandLineArgs: ["-fparse-all-comments"]
        )
        var foundChildren = false
        unit.visitChildren { cursor in
            if cursor is FunctionDecl, cursor.description == "add" {
                if let comment = cursor.fullComment {
                    let children = Array(comment.children)
                    #expect(!children.isEmpty)
                    // Should have paragraph or block command children
                    let hasParagraphOrBlock = children.contains {
                        $0 is ParagraphComment || $0 is BlockCommandComment || $0 is ParamCommandComment
                    }
                    #expect(hasParagraphOrBlock)
                    foundChildren = true
                }
            }
            return .recurse
        }
        #expect(foundChildren)
    }

    @Test("ParamCommandComment properties")
    func paramCommandComment() throws {
        let filename = testFile(for: "comments.c")
        let unit = try TranslationUnit(
            filename: filename,
            commandLineArgs: ["-fparse-all-comments"]
        )
        var foundParam = false
        unit.visitChildren { cursor in
            if cursor is FunctionDecl, cursor.description == "add" {
                if let comment = cursor.fullComment {
                    for child in comment.children {
                        if let param = child as? ParamCommandComment {
                            #expect(!param.name.isEmpty)
                            #expect(param.isValidIndex)
                            foundParam = true
                        }
                    }
                }
            }
            return .recurse
        }
        #expect(foundParam)
    }

    @Test("Full comment XML output")
    func fullCommentXML() throws {
        let filename = testFile(for: "comments.c")
        let unit = try TranslationUnit(
            filename: filename,
            commandLineArgs: ["-fparse-all-comments"]
        )
        var found = false
        unit.visitChildren { cursor in
            if cursor is FunctionDecl, cursor.description == "add" {
                if let comment = cursor.fullComment {
                    let xml = comment.xml
                    #expect(!xml.isEmpty)
                    #expect(xml.contains("Adds"))
                    found = true
                }
            }
            return .recurse
        }
        #expect(found)
    }

    @Test("TextComment text extraction")
    func textCommentText() throws {
        let filename = testFile(for: "comments.c")
        let unit = try TranslationUnit(
            filename: filename,
            commandLineArgs: ["-fparse-all-comments"]
        )
        var foundText = false
        unit.visitChildren { cursor in
            if cursor is FunctionDecl, cursor.description == "add" {
                if let comment = cursor.fullComment {
                    // Walk down to find a TextComment
                    for child in comment.children {
                        if let para = child as? ParagraphComment {
                            for subchild in para.children {
                                if let text = subchild as? TextComment {
                                    // TextComment has a text property
                                    _ = text.text
                                    foundText = true
                                }
                            }
                        }
                    }
                }
            }
            return .recurse
        }
        #expect(foundText)
    }
}
