//
//  FetchEntityWithIdPublisherTests.swift
//  
//
//  Created by Hadi Zamani on 2/14/21.
//

import XCTest
import Combine
import CoreData
@testable import BaseLocalDataAccess

@available(iOS 13.0, *)
class FetchEntityWithIdPublisherTests: XCTestCase {
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

    func testFetchEntityWithIdReturnsOneResultWhenOneItemExists() {

        genericDataAccess.set(itemsToReturn: [MockEntity()])

        genericDataAccess.fetchEntityPublisher(withId: UUID()).sink { completion in
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

    func testFetchEntityWithIdReturnsNilWhenThereIsNoItem() {
        genericDataAccess.fetchEntityPublisher(withId: UUID()).sink { completion in
            switch completion {
            case .finished:
                break
            case .failure( _ ):
                XCTFail()
            }
        } receiveValue: { result in
            XCTAssertNil(result)
        }.store(in:&self.storage)
    }

    func testFetchEntityWithIdThrowsErrorWhenMoreThanOnItemExists() {
        genericDataAccess.set(itemsToReturn: [MockEntity(), MockEntity()])

        genericDataAccess.fetchEntityPublisher(withId: UUID()).sink { completion in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                XCTAssertNotNil(error)
            }
        } receiveValue: { result in
            XCTFail()
        }.store(in:&self.storage)
    }

    class MockGenericDataAccess<TEntity>: GenericDataAccess<TEntity> where TEntity: EntityProtocol, TEntity: AnyObject, TEntity: NSFetchRequestResult {

        var itemsToReturn: [TEntity] = []

        func set(itemsToReturn: [TEntity]) {
            self.itemsToReturn = itemsToReturn
        }

        override func fetchEntity(predicate: PredicateProtocol? = nil, sort: SortProtocol? = nil, fetchLimit: Int? = nil, fetchOffset: Int? = nil) throws -> [TEntity] {

            return itemsToReturn
        }
    }
}

