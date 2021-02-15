//
//  FetchModelsPublisherTests.swift
//  
//
//  Created by Hadi Zamani on 2/14/21.
//

import XCTest
import Combine
import CoreData
@testable import BaseLocalDataAccess

@available(iOS 13.0, *)
class FetchModelsPublisherTests: XCTestCase {
    private var storage = Set<AnyCancellable>()
    private var genericDataAccess: MockGenericDataAccess<MockEntity>!
    private var p: GenericDataAccess<MockEntity>.FetchModelsPublisher<MockModel>!

    override func setUp() {
        super.setUp()

        genericDataAccess = MockGenericDataAccess<MockEntity>(context: MockManagedObjectContext())

        p = genericDataAccess.fetchModelsPublisher()
    }

    override func tearDown() {
        super.tearDown()

        storage.forEach { $0.cancel() }
    }

    func testFetchModelsIsSuccessful() {
        p.sink { completion in
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

    func testFetchModelsThrowsFailCreateModelWhenFetchEntityThrows() {
        genericDataAccess.set {
            throw EntityCRUDError.failFetchEntity("Mock")
        }

        p.sink { completion in
            switch completion {
            case .finished:
                XCTFail()
            case .failure(let error):
                if case ModelError.failCreateModel(let s) = error {
                    XCTAssertNotNil(s)
                } else {
                    XCTFail()
                }
            }
        } receiveValue: { result in
            XCTAssertNil(result)
        }.store(in:&self.storage)
    }

    func testFetchModelsThrowsFailCreateModelWhenToModelThrows() {

        genericDataAccess.setEntity(FailedToModelMockEntity())

        p.sink { completion in
            switch completion {
            case .finished:
                XCTFail()
            case .failure(let error):
                if case .failCreateModel(let s) = error {
                    XCTAssertNotNil(s)
                } else {
                    XCTFail()
                }
            }
        } receiveValue: { result in
            XCTAssertNil(result)
        }.store(in:&self.storage)
    }

    func testFetchModelsRetuensCorrectResultWhenPassesPredicate() {
        let p = PredicateObject(fieldName: "Id", operatorName: .equal, value: "1")

        genericDataAccess.fetchEntitiesPublisher(predicate: p).sink { completion in
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

    func testFetchModelsRetuensCorrectResultWhenPassesSort() {
        let s = SortObject(fieldName: "id", direction: .ascending)

        genericDataAccess.fetchEntitiesPublisher(sort: s).sink { completion in
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

    func testFetchModelsRetuensCorrectResultWhenPassesfetchLimit() {
        genericDataAccess.fetchEntitiesPublisher(fetchLimit: 5).sink { completion in
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

    func testFetchModelsRetuensCorrectResultWhenPassesfetchOfsset() {
        genericDataAccess.fetchEntitiesPublisher(fetchOffset: 10).sink { completion in
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

        private var entityToReturn: MockEntity? = nil
        var expectedBehavior: () throws -> Void = {}

        func set(expectedBehavior: @escaping () throws -> Void) {
            self.expectedBehavior = expectedBehavior
        }

        func setEntity(_ entity: MockEntity) {
            entityToReturn = entity
        }

        override func fetchEntity(predicate: PredicateProtocol? = nil, sort: SortProtocol? = nil, fetchLimit: Int? = nil, fetchOffset: Int? = nil) throws -> [TEntity] {

            try expectedBehavior()

            let entity: MockEntity

            if let entityToReturn = entityToReturn {
                entity = entityToReturn
            } else {
                entity = MockEntity()
            }

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


