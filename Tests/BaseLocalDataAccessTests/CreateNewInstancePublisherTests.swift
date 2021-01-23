//
//  CreateNewInstancePublisherTests.swift
//  
//
//  Created by Hadi Zamani on 1/23/21.
//

import XCTest
import Combine
import CoreData
@testable import BaseLocalDataAccess

@available(iOS 13.0, *)
class CreateNewInstancePublisherTests: XCTestCase {
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

    func testCreateNewInstanceIsSuccessful() {
        genericDataAccess.createNewInstancePublisher().sink { completion in
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

    func testCreateNewInstanceThrowsFailNewEntity() {
        genericDataAccess.set {
            throw EntityCRUDError.failNewEntity("Mock")
        }

        genericDataAccess.createNewInstancePublisher().sink { completion in
            switch completion {
            case .finished:
                XCTFail()
            case .failure(let error):
                if case .failNewEntity(let s) = error {
                    XCTAssertEqual("Mock", s)
                } else {
                    XCTFail()
                }
            }
        } receiveValue: { result in
            XCTAssertNil(result)
        }.store(in:&self.storage)
    }

    func testSaveEntityThrowsGeneralError() {
        enum MockError: Error {
            case general(String)
        }

        genericDataAccess.set {
            throw MockError.general("General Error")
        }

        genericDataAccess.createNewInstancePublisher().sink { completion in
            switch completion {
            case .finished:
                XCTFail()
            case .failure(let error):
                if case .failNewEntity(let s) = error {
                    XCTAssertNotNil(s)
                } else {
                    XCTFail()
                }
            }
        } receiveValue: { result in
            XCTAssertNil(result)
        }.store(in:&self.storage)
    }

    class MockGenericDataAccess<TEntity>: GenericDataAccess<TEntity> where TEntity: EntityProtocol, TEntity: AnyObject, TEntity: NSFetchRequestResult {

        var expectedBehavior: () throws -> Void = {}

        func set(expectedBehavior: @escaping () throws -> Void) {
            self.expectedBehavior = expectedBehavior
        }

        override func createNewInstance() throws -> TEntity {

            try expectedBehavior()

            return MockEntity() as! TEntity
        }
    }
}

