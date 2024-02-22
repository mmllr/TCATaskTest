//
//  ListFeature.swift
//  TaskTest
//
//  Created by Markus Müller on 22.02.24.
//

import Foundation
import ComposableArchitecture

@Reducer
struct ListFeature {
    @Reducer(state: .equatable)
    enum Path {
        case row(RowFeature)
    }

    @ObservableState
    struct State: Equatable {
        var path: StackState<Path.State> = .init()
        var rows: IdentifiedArrayOf<RowFeature.State> = []
    }

    enum Action {
        case task
        case fetchResult(TaskResult<[Item]>)
        case rows(IdentifiedActionOf<RowFeature>)
        case path(StackAction<Path.State, Path.Action>)
    }

    @Dependency(\.listClient.fetchItems) var fetchItems

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .run { send in
                    await send(.fetchResult(TaskResult {
                        try await fetchItems()
                    }))
                }
            case let .fetchResult(.success(items)):
                state.rows = .init(uniqueElements: items.map { RowFeature.State(item: $0, isLoading: false)})
                return .none

            case let .rows(.element(id: id, action: .moreButtonTapped)):
                guard let rowState = state.rows[id: id] else { return .none }
                state.path.append(.row(rowState))
                return .none

            case .fetchResult:
                return .none
            case .rows:
                return .none
            case .path:
                return .none
            }
        }
        .forEach(\.rows, action: \.rows) {
            RowFeature()
        }
        .forEach(\.path, action: \.path)
    }
}

import SwiftUI

struct ListFeatureView: View {
    @Bindable var store: StoreOf<ListFeature>
    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            ScrollView {
                LazyVStack {
                    ForEach(Array(store.scope(state: \.rows, action: \.rows))) { rowStore in
                        RowView(store: rowStore)
                    }
                }
            }
        } destination: { store in
            switch store.case {
            case .row(let rowStore):
                RowDetailView(store: rowStore)
            }
        }
        .task {
            await store.send(.task).finish()
        }
    }
}

