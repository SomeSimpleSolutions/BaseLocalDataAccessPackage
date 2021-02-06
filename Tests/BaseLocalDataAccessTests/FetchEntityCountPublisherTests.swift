//
//  FetchEntityCountPublisherTests.swift
//  
//
//  Created by Hadi Zamani on 2/6/21.
//

import XCTest
import Combine
import CoreData
@testable import BaseLocalDataAccess

@available(iOS 13.0, *)
class FetchEntityCountPublisherTests: XCTestCase {
    private var storage = Set<AnyCancellable>()
    private var genericDataAccess: MockGenericDataAccess<MockEntity>!

    override func setUp() {
        super.setUp()

        genericDataAccess = MockGenericDataAccess<MockEntity>(context: MockManagedObjectContext())
    }

    override func tearDown() {
        super.tearDown()

        storage.forEach { $0.cancel() }
    }

    func testFetchEntityCountIsSuccessful() {
        genericDataAccess.fetchEntityCountPublisher().sink { completion in
            switch completion {
            case .finished:
                break
            case .failure( _ ):
                XCTFail()
            }
        } receiveValue: { result in
            XCTAssertNotNil(result)
        }.store(in:&self.storage)
    }

    func testFetchEntityCountThrowsFailFetchCountEntity() {
        genericDataAccess.set {
            throw EntityCRUDError.failFetchEntityCount("Mock")
        }

        genericDataAccess.fetchEntityCountPublisher().sink { completion in
            switch completion {
            case .finished:
                XCTFail()
            case .failure(let error):
                if case .failFetchEntityCount(let s) = error {
                    XCTAssertEqual("Mock", s)
                } else {
                    XCTFail()
                }
            }
        } receiveValue: { result in
            XCTAssertNil(result)
        }.store(in:&self.storage)
    }

    func testFetchEntityThrowsGeneralError() {
        enum MockError: Error {
            case general(String)
        }

        genericDataAccess.set {
            throw MockError.general("General Error")
        }

        genericDataAccess.fetchEntityCountPublisher().sink { completion in
            switch completion {
            case .finished:
                XCTFail()
            case .failure(let error):
                if case .failFetchEntityCount(let s) = error {
                    XCTAssertNotNil(s)
                } else {
                    XCTFail()
                }
            }
        } receiveValue: { result in
            XCTAssertNil(result)
        }.store(in:&self.storage)
    }

    func testFetchEntityRetuensCorrectResultWhenPassesPredicate() {
        let p = PredicateObject(fieldName: "Id", operatorName: .equal, value: "1")

        genericDataAccess.fetchEntityCountPublisher(predicate: p).sink { completion in
            switch completion {
            case .finished:
                break
            case .failure( _ ):
                XCTFail()
            }
        } receiveValue: { result in
            XCTAssertEqual(result, Helper.predicateResultCount)
        }.store(in:&self.storage)
    }

    class MockGenericDataAccess<TEntity>: GenericDataAccess<TEntity> where TEntity: EntityProtocol, TEntity: AnyObject, TEntity: NSFetchRequestResult {

        var expectedBehavior: () throws -> Void = {}

        func set(expectedBehavior: @escaping () throws -> Void) {
            self.expectedBehavior = expectedBehavior
        }

        override func fetchEntityCount(predicate: PredicateProtocol? = nil) throws -> Int {

            try expectedBehavior()

            if let _ = predicate {
                return Helper.predicateResultCount
            }

            return 1
        }
    }

    private struct Helper {
        fileprivate static let predicateResultCount = 3
    }
}
