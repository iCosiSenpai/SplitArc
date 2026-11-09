import AppKit

final class TelemetryStore: ObservableObject {
    struct Entry: Identifiable {
        let id: UInt64
        let time: Date
        let message: String
    }

    static let shared = TelemetryStore()

    @Published private(set) var entries: [Entry] = []

    private let bufferLock = NSLock()
    private var pending: [Entry] = []
    private var flushScheduled = false
    private var sequence: UInt64 = 0
    private let limit = 400

    private init() {}

    func append(_ line: String) {
        guard !line.isEmpty else { return }
        bufferLock.lock()
        sequence &+= 1
        pending.append(Entry(id: sequence, time: Date(), message: String(line.prefix(512))))
        if pending.count > limit * 2 { pending.removeFirst(pending.count - limit) }
        let shouldSchedule = !flushScheduled
        flushScheduled = true
        bufferLock.unlock()

        if shouldSchedule {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.flush()
            }
        }
    }

    func clear() {
        bufferLock.lock()
        pending.removeAll(keepingCapacity: true)
        bufferLock.unlock()
        entries = []
    }

    func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(entries.map(\.message).joined(separator: "\n"), forType: .string)
    }

    private func flush() {
        bufferLock.lock()
        let batch = pending
        pending.removeAll(keepingCapacity: true)
        flushScheduled = false
        bufferLock.unlock()
        if !batch.isEmpty { entries = Array((entries + batch).suffix(limit)) }
    }
}
