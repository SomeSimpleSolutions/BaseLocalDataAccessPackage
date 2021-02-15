//
//  MockManagedObjectContext.swift
//  
//
//  Created by Hadi Zamani on 1/18/21.
//

import CoreData
import BaseLocalDataAccess

class MockManagedObjectContext: ManagedObjectContextProtocol {
    var managedObjectContext: NSManagedObjectContext
    
    init() {
        managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
    }
}

class MockEntity {
    var id: String = ""
    var title: String = ""

    public func toModel() throws -> ModelProtocol {
        return MockModel(id: id, title: title)
    }
}

extension MockEntity: EntityProtocol {
    public static var idField: String {
        return "id"
    }
    
    public static var entityName: String {
        return "MockEntity"
    }
    
    public enum Fields: String {
        case id
        case title
    }
}

public struct MockModel: ModelProtocol {
    var id: String
    var title: String
}

extension MockEntity: NSFetchRequestResult {
    func isEqual(_ object: Any?) -> Bool {
        return false
    }
    
    var hash: Int {
        0
    }
    
    var superclass: AnyClass? {
        nil
    }
    
    func `self`() -> Self {
        return self
    }
    
    func perform(_ aSelector: Selector!) -> Unmanaged<AnyObject>! {
        return nil
    }
    
    func perform(_ aSelector: Selector!, with object: Any!) -> Unmanaged<AnyObject>! {
        return nil
    }
    
    func perform(_ aSelector: Selector!, with object1: Any!, with object2: Any!) -> Unmanaged<AnyObject>! {
        return nil
    }
    
    func isProxy() -> Bool {
        return false
    }
    
    func isKind(of aClass: AnyClass) -> Bool {
        return false
    }
    
    func isMember(of aClass: AnyClass) -> Bool {
        return false
    }
    
    func conforms(to aProtocol: Protocol) -> Bool {
        return false
    }
    
    func responds(to aSelector: Selector!) -> Bool {
        return false
    }
    
    var description: String {
        return ""
    }
}

class FailedToModelMockEntity: MockEntity {
    override public func toModel() throws -> ModelProtocol {
        throw ModelError.failCreateModel("MockModel")
    }

}
