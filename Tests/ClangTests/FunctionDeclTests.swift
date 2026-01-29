import Testing
import Foundation
@testable import CclangWrapper
@testable import Clang

@Suite("FunctionDecl Extended")
struct FunctionDeclTests {
    @Test("CallingConvention enum cases")
    func callingConventionCases() {
        #expect(CallingConvention(clang: CXCallingConv_Default) == .default)
        #expect(CallingConvention(clang: CXCallingConv_C) == .c)
        #expect(CallingConvention(clang: CXCallingConv_X86StdCall) == .x86StdCall)
        #expect(CallingConvention(clang: CXCallingConv_X86FastCall) == .x86FastCall)
        #expect(CallingConvention(clang: CXCallingConv_X86ThisCall) == .x86ThisCall)
        #expect(CallingConvention(clang: CXCallingConv_Swift) == .swift)
        #expect(CallingConvention(clang: CXCallingConv_PreserveMost) == .preserveMost)
        #expect(CallingConvention(clang: CXCallingConv_PreserveAll) == .preserveAll)
        #expect(CallingConvention(clang: CXCallingConv_Unexposed) == .unexposed)
        #expect(CallingConvention(clang: CXCallingConv_Invalid) == nil)
    }

    @Test("ObjCPropertyAttributes flag values")
    func objcPropertyAttributeFlags() {
        #expect(ObjCPropertyAttributes.noattr.rawValue == 0)
        #expect(ObjCPropertyAttributes.readonly.rawValue != 0)
        #expect(ObjCPropertyAttributes.getter.rawValue != 0)
        #expect(ObjCPropertyAttributes.assign.rawValue != 0)
        #expect(ObjCPropertyAttributes.readwrite.rawValue != 0)
        #expect(ObjCPropertyAttributes.retain.rawValue != 0)
        #expect(ObjCPropertyAttributes.copy.rawValue != 0)
        #expect(ObjCPropertyAttributes.nonatomic.rawValue != 0)
        #expect(ObjCPropertyAttributes.setter.rawValue != 0)
        #expect(ObjCPropertyAttributes.atomic.rawValue != 0)
        #expect(ObjCPropertyAttributes.weak.rawValue != 0)
        #expect(ObjCPropertyAttributes.strong.rawValue != 0)
        #expect(ObjCPropertyAttributes.unsafe_unretained.rawValue != 0)
        #expect(ObjCPropertyAttributes.`class`.rawValue != 0)

        // Verify combining works
        let combined: ObjCPropertyAttributes = [.nonatomic, .strong]
        #expect(combined.contains(.nonatomic))
        #expect(combined.contains(.strong))
        #expect(!combined.contains(.readonly))
    }
}
