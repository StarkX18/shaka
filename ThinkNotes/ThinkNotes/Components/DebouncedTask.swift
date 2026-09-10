import SwiftUI

struct DebouncedTask {
    private var task: Task<Void, Never>?

    mutating func schedule(after interval: Duration = .milliseconds(500), action: @escaping @Sendable () async -> Void) {
        task?.cancel()
        task = Task {
            try? await Task.sleep(for: interval)
            guard !Task.isCancelled else { return }
            await action()
        }
    }

    mutating func cancel() {
        task?.cancel()
        task = nil
    }
}
