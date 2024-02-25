//
//  ListClient.swift
//  TaskTest
//
//  Created by Markus Müller on 22.02.24.
//

import Algorithms
import Dependencies
import DependenciesMacros
import Foundation

struct Item: Equatable, Identifiable, Sendable {
    var id: Int
    var text: String = ""
}

@DependencyClient
struct ListClient {
    var fetchItems: @Sendable () async throws -> [Item]
    var loadFact: @Sendable (Item.ID) async throws -> String
}

extension ListClient: DependencyKey {
    static let facts: [String] = ["1+1=2", "42", "Grass is green", "Water is wet"]
    static var liveValue: Self = {
        let values = LockIsolated<[Item]>([])

        return .init(fetchItems: {
            guard values.isEmpty else {
                return values.value
            }
            let result = try await withThrowingTaskGroup(of: [Item].self) { group in
                for chunk in (1 ... 30000).evenlyChunked(in: 5) {
                    group.addTask {
                        chunk.map {
                            return Item(id: $0)
                        }
                    }
                }
                return try await group.reduce([Item]()) { acc, items in
                    try Task.checkCancellation()
                    return acc + items
                }
            }
            values.setValue(result)
            return result
        }, loadFact: { id in
            try await Task.sleep(for: .milliseconds(Int.random(in: 100 ... 300)))
            return facts.randomElement()!
        })
    }()
}

extension DependencyValues {
    var listClient: ListClient {
        get { self[ListClient.self] }
        set { self[ListClient.self] = newValue }
    }
}
