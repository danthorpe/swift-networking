import Foundation

public func measureExecutionTime<Output>(
  operation: () async -> Output
) async -> (output: Output, seconds: Double) {
  let start = DispatchTime.now()
  let output = await operation()
  let end = DispatchTime.now()
  let seconds = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / Double(NSEC_PER_SEC)
  return (output, seconds)
}

public func measureConcurrentOperations(
  acrossCores cores: Int =  ProcessInfo.processInfo.activeProcessorCount,
  count: Int = 1000,
  operation: @escaping @Sendable (Int) async -> Void
) async -> Double {
  await measureExecutionTime {
    await withTaskGroup(of: Void.self) { group in
      let tasksPerCore = count / cores
      for c in 0 ..< cores {
        group.addTask {
          let start = c * tasksPerCore
          let end = (c + 1) * tasksPerCore
          for i in start ..< end {
            await operation(i)
          }
        }
      }
      group.addTask {
        for i in (cores * tasksPerCore) ..< count {
          await operation(i)
        }
      }
    }
  }.seconds
}
