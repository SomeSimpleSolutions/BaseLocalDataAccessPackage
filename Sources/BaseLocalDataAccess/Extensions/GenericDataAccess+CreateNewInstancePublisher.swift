//
//  GenericDataAccess+CreateNewInstancePublisher.swift
//  
//
//  Created by Hadi Zamani on 1/23/21.
//

import Combine

@available(iOS 13.0, *)
public extension GenericDataAccess {
    func createNewInstancePublisher() -> CreateNewInstancePublisher {
        return CreateNewInstancePublisher(self: self)
    }

    struct CreateNewInstancePublisher: Publisher {
        private let gda: GenericDataAccess<TEntity>

        public typealias Output = TEntity
        public typealias Failure = EntityCRUDError

        init(self gda: GenericDataAccess<TEntity>) {
            self.gda = gda
        }

        public func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {

            let subscription = Inner(downstream: subscriber, gda: gda)
            subscriber.receive(subscription: subscription)
        }

        class Inner<S>: Subscription where S: Subscriber, Failure == S.Failure, Output == S.Input  {

            private unowned let gda: GenericDataAccess<TEntity>
            var downstream: S?

            init(downstream: S, gda: GenericDataAccess<TEntity>) {
                self.downstream = downstream
                self.gda = gda
            }

            func request(_ demand: Subscribers.Demand) {
                defer {
                    downstream = nil
                }

                do {
                    let entity = try gda.createNewInstance()
                    _ = downstream?.receive(entity)
                    downstream?.receive(completion: .finished)

                } catch EntityCRUDError.failNewEntity(let error) {
                    downstream?.receive(completion: .failure(EntityCRUDError.failNewEntity(error)))
                } catch {
                    downstream?.receive(completion: .failure(EntityCRUDError.failNewEntity(error.localizedDescription)))
                }
            }

            func cancel() {
                downstream = nil
            }
        }
    }
}
