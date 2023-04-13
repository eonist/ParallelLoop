![Tests](https://github.com/light-stream/ParallelLoop/workflows/Tests/badge.svg)

# ParallelLoop 💞

> Parallel + functional operations in swift

### Features:
- 👯‍♂️ Process data in parallel over many cpu-cores and awaits
- 💜 Functional operations you already know and love
- ⚛️ Thread safe values across cpu-cores with AtomicValue
- ⏩ Easily stride big data-sets with the array divide operation
- 🎚Toggle concurrency on / off 

### Examples:
```swift
// Parallel map
let result = [0, 1, 2, 3].concurrentMap { i in
   i * 2
}
print(result) // 0, 2, 4, 6

// Parallel forEach
[1, 2, 3, 4].concurrentForEach {
   print($0) // 1,2,3,4
}

// Parallel compactMap
let array = [0, 1, nil, 3].concurrentCompactMap { i in
   i * 2
}
print(array) // 0, 2, 6

// Parallel reduce
let str: String = [0, 1, 2].concurrentReduce("") {
   $0 + "\( $1)"
} // "012"
print(str)

// Atomic value:
let x: Atomic<Int> = .init(0) // can be written and read across cores and threads
DispatchQueue.concurrentPerform(iterations: 1000) { y in
   x.mutate { $0 += 1 }
}
print(x.value) // 1000

// Stride concurrent operations on big data sets
// We stride to utlize cores better
// The cost of managing threads out way the benefit on big data sets
let batches = Array(0..<1000).divideBy(by: 20) // try different amounts
batches.concurrentForEach { batch in // one batch at the time (50 times), avoids cpu admin overhead
   batch.forEach { $0 } // only assigns 20 operations at the time
} // Use .flatMap { $0 } if you need to flatten the result etc

// or even easier:
// The batches method also ensures a good distribution for big and small data sets
// great when the data-set count varies
Array(0..<1000).batches(spread: 20).concurrentForEach { batch in
   batch.forEach { $0 }
}

// Another example using flatMap:
let values: [Int] = Array(0..<1000).batches(spread: 20).concurrentFlatMap { batch in
   batch.map { $0 }
}
```

### Installation:
- Swift packag manager: `.package(url: "https://github.com/passbook/ParallelLoop.git", .branch("master"))`
- XCode package-manager: search for `ParallelLoop`
