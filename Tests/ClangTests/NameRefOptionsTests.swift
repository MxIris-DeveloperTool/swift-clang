import Testing
import Foundation
@testable import CclangWrapper
@testable import Clang

@Suite("NameRefOptions")
struct NameRefOptionsTests {
    @Test("NameRefOptions flag values")
    func nameRefOptionsFlags() {
        #expect(NameRefOptions.wantQualifier.rawValue != 0)
        #expect(NameRefOptions.wantTemplateArgs.rawValue != 0)
        #expect(NameRefOptions.wantSinglePiece.rawValue != 0)

        // Verify all values are distinct
        let values: [NameRefOptions] = [.wantQualifier, .wantTemplateArgs, .wantSinglePiece]
        for i in 0..<values.count {
            for j in (i+1)..<values.count {
                #expect(values[i].rawValue != values[j].rawValue)
            }
        }

        // Verify combining works
        let combined: NameRefOptions = [.wantQualifier, .wantTemplateArgs]
        #expect(combined.contains(.wantQualifier))
        #expect(combined.contains(.wantTemplateArgs))
        #expect(!combined.contains(.wantSinglePiece))
    }
}
