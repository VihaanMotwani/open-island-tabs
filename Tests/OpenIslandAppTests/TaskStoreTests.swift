import Foundation
import Testing
@testable import OpenIslandApp

@MainActor
struct TaskStoreTests {
    @Test
    func addingTaskTrimsWhitespaceAndIgnoresBlankTitles() {
        let store = TaskStore(storageURL: temporaryStorageURL())

        store.addTask(title: "  Write plan  ")
        store.addTask(title: "   \n")

        #expect(store.tasks.map(\.title) == ["Write plan"])
        #expect(store.tasks.first?.isCompleted == false)
    }

    @Test
    func completingTaskMovesItBelowActiveTasks() throws {
        let store = TaskStore(storageURL: temporaryStorageURL())
        store.addTask(title: "First")
        store.addTask(title: "Second")
        let firstID = try #require(store.tasks.first?.id)

        store.toggleCompletion(id: firstID)

        #expect(store.tasks.map(\.title) == ["Second", "First"])
        #expect(store.tasks.last?.isCompleted == true)
        #expect(store.tasks.last?.completedAt != nil)
    }

    @Test
    func editingTaskTrimsAndUpdatesItsTitle() throws {
        let store = TaskStore(storageURL: temporaryStorageURL())
        store.addTask(title: "Draft")
        let taskID = try #require(store.tasks.first?.id)

        store.editTask(id: taskID, title: "  Final  ")

        #expect(store.tasks.first?.title == "Final")
        #expect(store.tasks.first?.updatedAt != nil)
    }

    @Test
    func deletingTaskRemovesIt() throws {
        let store = TaskStore(storageURL: temporaryStorageURL())
        store.addTask(title: "Remove me")
        let taskID = try #require(store.tasks.first?.id)

        store.deleteTask(id: taskID)

        #expect(store.tasks.isEmpty)
    }

    @Test
    func mutationsPersistAndReloadInDisplayOrder() throws {
        let storageURL = temporaryStorageURL()
        let writer = TaskStore(storageURL: storageURL)
        writer.addTask(title: "Active")
        writer.addTask(title: "Done")
        let doneID = try #require(writer.tasks.last?.id)
        writer.toggleCompletion(id: doneID)

        let reader = TaskStore(storageURL: storageURL)

        #expect(reader.tasks.map(\.title) == ["Active", "Done"])
        #expect(reader.tasks.last?.isCompleted == true)
    }

    private func temporaryStorageURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("tasks.json")
    }
}
