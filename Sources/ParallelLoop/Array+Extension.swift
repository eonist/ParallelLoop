import Foundation
/**
 * Operations
 */
extension Array {
   /**
    * Map with parallel processing (returns array in correct order as well)
    * - Fixme: ⚠️️ you could add rethrow and throw on this method, but it would work after looping sort of
    * - Fixme: ⚠️️ might need to run things on global que, man que could result in deadlock with concurrentPerform DispatchQueue.global().async { }
    * - Note: Should work from any queue you call it from, it will just return once it's done
    * - Note: This will block the thread you call it from (just like the non-concurrent map will), so make sure to dispatch this to a background queue.
    * - Note: One needs to ensure that there is enough work on each thread to justify the inherent overhead of managing all of these threads. (E.g. a simple xor call per loop is not sufficient, and you'll find that it's actually slower than the non-concurrent rendition.) In these cases, make sure you stride (see Improving Loop Code that balances the amount of work per concurrent block). For example, rather than doing 5000 iterations of one extremely simple operation, do 10 iterations of 500 operations per loop. You may have to experiment with suitable striding values.
    * - Note: Many iterations and a small amount of work per iteration can create so much overhead that it negates any gains from making the calls concurrent. The technique known as striding helps you out here
    * - Note: on striding: https://developer.apple.com/library/archive/documentation/General/Conceptual/ConcurrencyProgrammingGuide/ThreadMigration/ThreadMigration.html#//apple_ref/doc/uid/TP40008091-CH105-SW2
    * - Note: Striding in general: Striding allows you to do multiple pieces of work for each iteration.
    * - Note: you can log thread count / id with Thread.current
    * ## Examples:
    * [0, 1, 2, 3].concurrentMap { i in i * 2 } // 0, 2, 4, 6
    */
   @discardableResult
   public func concurrentMap<T>(transform: @escaping (Element) -> T) -> [T] {
      let buffer: UnsafeMutablePointer<T> = .allocate(capacity: count) // Create a thread safe array
      defer { buffer.deallocate() } // Always clean up allocated resources
      DispatchQueue.concurrentPerform(iterations: count) { i in
         buffer.advanced(by: i).initialize(to: transform(self[i]))
      }
      return .init(UnsafeBufferPointer(start: buffer, count: count))
   }
   /**
    * ForEach with parallel processing (Synchronous)
    * - Note: Convenient
    * ## Examples:
    * [1, 2, 3, 4].concurrentForEach { print($0) }
    */
   public func concurrentForEach(transform: @escaping (Element) -> Void) {
      concurrentMap { _ = transform($0) }
   }
   /**
    * Convenience
    * ## Examples:
    * [0, 1, nil, 3].concurrentCompactMap { i in i * 2 } // 0, 2, 6
    */
   public func concurrentCompactMap<T>(transform: @escaping (Element) -> T?) -> [T] {
      concurrentMap(transform: transform).compactMap { $0 }
   }
   /**
    * Convenience
    */
   public func concurrentFlatMap<T>(transform: @escaping (Element) -> T) -> [T.Element] where T : Sequence {
      concurrentMap(transform: transform).flatMap { $0 }
   }
}
/**
 * Experimental
 */
extension Array {
   /**
    * ⚠️️ New, not fully tested ⚠️️
    * ## Examples:
    * let str: String = [0, 1, 2].concurrentReduce("") { $0 + "\( $1)" } // "012"
    */
   public func concurrentReduce<T>(_ initValue: T, transform: @escaping (_ acc: T, _ new: Element) -> T) -> T {
      let lock = NSLock() // needed when accessing a variable from many threads
      var initValue = initValue
      concurrentForEach { item in
         let tempVal = transform(initValue, item) // we have to do the processing outside the lock operation
         lock.lock() // lock.sync {} // probably extend NSlock to make this functionality
         initValue = tempVal // needed when accessing a variable from many threads
         lock.unlock()
      }
      return initValue
   }
   /**
    * ⚠️️ Testing / Experimental ⚠️️
    * - Ref: https://swift.org/blog/tsan-support-on-linux/
    * - Note: the .barrier flag to allow concurrent reads, but block access when a write is in progress
    * - Note: More info on barrier here: https://basememara.com/creating-thread-safe-arrays-in-swift/
    * - Note: Its also possible to do this with NSLock and .sync {} see your concurrent post from 2019
    * ## Examples:
    * [0, 1, 2, 3].concurrentMap2 { i in i * 2 } // 0, 2, 4, 6
    */
   internal func concurrentMap2<T>(_ transform: (Element) -> T) -> [T] {
      var results = [Int: T]()
      let queue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!).\(UUID().uuidString)", attributes: .concurrent)
      DispatchQueue.concurrentPerform(iterations: count) { index in
         let result = transform(self[index])
         queue.async { results[index] = result }
      }
      return queue.sync(flags: .barrier) {
         (0 ..< results.count).map { results[$0]! }
      }
   }
}
/**
 * Helper
 */
extension Array {
   /**
    * Used to make concurrent striding simpler
    * ## Examples:
    * let batches = Array(0..<1000).divideBy(by: 20) // batches now have 50 items
    * batches.forEach { batch in batch.concurrentForEach { $0 } }
    * - Fixme: ⚠️️ rename to divide(by:)
    */
   public func divideBy(by size: Int) -> [[Element]] {
      stride(from: 0, to: self.count, by: size).map {
         Array(self[$0..<Swift.min($0 + size, self.count)])
      }
   }
   /**
    * Returns batches for spread
    * - Parameter spread: number of threads to use
    */
   public func batches(spread: Int) -> [[Element]] {
      let distribution: Int = ParallelLoop.distribution(itemCount: self.count, spread: spread)
      return divideBy(by: distribution)
   }
}
