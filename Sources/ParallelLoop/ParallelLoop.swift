import Foundation
/**
 * Helper methods for doing parallel operations
 */
public final class ParallelLoop {
   /**
    * Calculates a good number to divide big data-sets in when striding
    * - Note: Use in conjunction with [].divideBy(by: 20)
    * - Note: A good spread is around 10-20 or you can try: ProcessInfo().activeProcessorCount
    * distribution(itemCount: 200, spread: 10) // 20
    * distribution(itemCount: 10, spread: 10) // 1
    * - Parameter itemCount: num of items in big data set
    * - Parameter spread: number of threads to use
    */
   public static func distribution(itemCount: Int, spread: Int) -> Int {
      max(Int(floor(Double(itemCount / spread))), 1)
   }
}
