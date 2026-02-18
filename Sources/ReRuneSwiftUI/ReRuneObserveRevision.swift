import SwiftUI
import ReRuneCore

public extension View {
    func reRuneObserveRevision() -> some View {
        modifier(observeRevisionModifier())
    }
}

private struct observeRevisionModifier: ViewModifier {
    @StateObject private var observer = revisionObserver()

    func body(content: Content) -> some View {
        content
            .id(observer.revision)
    }
}
