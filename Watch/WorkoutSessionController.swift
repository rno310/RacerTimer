import Foundation
import HealthKit

@MainActor
final class WorkoutSessionController: NSObject, ObservableObject {
    private let healthStore = HKHealthStore()
    private let fallback = RuntimeSessionController()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var authRequested = false
    private var pendingFallbackAutoStop: Date?

    func start(fallbackAutoStopAt: Date? = nil) {
        if let session, session.state == .running || session.state == .prepared {
            return
        }
        guard HKHealthStore.isHealthDataAvailable() else {
            fallback.start(autoStopAt: fallbackAutoStopAt)
            return
        }
        pendingFallbackAutoStop = fallbackAutoStopAt
        Task { await self.requestAuthorizationAndStart() }
    }

    func stop() {
        fallback.stop()
        guard let session else { return }
        let endDate = Date()
        let activeBuilder = builder
        session.end()
        activeBuilder?.endCollection(withEnd: endDate) { _, _ in
            activeBuilder?.finishWorkout { _, _ in }
        }
        self.session = nil
        self.builder = nil
    }

    private func requestAuthorizationAndStart() async {
        let typesToShare: Set<HKSampleType> = [HKObjectType.workoutType()]
        let typesToRead: Set<HKObjectType> = [HKObjectType.workoutType()]
        if !authRequested {
            authRequested = true
            do {
                try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            } catch {
                fallback.start(autoStopAt: pendingFallbackAutoStop)
                return
            }
        }
        if !beginSession() {
            fallback.start(autoStopAt: pendingFallbackAutoStop)
        }
    }

    private func beginSession() -> Bool {
        let config = HKWorkoutConfiguration()
        config.activityType = .sailing
        config.locationType = .outdoor

        let session: HKWorkoutSession
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
        } catch {
            return false
        }
        let builder = session.associatedWorkoutBuilder()
        builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)
        session.delegate = self
        builder.delegate = self

        let startDate = Date()
        session.startActivity(with: startDate)
        builder.beginCollection(withStart: startDate) { _, _ in }

        self.session = session
        self.builder = builder
        return true
    }
}

extension WorkoutSessionController: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        if toState == .ended {
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.session === workoutSession {
                    self.session = nil
                    self.builder = nil
                }
            }
        }
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            if self.session === workoutSession {
                self.session = nil
                self.builder = nil
            }
        }
    }
}

extension WorkoutSessionController: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {}

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}
