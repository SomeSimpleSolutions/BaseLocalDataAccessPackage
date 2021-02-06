//
//  GenericDataAccess+FetchEntityCountPublisher.swift
//  
//
//  Created by Hadi Zamani on 2/6/21.
//

import Combine

@available(iOS 13.0, *)
public extension GenericDataAccess {
    func fetchEntityCountPublisher(predicate: PredicateProtocol? = nil) -> FetchEntityCountPublisher {

        return FetchEntityCountPublisher(self: self, predicate: predicate)
    }

    struct FetchEntityCountPublisher: Publisher {
        private let gda: GenericDataAccess<TEntity>
        private let predicate: PredicateProtocol?

        public typealias Output = Int
        public typealias Failure = EntityCRUDError

        init(self gda: GenericDataAccess<TEntity>, predicate: PredicateProtocol?) {
            self.gda = gda
            self.predicate = predicate
        }

        public func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {

            let subscription = Inner(downstream: subscriber, gda: gda, predicate: predicate)
            subscriber.receive(subscription: subscription)
        }

        class Inner<S>: Subscription where S: Subscriber, Failure == S.Failure, Output == S.Input  {

            private unowned let gda: GenericDataAccess<TEntity>
            private let predicate: PredicateProtocol?
            var downstream: S?

            init(downstream: S, gda: GenericDataAccess<TEntity>, predicate: PredicateProtocol?) {
                self.downstream = downstream
                self.gda = gda
                self.predicate = predicate
            }

            func request(_ demand: Subscribers.Demand) {
                defer {
                    downstream = nil
                }

                do {
                    let result = try gda.fetchEntityCount(predicate: predicate)
                    _ = downstream?.receive(result)
                    downstream?.receive(completion: .finished)

                } catch EntityCRUDError.failFetchEntityCount(let error) {
                    downstream?.receive(completion: .failure(EntityCRUDError.failFetchEntityCount(error)))
                } catch {
                    downstream?.receive(completion: .failure(EntityCRUDError.failFetchEntityCount(error.localizedDescription)))
                }
            }

            func cancel() {
                downstream = nil
            }
        }
    }
}
