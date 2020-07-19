import XCTest
@testable import ParallelLoop

final class ParallelLoopTests: XCTestCase {
    func testExample() {
        testAtomicValue()
    }
}
extension ParallelLoopTests {
   /**
    * Atomic value test
    */
   fileprivate func testAtomicValue() {
     let x: Atomic<Int> = .init(0)
     DispatchQueue.concurrentPerform(iterations: 1000) { _ in
         x.mutate { $0 += 1 }
     }
     print(x.value) // 1000
     XCTAssertEqual(x.value, 1000)
   }
}
