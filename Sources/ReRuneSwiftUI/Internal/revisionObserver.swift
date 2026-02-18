import Combine
import Foundation
import ReRuneCore

final class revisionObserver: ObservableObject {
    @Published var revision: Int = ReRune.revision
    private var cancellable: AnyCancellable?

    init() {
        cancellable = ReRune.revisionPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                self?.revision = value
            }
    }
}
