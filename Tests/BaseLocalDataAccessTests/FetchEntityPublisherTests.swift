//
//  FetchEntityPublisherTests.swift
//  
//
//  Created by Hadi Zamani on 1/23/21.
//

import XCTest
import Combine
import CoreData
@testable import BaseLocalDataAccess

@available(iOS 13.0, *)
class FetchEntityPublisherTests: XCTestCase {
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

    func testFetchEntityIsSuccessful() {
        genericDataAccess.fetchEntityPublisher().sink { completion in
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

    func testFetchEntityThrowsFailFetchEntity() {
        genericDataAccess.set {
            throw EntityCRUDError.failFetchEntity("Mock")
        }

        genericDataAccess.fetchEntityPublisher().sink { completion in
            switch completion {
            case .finished:
                XCTFail()
            case .failure(let error):
                if case .failFetchEntity(let s) = error {
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

        genericDataAccess.fetchEntityPublisher().sink { completion in
            switch completion {
            case .finished:
                XCTFail()
            case .failure(let error):
                if case .failFetchEntity(let s) = error {
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

        genericDataAccess.fetchEntityPublisher(predicate: p).sink { completion in
            switch completion {
            case .finished:
                break
            case .failure( _ ):
                XCTFail()
            }
        } receiveValue: { result in
            XCTAssertEqual(result[0].id, Helper.predicate.value)
        }.store(in:&self.storage)
    }

    func testFetchEntityRetuensCorrectResultWhenPassesSort() {
        let s = SortObject(fieldName: "id", direction: .ascending)

        genericDataAccess.fetchEntityPublisher(sort: s).sink { completion in
            switch completion {
            case .finished:
                break
            case .failure( _ ):
                XCTFail()
            }
        } receiveValue: { result in
            XCTAssertEqual(result[0].id, Helper.sort.value)
        }.store(in:&self.storage)
    }

    func testFetchEntityRetuensCorrectResultWhenPassesfetchLimit() {
        genericDataAccess.fetchEntityPublisher(fetchLimit: 5).sink { completion in
            switch completion {
            case .finished:
                break
            case .failure( _ ):
                XCTFail()
            }
        } receiveValue: { result in
            XCTAssertEqual(result[0].id, Helper.fetchLimit.value)
        }.store(in:&self.storage)
    }

    func testFetchEntityRetuensCorrectResultWhenPassesfetchOfsset() {
        genericDataAccess.fetchEntityPublisher(fetchOffset: 10).sink { completion in
            switch completion {
            case .finished:
                break
            case .failure( _ ):
                XCTFail()
            }
        } receiveValue: { result in
            XCTAssertEqual(result[0].id, Helper.fetchOffset.value)
        }.store(in:&self.storage)
    }

    class MockGenericDataAccess<TEntity>: GenericDataAccess<TEntity> where TEntity: EntityProtocol, TEntity: AnyObject, TEntity: NSFetchRequestResult {

        var expectedBehavior: () throws -> Void = {}

        func set(expectedBehavior: @escaping () throws -> Void) {
            self.expectedBehavior = expectedBehavior
        }

        override func fetchEntity(predicate: PredicateProtocol? = nil, sort: SortProtocol? = nil, fetchLimit: Int? = nil, fetchOffset: Int? = nil) throws -> [TEntity] {

            try expectedBehavior()

            let entity = MockEntity()

            if let _ = predicate {
                entity.id = Helper.predicate.value
            } else if let _ = sort {
                entity.id = Helper.sort.value
            } else if let _ = fetchLimit {
                entity.id = Helper.fetchLimit.value
            } else if let _ = fetchOffset {
                entity.id = Helper.fetchOffset.value
            }

            return [entity as! TEntity]
        }
    }

    enum Helper {
        case predicate
        case sort
        case fetchLimit
        case fetchOffset

        var value: String {
            switch self {
            case .predicate:
                return "1"
            case .sort:
                return "2"
            case .fetchLimit:
                return "3"
            case .fetchOffset:
                return "4"
            }
        }
    }
}
