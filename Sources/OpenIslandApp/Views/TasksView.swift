import SwiftUI

struct TasksView: View {
    let store: TaskStore
    let lang: LanguageManager
    let onContentHeightChange: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var draft = ""
    @State private var editingTaskID: UUID?
    @State private var editingDraft = ""
    @State private var showingClearCompletedConfirmation = false
    @FocusState private var focusedField: Field?

    fileprivate enum Field: Hashable {
        case newTask
        case editing(UUID)
    }

    var body: some View {
        VStack(spacing: 12) {
            addTaskField

            if !store.tasks.isEmpty {
                ScrollView(.vertical) {
                    LazyVStack(spacing: ExpandedNotchLayoutMetrics.taskRowSpacing) {
                        ForEach(store.tasks) { task in
                            taskRow(task)
                        }
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollIndicators(.hidden)
            }

            if store.hasCompletedTasks {
                Button {
                    showingClearCompletedConfirmation = true
                } label: {
                    Label(lang.t("tasks.clearCompleted"), systemImage: "trash")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.48))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, ExpandedNotchLayoutMetrics.safeContentHorizontalInset)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .alert(
            lang.t("tasks.clearCompleted.confirmTitle"),
            isPresented: $showingClearCompletedConfirmation
        ) {
            Button(lang.t("tasks.clearCompleted.confirmAction"), role: .destructive) {
                clearCompletedTasks()
            }
            Button(lang.t("tasks.cancel"), role: .cancel) {}
        } message: {
            Text(lang.t("tasks.clearCompleted.confirmMessage"))
        }
    }

    private var addTaskField: some View {
        HStack(spacing: 8) {
            Image(systemName: "checklist")
                .foregroundStyle(.white.opacity(0.65))
                .accessibilityHidden(true)

            TextField(lang.t("tasks.add"), text: $draft)
                .textFieldStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.88))
                .focused($focusedField, equals: .newTask)
                .onSubmit(addTask)
        }
        .padding(.horizontal, 12)
        .frame(height: ExpandedNotchLayoutMetrics.tasksInputRowHeight)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(0.08))
        )
    }

    private func taskRow(_ task: TaskItem) -> some View {
        TaskRow(
            task: task,
            lang: lang,
            isEditing: editingTaskID == task.id,
            editingDraft: $editingDraft,
            editingFocus: $focusedField,
            onToggle: {
                withAnimation(reduceMotion ? nil : .snappy(duration: 0.26, extraBounce: 0.04)) {
                    store.toggleCompletion(id: task.id)
                }
                refreshHeight()
            },
            onBeginEditing: { beginEditing(task) },
            onCommitEditing: { commitEditing(task) },
            onCancelEditing: cancelEditing,
            onDelete: {
                withAnimation(reduceMotion ? nil : .snappy(duration: 0.24)) {
                    store.deleteTask(id: task.id)
                }
                refreshHeight()
            }
        )
    }

    private func addTask() {
        let title = draft
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.28, extraBounce: 0.06)) {
            store.addTask(title: title)
        }
        draft = ""
        refreshHeight()
    }

    private func clearCompletedTasks() {
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.24)) {
            store.clearCompletedTasks()
        }
        refreshHeight()
    }

    private func beginEditing(_ task: TaskItem) {
        editingTaskID = task.id
        editingDraft = task.title
        focusedField = .editing(task.id)
    }

    private func commitEditing(_ task: TaskItem) {
        let title = editingDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !title.isEmpty {
            store.editTask(id: task.id, title: title)
        }
        cancelEditing()
    }

    private func cancelEditing() {
        editingTaskID = nil
        editingDraft = ""
        focusedField = nil
    }

    private func refreshHeight() {
        DispatchQueue.main.async {
            onContentHeightChange()
        }
    }
}

private struct TaskRow: View {
    let task: TaskItem
    let lang: LanguageManager
    let isEditing: Bool
    @Binding var editingDraft: String
    var editingFocus: FocusState<TasksView.Field?>.Binding
    let onToggle: () -> Void
    let onBeginEditing: () -> Void
    let onCommitEditing: () -> Void
    let onCancelEditing: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(
                        task.isCompleted
                            ? .white.opacity(0.7)
                            : .white.opacity(0.5)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                lang.t(task.isCompleted ? "tasks.markIncomplete" : "tasks.markComplete")
            )

            if isEditing {
                TextField(lang.t("tasks.task"), text: $editingDraft)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .focused(editingFocus, equals: .editing(task.id))
                    .onSubmit(onCommitEditing)
                    .onExitCommand(perform: onCancelEditing)

                Button(action: onCommitEditing) {
                    Image(systemName: "checkmark.circle.fill")
                }
                .accessibilityLabel(lang.t("tasks.save"))

                Button(action: onCancelEditing) {
                    Image(systemName: "xmark.circle.fill")
                }
                .accessibilityLabel(lang.t("tasks.cancelEditing"))
            } else {
                Text(task.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(task.isCompleted ? 0.5 : 0.92))
                    .strikethrough(task.isCompleted, color: .white.opacity(0.6))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .font(.system(size: 10, weight: .medium))
        .foregroundStyle(.white.opacity(0.42))
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .frame(height: ExpandedNotchLayoutMetrics.taskRowHeight)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(task.isCompleted ? 0.05 : 0.08))
        )
        .contentShape(Rectangle())
        .contextMenu {
            Button(
                lang.t(task.isCompleted ? "tasks.markIncomplete" : "tasks.complete"),
                action: onToggle
            )
            Button(lang.t("tasks.edit"), action: onBeginEditing)
            Button(lang.t("tasks.delete"), role: .destructive, action: onDelete)
        }
        .accessibilityElement(children: .contain)
    }
}
