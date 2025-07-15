//
// FileSystemMonitor.swift
// GitCthulhu
//
// Created by GitCthulhu Team on 2025-07-15.
//

import Combine
import CoreFoundation
import Foundation
import Utilities

/// File system event for repository monitoring
public struct FileSystemEvent {
    public let path: String
    public let eventFlags: FSEventStreamEventFlags
    public let timestamp: Date

    public init(path: String, eventFlags: FSEventStreamEventFlags, timestamp: Date = Date()) {
        self.path = path
        self.eventFlags = eventFlags
        self.timestamp = timestamp
    }
}

/// File system monitor using macOS FSEvents API
@MainActor
public class FileSystemMonitor: ObservableObject {
    private var eventStream: FSEventStreamRef?
    private let repositoryPath: URL
    private let logger = Logger(category: "FileSystemMonitor")

    // Event filtering and debouncing
    private var eventDebounceTimer: Timer?
    private var pendingEvents: [FileSystemEvent] = []
    private let debounceInterval: TimeInterval = 0.5

    // Publishers for event notification
    private let eventSubject = PassthroughSubject<[FileSystemEvent], Never>()
    public var eventPublisher: AnyPublisher<[FileSystemEvent], Never> {
        eventSubject.eraseToAnyPublisher()
    }

    // Monitoring state
    @Published public private(set) var isMonitoring = false

    // Git-related file patterns to filter
    private let gitInternalPaths: Set<String> = [
        ".git/objects",
        ".git/refs/remotes",
        ".git/logs",
        ".git/index.lock"
    ]

    private let ignoredExtensions: Set<String> = [
        ".tmp", ".temp", ".lock", ".swp", ".swo", "~"
    ]

    public init(repositoryPath: URL) {
        self.repositoryPath = repositoryPath
    }

    deinit {
        // Ensure monitoring is stopped before deallocation
        // This prevents callbacks to a deallocated object
        if let eventStream {
            FSEventStreamStop(eventStream)
            FSEventStreamInvalidate(eventStream)
            FSEventStreamRelease(eventStream)
        }

        // Synchronously invalidate timer to prevent any potential issues
        // Safe because timer uses [weak self] closure
        if let timer = eventDebounceTimer {
            timer.invalidate()
        }
    }

    // MARK: - Public API

    /// Start monitoring file system events for the repository
    public func startMonitoring() {
        guard !isMonitoring else {
            logger.info("File system monitoring already started for \(repositoryPath.path)")
            return
        }

        guard validateRepositoryPath() else { return }

        guard let eventStream = createEventStream() else { return }

        configureAndStartEventStream(eventStream)
    }

    /// Stop monitoring file system events
    public func stopMonitoring() {
        guard isMonitoring, let eventStream else { return }

        FSEventStreamStop(eventStream)
        FSEventStreamInvalidate(eventStream)
        FSEventStreamRelease(eventStream)

        self.eventStream = nil
        isMonitoring = false

        // Cancel pending debounce timer
        eventDebounceTimer?.invalidate()
        eventDebounceTimer = nil
        pendingEvents.removeAll()

        logger.info("Stopped file system monitoring for \(repositoryPath.path)")
    }

    // MARK: - Private Helper Methods

    private func validateRepositoryPath() -> Bool {
        // Validate repository path exists and is accessible
        guard FileManager.default.fileExists(atPath: repositoryPath.path) else {
            logger.error("Repository path does not exist: \(repositoryPath.path)")
            return false
        }

        // Check if path is readable
        guard FileManager.default.isReadableFile(atPath: repositoryPath.path) else {
            logger.error("Repository path is not readable: \(repositoryPath.path)")
            return false
        }

        return true
    }

    private func createEventStream() -> FSEventStreamRef? {
        let pathsToWatch = [repositoryPath.path as NSString]
        let pathsArray = NSArray(array: pathsToWatch)

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let latency: CFTimeInterval = 0.3
        let flags: FSEventStreamCreateFlags = UInt32(
            kFSEventStreamCreateFlagUseCFTypes |
                kFSEventStreamCreateFlagFileEvents |
                kFSEventStreamCreateFlagIgnoreSelf
        )

        let stream = FSEventStreamCreate(
            nil,
            { _, clientCallBackInfo, numEvents, eventPaths, eventFlags, _ in
                guard let clientCallBackInfo else { return }
                let monitor = Unmanaged<FileSystemMonitor>.fromOpaque(clientCallBackInfo).takeUnretainedValue()
                monitor.handleFSEvents(
                    numEvents: numEvents,
                    eventPaths: eventPaths,
                    eventFlags: eventFlags
                )
            },
            &context,
            pathsArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            latency,
            flags
        )

        guard let stream else {
            logger.error("Failed to create FSEventStream for \(repositoryPath.path)")
            return nil
        }

        return stream
    }

    private func configureAndStartEventStream(_ stream: FSEventStreamRef) {
        FSEventStreamSetDispatchQueue(stream, DispatchQueue.global(qos: .background))

        if FSEventStreamStart(stream) {
            eventStream = stream
            isMonitoring = true
            logger.info("Started file system monitoring for \(repositoryPath.path)")
        } else {
            logger.error("Failed to start FSEventStream for \(repositoryPath.path)")
            FSEventStreamRelease(stream)
        }
    }

    // MARK: - Event Handling

    private func handleFSEvents(
        numEvents: Int,
        eventPaths: UnsafeRawPointer,
        eventFlags: UnsafePointer<FSEventStreamEventFlags>
    ) {
        // Validate input parameters
        guard numEvents > 0 else {
            logger.warning("Received FSEvent callback with 0 events")
            return
        }

        guard let pathsArray = Unmanaged<CFArray>.fromOpaque(eventPaths).takeUnretainedValue() as? [String] else {
            logger.error("Failed to cast FSEvent paths to [String]")
            return
        }

        // Ensure we have the expected number of paths
        guard pathsArray.count == numEvents else {
            logger.error("FSEvent path count mismatch: expected \(numEvents), got \(pathsArray.count)")
            return
        }

        var filteredEvents: [FileSystemEvent] = []

        for eventIndex in 0 ..< numEvents
            where !shouldIgnoreEvent(path: pathsArray[eventIndex], flags: eventFlags[eventIndex]) {
            let path = pathsArray[eventIndex]
            let flags = eventFlags[eventIndex]

            let event = FileSystemEvent(path: path, eventFlags: flags)
            filteredEvents.append(event)
        }

        if !filteredEvents.isEmpty {
            Task { @MainActor in
                addPendingEvents(filteredEvents)
            }
        }
    }

    private func shouldIgnoreEvent(path: String, flags: FSEventStreamEventFlags) -> Bool {
        let relativePath = path.replacingOccurrences(of: repositoryPath.path + "/", with: "")

        // Ignore Git internal paths that don't affect working directory status
        for gitPath in gitInternalPaths where relativePath.hasPrefix(gitPath) {
            return true
        }

        // Ignore files with certain extensions
        let pathExtension = URL(fileURLWithPath: path).pathExtension.lowercased()
        if ignoredExtensions.contains("." + pathExtension) {
            return true
        }

        // Ignore temporary files
        let fileName = URL(fileURLWithPath: path).lastPathComponent
        if fileName.hasPrefix(".") && fileName.hasSuffix(".tmp") {
            return true
        }

        // Process file-related events (creation, modification, deletion)
        let isFileEvent = (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsFile)) != 0
        let isDirectoryEvent = (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsDir)) != 0
        let isCreated = (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemCreated)) != 0
        let isModified = (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemModified)) != 0
        let isRemoved = (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemRemoved)) != 0
        let isRenamed = (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemRenamed)) != 0

        // Include any file or directory modification events
        let isRelevantEvent = isFileEvent || isDirectoryEvent || isCreated || isModified || isRemoved || isRenamed

        return !isRelevantEvent
    }

    private func addPendingEvents(_ events: [FileSystemEvent]) {
        pendingEvents.append(contentsOf: events)

        // Cancel existing timer and start a new one
        eventDebounceTimer?.invalidate()
        eventDebounceTimer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.processPendingEvents()
            }
        }
    }

    private func processPendingEvents() {
        guard !pendingEvents.isEmpty else { return }

        let eventsToProcess = pendingEvents
        pendingEvents.removeAll()

        // Group events by path to avoid duplicates
        var uniqueEvents: [String: FileSystemEvent] = [:]
        for event in eventsToProcess {
            uniqueEvents[event.path] = event
        }

        let finalEvents = Array(uniqueEvents.values).sorted { $0.timestamp < $1.timestamp }

        logger.info("Processing \(finalEvents.count) file system events")
        eventSubject.send(finalEvents)
    }
}

// MARK: - FSEventStreamEventFlags Extension

extension FSEventStreamEventFlags {
    var description: String {
        var flags: [String] = []

        if self & FSEventStreamEventFlags(kFSEventStreamEventFlagItemCreated) != 0 {
            flags.append("Created")
        }
        if self & FSEventStreamEventFlags(kFSEventStreamEventFlagItemRemoved) != 0 {
            flags.append("Removed")
        }
        if self & FSEventStreamEventFlags(kFSEventStreamEventFlagItemModified) != 0 {
            flags.append("Modified")
        }
        if self & FSEventStreamEventFlags(kFSEventStreamEventFlagItemRenamed) != 0 {
            flags.append("Renamed")
        }
        if self & FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsFile) != 0 {
            flags.append("File")
        }
        if self & FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsDir) != 0 {
            flags.append("Directory")
        }

        return flags.isEmpty ? "Unknown" : flags.joined(separator: ", ")
    }
}
