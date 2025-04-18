import Dependencies
import Foundation
import Numerics
import ShortID
import Tagged
import Testing

@testable import Networking

@Suite(.tags(.basics))
struct CacheTests {
  typealias TestCache = Cache<Int, String>

  let cache = TestCache()

  @Test func roundTrip() {
    withDependencies {
      $0.date = .constant(Date())
    } operation: {
      cache.insert("hello", forKey: 0)
      #expect(cache.value(forKey: 0) == "hello")
      #expect(cache[0] == "hello")
      cache[0] = "world"
      #expect(cache.value(forKey: 0) == "world")
      #expect(cache.value(forKey: 1) == nil)
      cache.removeValue(forKey: 0)
      #expect(cache.value(forKey: 0) == nil)
      cache[1] = "world"
      #expect(cache.value(forKey: 1) == "world")
      cache[1] = nil
      #expect(cache.value(forKey: 1) == nil)
    }
  }

  @Test func nscacheFacade() {
    #expect(cache.countLimit == 0)
    #expect(cache.totalCostLimit == 0)
    cache.countLimit = 10
    cache.totalCostLimit = 100
    #expect(cache.countLimit == 10)
    #expect(cache.totalCostLimit == 100)
  }

  @Test func durationBasedExpiry() {
    let date = Date()
    withDependencies {
      $0.date = .constant(date)
    } operation: {
      cache.insert("hello", forKey: 0, duration: 100)
      #expect(cache.value(forKey: 0) == "hello")
      #expect(cache.value(forKey: 1) == nil)
    }

    withDependencies {
      $0.date = .constant(date.addingTimeInterval(101))
    } operation: {
      #expect(cache.value(forKey: 0) == nil)
    }
  }

  @Test func codableRoundTrip() throws {
    try withDependencies {
      $0.date = .constant(Date())
    } operation: {
      cache.insert("hello", forKey: 0)
      cache.insert("world", forKey: 1)
      #expect(cache.value(forKey: 0) == "hello")
      #expect(cache.value(forKey: 1) == "world")
      let data = try JSONEncoder().encode(cache)
      let decoded = try JSONDecoder().decode(TestCache.self, from: data)
      #expect(decoded.value(forKey: 0) == "hello")
      #expect(decoded.value(forKey: 1) == "world")
    }
  }

  @Test func multithreading() async throws {
    await withDependencies {
      $0.date = .constant(Date())
    } operation: {
      await withTaskGroup(of: (String?, Int).self) { group in
        let cache = TestCache()
        let expectedCount: Int = 1000
        (1 ... expectedCount).forEach { _ in
          group.addTask {
            let key = Int.random(in: 0 ..< 10)
            let expectation = "Hello world \(key)"
            cache.insert(expectation, forKey: key)
            let value = cache.value(forKey: key)
            #expect(value == expectation)
            return (value, key)
          }
        }

        var count = 0
        for await _ in group {
          count += 1
        }

        #expect(count == expectedCount)
      }
    }
  }
}
