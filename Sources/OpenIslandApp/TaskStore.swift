import Foundation
import Observation

// Task behavior is adapted from Ayushman Malla's macIsland (MIT).
// See THIRD_PARTY_NOTICES.md.
struct TaskItem: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    let createdAt: Date
    var completedAt: Date?
    var updatedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.updatedAt = updatedAt
    }
}

@MainActor
@Observable
final class TaskStore {
    private(set) var tasks: [TaskItem] = []

    var hasCompletedTasks: Bool {
        tasks.contains(where: \.isCompleted)
    }

    private let storageURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(storageURL: URL? = nil) {
        self.storageURL = storageURL ?? Self.defaultStorageURL()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        load()
    }

    func addTask(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        tasks.append(TaskItem(title: trimmed))
        sortAndSave()
    }

    func toggleCompletion(id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }

        let changedAt = Date()
        tasks[index].isCompleted.toggle()
        tasks[index].completedAt = tasks[index].isCompleted ? changedAt : nil
        tasks[index].updatedAt = changedAt
        sortAndSave()
    }

    func editTask(id: UUID, title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = tasks.firstIndex(where: { $0.id == id }) else {
            return
        }

        tasks[index].title = trimmed
        tasks[index].updatedAt = Date()
        sortAndSave()
    }

    func deleteTask(id: UUID) {
        tasks.removeAll { $0.id == id }
        save()
    }

    func clearCompletedTasks() {
        guard hasCompletedTasks else { return }
        tasks.removeAll(where: \.isCompleted)
        save()
    }

    func replaceTasksForDebug(_ tasks: [TaskItem]) {
        self.tasks = tasks
        sortInPlace()
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL) else {
            tasks = []
            return
        }

        tasks = (try? decoder.decode([TaskItem].self, from: data)) ?? []
        sortInPlace()
    }

    private func sortAndSave() {
        sortInPlace()
        save()
    }

    private func sortInPlace() {
        tasks.sort {
            if $0.isCompleted != $1.isCompleted { return !$0.isCompleted }
            if $0.isCompleted {
                return ($0.completedAt ?? .distantPast) < ($1.completedAt ?? .distantPast)
            }
            return $0.createdAt < $1.createdAt
        }
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(
                at: storageURL.deletingLastPathComponent(),
                withIntermediateDirectories: true,
                attributes: nil
            )
            let data = try encoder.encode(tasks)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            print("OpenIsland: Failed to save tasks: \(error)")
        }
    }

    private static func defaultStorageURL() -> URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return base
            .appendingPathComponent("OpenIsland", isDirectory: true)
            .appendingPathComponent("tasks.json")
    }
}
