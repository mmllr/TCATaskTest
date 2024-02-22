//
//  RowFeature.swift
//  TaskTest
//
//  Created by Markus Müller on 22.02.24.
//

import Foundation
import ComposableArchitecture

@Reducer
struct RowFeature {
    @ObservableState
    struct State: Equatable, Identifiable {
        var item: Item
        var isLoading: Bool
        var id: Item.ID { item.id }
        var counter: Int = 0
    }

    enum Action {
        case task
        case fetchResult(String)
        case moreButtonTapped
        case timerTick
    }

    @Dependency(\.listClient.loadFact) var loadFact
    @Dependency(\.continuousClock) var clock

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                return .run { [id = state.id] send in
                    await withThrowingTaskGroup(of: Void.self) { group in
                        group.addTask {
                            await send(.fetchResult(try await loadFact(id)))
                        }
                        group.addTask {
                            for await _ in clock.timer(interval: .milliseconds(333)) {
                                try Task.checkCancellation()
                                await send(.timerTick)
                            }
                        }
                    }
                }

            case .fetchResult(let fact):
                state.isLoading = false
                state.item.text = fact
                return .none

            case .moreButtonTapped:
                return .none

            case .timerTick:
                state.counter += 1
                return .none
            }
        }
    }
}

import SwiftUI

struct RowView: View {
    let store: StoreOf<RowFeature>

    var body: some View {
        HStack {
            Text("\(store.item.id) - \(store.item.text)")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .task {
                    await store.send(.task).finish()
                }
            if store.isLoading {
                ProgressView()
            }

            Spacer()

            Button(">") {
                store.send(.moreButtonTapped)
            }
        }.padding()
    }
}

struct RowDetailView: View {
    let store: StoreOf<RowFeature>

    var body: some View {
        Form {
            Text(store.item.text)

            LabeledContent("Counter", value: "\(store.counter)")
        }
        .task {
            await store.send(.task).finish()
        }
    }
}
