import XCTest
@testable import HelloWorld

final class HelloWorldTests: XCTestCase {
    func testGreet() {
        XCTAssertEqual(HelloWorld.greet(), "Hello, World!")
    }
}
