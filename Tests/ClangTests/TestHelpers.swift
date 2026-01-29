import Foundation

func testFile(for filename: String) -> String {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("input_tests")
        .appendingPathComponent(filename)
        .path
}
