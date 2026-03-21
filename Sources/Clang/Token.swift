@preconcurrency package import CclangWrapper

import Foundation

/// Represents a C, C++, or Objective-C token.
public protocol Token {
}

protocol ClangTokenBacked {
    var clang: CXToken { get }
}

extension Token {
    var clangToken: CXToken {
        (self as! ClangTokenBacked).clang
    }
}

extension Token {
    /// Determine the spelling of the given token.
    /// The spelling of a token is the textual representation of that token,
    /// e.g., the text of an identifier or keyword.
    public func spelling(in translationUnit: TranslationUnit) -> String {
        return clang_getTokenSpelling(translationUnit.clang, clangToken).asSwift()
    }

    /// Retrieve the source location of the given token.
    /// - param translationUnit: The translation unit in which you're looking
    ///                          for this token.
    public func location(in translationUnit: TranslationUnit) -> SourceLocation {
        return SourceLocation(clang: clang_getTokenLocation(translationUnit.clang,
                                                            clangToken))
    }

    /// Retrieve a source range that covers the given token.
    /// - param translationUnit: The translation unit in which you're looking
    ///                          for this token.
    public func range(in translationUnit: TranslationUnit) -> SourceRange {
        return SourceRange(clang: clang_getTokenExtent(translationUnit.clang,
                                                       clangToken))
    }
}

/// A token that contains some kind of punctuation.
public struct PunctuationToken: Token, ClangTokenBacked {
    package let clang: CXToken
}

/// A language keyword.
public struct KeywordToken: Token, ClangTokenBacked {
    package let clang: CXToken
}

/// An identifier (that is not a keyword).
public struct IdentifierToken: Token, ClangTokenBacked {
    package let clang: CXToken
}

/// A numeric, string, or character literal.
public struct LiteralToken: Token, ClangTokenBacked {
    package let clang: CXToken
}

/// A comment.
public struct CommentToken: Token, ClangTokenBacked {
    package let clang: CXToken
}

/// Converts a CXToken to a Token.
/// - throws: `ClangError.unexpectedValue` if the token kind is unrecognized.
func convertToken(_ clang: CXToken) throws -> Token {
    switch clang_getTokenKind(clang) {
    case CXToken_Punctuation: return PunctuationToken(clang: clang)
    case CXToken_Keyword: return KeywordToken(clang: clang)
    case CXToken_Identifier: return IdentifierToken(clang: clang)
    case CXToken_Literal: return LiteralToken(clang: clang)
    case CXToken_Comment: return CommentToken(clang: clang)
    default: throw ClangError.unexpectedValue
    }
}

public struct SourceLocation: Sendable {
    let clang: CXSourceLocation

    /// Creates a SourceLocation.
    /// - parameter clang: A CXSourceLocation.
    init(clang: CXSourceLocation) {
        self.clang = clang
    }

    /// Creates a source location associated with a given file/line/column
    /// in a particular translation unit
    /// - parameters:
    ///   - translationUnit: The translation unit associated with the location
    ///       to extract.
    ///   - file: Source file.
    ///   - line: The line number in the source file.
    ///   - column: The column number in the source file.
    public init(translationUnit: TranslationUnit,
                file: File, line: Int, column: Int) {
        self.clang = clang_getLocation(
            translationUnit.clang, file.clang, UInt32(line), UInt32(column)
        )
    }

    /// Creates a source location associated with a given character offset
    /// in a particular translation unit
    /// - parameters:
    ///   - translationUnit: The translation unit associated with the location
    ///       to extract.
    ///   - file: Source file.
    ///   - offset: character offset in the source file.
    public init(translationUnit: TranslationUnit, file: File, offset: Int) {
        self.clang = clang_getLocationForOffset(
            translationUnit.clang, file.clang, UInt32(offset)
        )
    }

    /// Retrieves all file, line, column, and offset attributes of the provided
    /// source location.
    internal var locations: (file: File, line: Int, column: Int, offset: Int)? {
        var l = 0 as UInt32
        var c = 0 as UInt32
        var o = 0 as UInt32
        var f: CXFile?
        clang_getFileLocation(clang, &f, &l, &c, &o)
        guard let f else { return nil }
        return (file: File(clang: f), line: Int(l), column: Int(c),
                offset: Int(o))
    }

    public func cursor(in translationUnit: TranslationUnit) -> Cursor? {
        return clang_getCursor(translationUnit.clang, clang)
    }

    /// The line to which the given source location points.
    public var line: Int {
        return locations?.line ?? 0
    }

    /// The column to which the given source location points.
    public var column: Int {
        return locations?.column ?? 0
    }

    /// The offset into the buffer to which the given source location points.
    public var offset: Int {
        return locations?.offset ?? 0
    }

    /// The file to which the given source location points.
    public var file: File {
        guard let locations else {
            preconditionFailure("SourceLocation has no associated file")
        }
        return locations.file
    }

    /// Returns if the given source location is in the main file of
    /// the corresponding translation unit.
    public var isFromMainFile: Bool {
        return clang_Location_isFromMainFile(clang) != 0
    }
}

/// Represents a half-open character range in the source code.
public struct SourceRange: Sendable {
    let clang: CXSourceRange

    /// Creates a SourceRange.
    /// - clang: A CXSourceRange.
    init(clang: CXSourceRange) {
        self.clang = clang
    }

    /// Creates a range from two locations.
    /// - parameters:
    ///   - start: Location of the start of the range.
    ///   - end: Location of the end of the range.
    /// - note: The range is half opened [start..<end]. That means that the end
    ///     location is not included.
    public init(start: SourceLocation, end: SourceLocation) {
        self.clang = clang_getRange(start.clang, end.clang)
    }

    /// Retrieve a source location representing the first character within a
    /// source range.
    public var start: SourceLocation {
        return SourceLocation(clang: clang_getRangeStart(clang))
    }

    /// Retrieve a source location representing the last character within a
    /// source range.
    public var end: SourceLocation {
        return SourceLocation(clang: clang_getRangeEnd(clang))
    }
}
