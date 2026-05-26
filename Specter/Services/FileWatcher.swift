import Foundation
import Combine

final class FileWatcher {
    private var source: DispatchSourceFileSystemObject?
    private let fileDescriptor: CInt
    private let queue = DispatchQueue(label: "com.specter.filewatcher")
    private var debounceWork: DispatchWorkItem?

    let changeSubject = PassthroughSubject<Void, Never>()

    init?(url: URL) {
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else { return nil }
        self.fileDescriptor = fd

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename, .extend],
            queue: queue
        )
        self.source = src
        src.setEventHandler { [weak self] in self?.debounceFire() }
        src.setCancelHandler { [fd] in close(fd) }
        src.resume()
    }

    private func debounceFire() {
        debounceWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.changeSubject.send(())
        }
        debounceWork = work
        queue.asyncAfter(deadline: .now() + .milliseconds(250), execute: work)
    }

    deinit {
        source?.cancel()
    }
}
