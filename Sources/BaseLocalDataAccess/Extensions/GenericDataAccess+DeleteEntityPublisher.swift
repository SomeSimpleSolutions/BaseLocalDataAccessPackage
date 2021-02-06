//
//  GenericDataAccess+DeleteEntityPublisher.swift
//  
//
//  Created by Hadi Zamani on 2/6/21.
//

import Combine

@available(iOS 13.0, *)
public extension GenericDataAccess {
    func deleteEntityPublisher(entity: TEntity) -> DeleteEntityPublisher {
        return DeleteEntityPublisher(self: self, entity: entity)
    }

    struct DeleteEntityPublisher: Publisher {
        private let gda: GenericDataAccess<TEntity>
        private let entity: TEntity

        public typealias Output = Bool
        public typealias Failure = EntityCRUDError

        init(self gda: GenericDataAccess<TEntity>, entity: TEntity) {
            self.gda = gda
            self.entity = entity
        }

        public func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {

            let subscription = Inner(downstream: subscriber, gda: gda, entity: entity)
            subscriber.receive(subscription: subscription)
        }

        class Inner<S>: Subscription where S: Subscriber, Failure == S.Failure, Output == S.Input  {

            private unowned let gda: GenericDataAccess<TEntity>
            private let entity: TEntity
            var downstream: S?

            init(downstream: S, gda: GenericDataAccess<TEntity>, entity: TEntity) {
                self.downstream = downstream
                self.gda = gda
                self.entity = entity
            }

            func request(_ demand: Subscribers.Demand) {
                defer {
                    downstream = nil
                }

                do {
                    try gda.deleteEntity(entity)
                    _ = downstream?.receive(true)
                    downstream?.receive(completion: .finished)

                } catch EntityCRUDError.failDeleteEntity(let error) {
                    downstream?.receive(completion: .failure(EntityCRUDError.failDeleteEntity(error)))
                } catch {
                    downstream?.receive(completion: .failure(EntityCRUDError.failDeleteEntity(error.localizedDescription)))
                }
            }

            func cancel() {
                downstream = nil
            }
        }
    }
}
