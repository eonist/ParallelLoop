import Foundation
/**
 * Makes values work in parallel
 * - Note: NSLock could potentially also be used
 * - Note: Similar solution but with semaphore: https://stackoverflow.com/a/42156140/5389500 and https://gist.github.com/nestserau/ce8f5e5d3f68781732374f7b1c352a5a
 * - Note: More in-depth info around different locks: https://www.vadimbulavin.com/atomic-properties/
 * ## Examples:
 * let x: Atomic<Int> = .init(0)
 * DispatchQueue.concurrentPerform(iterations: 1000) { y in
 *    x.mutate { $0 += 1 }
 * }
 * print(x.value) // 1000
 * Fixme: ⚠️️ set lock , attributes: .concurrent ?
 */
public final class Atomic<Value> {
   private let lock = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!).\(UUID().uuidString)")
   private var _value: Value
   public var value: Value { lock.sync { self._value } }
   /**
    * Add the initial value
    */
   public init(_ value: Value) {
      self._value = value
   }
   /**
    * Mutate method that atomically mutates the underlying variable:
    */
   public func mutate(_ transform: (inout Value) -> Void) {
      lock.sync {
         transform(&self._value)
      }
   }
}
