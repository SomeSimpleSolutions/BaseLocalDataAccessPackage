//
//  GenericDataAccess+FetchEntityWithIdPublisher.swift
//  
//
//  Created by Hadi Zamani on 2/13/21.
//

import Combine
import Foundation

@available(iOS 13.0, *)
public extension GenericDataAccess {

    func fetchEntityPublisher(withId id: UUID) -> FetchEntityWithIdPublisher {

        return FetchEntityWithIdPublisher(self: self, id: id)
    }

    struct FetchEntityWithIdPublisher: Publisher {
        private let gda: GenericDataAccess<TEntity>
        private let id: UUID

        public typealias Output = TEntity?
        public typealias Failure = EntityCRUDError

        init(self gda: GenericDataAccess<TEntity>, id: UUID) {
            self.gda = gda
            self.id = id
        }

        public func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {

            let subscription = Inner(downstream: subscriber, gda: gda, id: id)
            subscriber.receive(subscription: subscription)
        }

        class Inner<S>: Subscription where S: Subscriber, Failure == S.Failure, Output == S.Input  {

            private unowned let gda: GenericDataAccess<TEntity>
            private let id: UUID
            var downstream: S?

            init(downstream: S, gda: GenericDataAccess<TEntity>,  id: UUID) {
                self.downstream = downstream
                self.gda = gda
                self.id = id
            }

            func request(_ demand: Subscribers.Demand) {
                defer {
                    downstream = nil
                }

                do {
                    let result = try gda.fetchEntity(withId: id)
                    _ = downstream?.receive(result)
                    downstream?.receive(completion: .finished)

                } catch EntityCRUDError.failFetchEntity(let error) {
                    downstream?.receive(completion: .failure(EntityCRUDError.failFetchEntity(error)))
                } catch {
                    downstream?.receive(completion: .failure(EntityCRUDError.failFetchEntity(error.localizedDescription)))
                }
            }

            func cancel() {
                downstream = nil
            }
        }
    }
}
