import SwiftUI
import UIKit

/// A two-page book spread backed by UIKit's native, center-spine page curl.
struct PageCurlPager<Page: View>: UIViewControllerRepresentable {
    /// Number of spreads. Each spread contains two pages.
    let count: Int
    /// The zero-based spread currently open in the book.
    @Binding var index: Int
    @Binding var isTurning: Bool
    /// Builds one physical page, not a complete spread.
    @ViewBuilder let page: (Int) -> Page

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let controller = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: [.spineLocation: NSNumber(value: UIPageViewController.SpineLocation.mid.rawValue)]
        )
        controller.isDoubleSided = true
        controller.view.backgroundColor = .clear
        controller.view.clipsToBounds = true
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        let firstPageIndex = safeIndex * 2
        controller.setViewControllers(
            [context.coordinator.host(for: firstPageIndex), context.coordinator.host(for: firstPageIndex + 1)],
            direction: .forward,
            animated: false
        )
        return controller
    }

    func updateUIViewController(_ controller: UIPageViewController, context: Context) {
        let coordinator = context.coordinator
        coordinator.parent = self
        guard !coordinator.isTransitioning,
              let shown = controller.viewControllers?.first as? PageHost else { return }

        let targetFirstPage = safeIndex * 2
        if shown.pageIndex == targetFirstPage {
            coordinator.refreshVisiblePages(in: controller)
        } else {
            coordinator.scheduleTurn(to: safeIndex, in: controller)
        }
    }

    private var safeIndex: Int { min(max(index, 0), max(count - 1, 0)) }
    private var physicalPageCount: Int { max(count, 1) * 2 }

    final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: PageCurlPager
        var isTransitioning = false
        private var isInteractiveTurn = false
        private var hasScheduledTurn = false

        init(parent: PageCurlPager) { self.parent = parent }

        func scheduleTurn(to spreadIndex: Int, in controller: UIPageViewController) {
            guard !isTransitioning, !hasScheduledTurn else { return }
            hasScheduledTurn = true
            DispatchQueue.main.async { [weak self, weak controller] in
                guard let self, let controller else { return }
                self.hasScheduledTurn = false
                self.turn(to: spreadIndex, in: controller, animated: true)
            }
        }

        func host(for pageIndex: Int) -> PageHost {
            let host = PageHost(rootView: AnyView(parent.page(pageIndex)))
            host.pageIndex = pageIndex
            host.view.backgroundColor = .clear
            return host
        }

        func turn(to spreadIndex: Int, in controller: UIPageViewController, animated: Bool) {
            guard !isTransitioning else { return }
            guard let shown = controller.viewControllers?.first as? PageHost else { return }
            let targetFirstPage = spreadIndex * 2
            guard shown.pageIndex != targetFirstPage else { return }

            isTransitioning = true
            parent.isTurning = true
            controller.setViewControllers(
                [host(for: targetFirstPage), host(for: targetFirstPage + 1)],
                direction: spreadIndex > shown.pageIndex / 2 ? .forward : .reverse,
                animated: animated
            ) { [weak self, weak controller] completed in
                guard let self, let controller else { return }
                self.finishTransition(completed: completed, in: controller)
            }
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            guard let pageIndex = (viewController as? PageHost)?.pageIndex, pageIndex > 0 else { return nil }
            return host(for: pageIndex - 1)
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            guard let pageIndex = (viewController as? PageHost)?.pageIndex,
                  pageIndex + 1 < parent.physicalPageCount else { return nil }
            return host(for: pageIndex + 1)
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            willTransitionTo pendingViewControllers: [UIViewController]
        ) {
            isTransitioning = true
            isInteractiveTurn = true
            parent.isTurning = true
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            guard isInteractiveTurn else { return }
            isInteractiveTurn = false
            isTransitioning = false
            if completed, let host = pageViewController.viewControllers?.first as? PageHost {
                parent.index = host.pageIndex / 2
            }
            parent.isTurning = false
            refreshVisiblePages(in: pageViewController)
        }

        private func finishTransition(completed: Bool, in controller: UIPageViewController) {
            isTransitioning = false
            if completed, let host = controller.viewControllers?.first as? PageHost {
                parent.index = host.pageIndex / 2
            }
            parent.isTurning = false
            refreshVisiblePages(in: controller)
        }

        func refreshVisiblePages(in controller: UIPageViewController) {
            for host in controller.viewControllers?.compactMap({ $0 as? PageHost }) ?? [] {
                host.rootView = AnyView(parent.page(host.pageIndex))
            }
        }
    }

    final class PageHost: UIHostingController<AnyView> {
        var pageIndex = 0
    }
}
