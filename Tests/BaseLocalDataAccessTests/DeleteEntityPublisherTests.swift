//
//  DeleteEntityPublisherTests.swift
//  
//
//  Created by Hadi Zamani on 2/6/21.
//

import XCTest
import Combine
import CoreData
@testable import BaseLocalDataAccess

@available(iOS 13.0, *)
class DeleteEntityPublisherTests: XCTestCase {
    private var storage = Set<AnyCancellable>()
    private var genericDataAccess: MockGenericDataAccess<MockEntity>!
    private var mockEntity: MockEntity!

    override func setUp() {
        super.setUp()

        genericDataAccess = MockGenericDataAccess<MockEntity>(context: MockManagedObjectContext())
        mockEntity = MockEntity()
    }

    override func tearDown() {
        super.tearDown()

        storage.forEach { $0.cancel() }
    }

    func testDeleteEntityIsSuccessful() {
        genericDataAccess.deleteEntityPublisher(entity: mockEntity).sink { completion in
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

    func testDeleteEntityThrowsFailDeleteEntity() {
        genericDataAccess.set {
            throw EntityCRUDError.failDeleteEntity("Mock")
        }

        genericDataAccess.deleteEntityPublisher(entity: mockEntity).sink { completion in
            switch completion {
            case .finished:
                XCTFail()
            case .failure(let error):
                if case .failDeleteEntity(let s) = error {
                    XCTAssertEqual("Mock", s)
                } else {
                    XCTFail()
                }
            }
        } receiveValue: { result in
            XCTAssertFalse(result)
        }.store(in:&self.storage)
    }

    func testDeleteEntityThrowsGeneralError() {
        enum MockError: Error {
            case general(String)
        }

        genericDataAccess.set {
            throw MockError.general("General Error")
        }

        genericDataAccess.deleteEntityPublisher(entity: mockEntity).sink { completion in
            switch completion {
            case .finished:
                XCTFail()
            case .failure(let error):
                if case .failDeleteEntity(let s) = error {
                    XCTAssertNotNil(s)
                } else {
                    XCTFail()
                }
            }
        } receiveValue: { result in
            XCTAssertFalse(result)
        }.store(in:&self.storage)
    }

    class MockGenericDataAccess<TEntity>: GenericDataAccess<TEntity> where TEntity: EntityProtocol, TEntity: AnyObject, TEntity: NSFetchRequestResult {

        var expectedBehavior: () throws -> Void = {}

        func set(expectedBehavior: @escaping () throws -> Void) {
            self.expectedBehavior = expectedBehavior
        }

        override func deleteEntity(_ entity: TEntity) throws {

            try expectedBehavior()
        }
    }
}
