import Foundation

@MainActor
final class HistoryManager {
    private(set) var undoStack: [DrawingAction] = []
    private(set) var redoStack: [DrawingAction] = []

    private let actionLimit: Int
    private let memoryBudget: Int

    init(actionLimit: Int = 25, memoryBudget: Int = 48 * 1024 * 1024) {
        self.actionLimit = actionLimit
        self.memoryBudget = memoryBudget
    }

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func record(_ action: DrawingAction) {
        guard !action.patches.isEmpty else { return }
        undoStack.append(action)
        redoStack.removeAll(keepingCapacity: true)
        trimUndoHistory()
    }

    func takeUndo() -> DrawingAction? {
        guard let action = undoStack.popLast() else { return nil }
        redoStack.append(action)
        return action
    }

    func takeRedo() -> DrawingAction? {
        guard let action = redoStack.popLast() else { return nil }
        undoStack.append(action)
        return action
    }

    func clear() {
        undoStack.removeAll(keepingCapacity: true)
        redoStack.removeAll(keepingCapacity: true)
    }

    private func trimUndoHistory() {
        while undoStack.count > actionLimit {
            undoStack.removeFirst()
        }
        var storedBytes = undoStack.reduce(0) { $0 + $1.storedByteCount }
        while undoStack.count > 1, storedBytes > memoryBudget {
            storedBytes -= undoStack.removeFirst().storedByteCount
        }
    }
}
