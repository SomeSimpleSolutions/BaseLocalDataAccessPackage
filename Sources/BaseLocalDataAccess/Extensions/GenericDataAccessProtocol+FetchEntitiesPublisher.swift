//
//  GenericDataAccessProtocol+FetchEntitiesPublisher.swift
//  
//
//  Created by Hadi Zamani on 2/9/21.
//

import Combine

@available(iOS 13.0, *)
public extension GenericDataAccess {

    func fetchEntitiesPublisher(predicate: PredicateProtocol? = nil, sort: SortProtocol? = nil, fetchLimit: Int? = nil, fetchOffset: Int? = nil) -> FetchEntitiesPublisher {

        let params: Params = (predicate: predicate, sort: sort, fetchLimit: fetchLimit, fetchOffset: fetchOffset)

        return FetchEntitiesPublisher(self: self, params: params)
    }

    struct FetchEntitiesPublisher: Publisher {
        private let gda: GenericDataAccess<TEntity>
        private let params: Params

        public typealias Output = [TEntity]
        public typealias Failure = EntityCRUDError

        init(self gda: GenericDataAccess<TEntity>, params: Params) {
            self.gda = gda
            self.params = params
        }

        public func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {

            let subscription = Inner(downstream: subscriber, gda: gda, params: params)
            subscriber.receive(subscription: subscription)
        }

        class Inner<S>: Subscription where S: Subscriber, Failure == S.Failure, Output == S.Input  {

            private unowned let gda: GenericDataAccess<TEntity>
            private let params: Params
            var downstream: S?

            init(downstream: S, gda: GenericDataAccess<TEntity>, params: Params) {
                self.downstream = downstream
                self.gda = gda
                self.params = params
            }

            func request(_ demand: Subscribers.Demand) {
                defer {
                    downstream = nil
                }

                do {
                    let result = try gda.fetchEntities(predicate: params.predicate, sort: params.sort, fetchLimit: params.fetchLimit, fetchOffset: params.fetchOffset)
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

