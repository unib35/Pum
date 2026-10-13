// UI-IOS-1ap · REQ-060 — 서버 PDF를 PDFKit으로 보여 준다. 현재 쪽이 바뀌면 알린다.
import SwiftUI
import PDFKit

struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument
    /// 현재 쪽(0부터)
    var onPageChange: (Int) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onPageChange: onPageChange) }

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.document = document
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = UIColor(PumTokens.ColorToken.gray200)
        context.coordinator.observe(view)
        return view
    }

    static func dismantleUIView(_ view: PDFView, coordinator: Coordinator) {
        NotificationCenter.default.removeObserver(coordinator, name: .PDFViewPageChanged, object: view)
    }

    func updateUIView(_ view: PDFView, context: Context) {
        context.coordinator.onPageChange = onPageChange
        if view.document !== document { view.document = document }
    }

    final class Coordinator: NSObject {
        var onPageChange: (Int) -> Void
        init(onPageChange: @escaping (Int) -> Void) { self.onPageChange = onPageChange }

        func observe(_ view: PDFView) {
            NotificationCenter.default.addObserver(
                self, selector: #selector(pageChanged(_:)), name: .PDFViewPageChanged, object: view)
        }

        @MainActor @objc private func pageChanged(_ note: Notification) {
            guard let view = note.object as? PDFView, let doc = view.document, let page = view.currentPage else { return }
            onPageChange(doc.index(for: page))
        }

        deinit { NotificationCenter.default.removeObserver(self) }
    }
}
