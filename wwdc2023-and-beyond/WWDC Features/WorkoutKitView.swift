//
//  WorkoutKitView.swift
//  wwdc2023-and-beyond
//
//  Created by Łukasz Stachnik on 08/06/2023.
//

import SwiftUI
import HealthKit
import WorkoutKit

final class WorkoutStore {

    // MARK: Creating custom workout
    static func createCyclingCustomComposition() throws -> WorkoutComposition {
        // MARK: Warmup Step
        let warmupStep = WarmupStep() // this has open goal and no alerts that's why we use default init

        // MARK: Block One
        // 10 km goal
        let tenKilometers = HKQuantity(unit: .meter(), doubleValue: 10_000)
        let tenKilometersGoal = WorkoutGoal.distance(tenKilometers)

        // Pace alert for 25 km per hour (or in other words 25_000 meters per hour)
        let paceUnit = HKUnit.meter().unitDivided(by: .hour())
        let paceValue = HKQuantity(unit: paceUnit, doubleValue: 25_000)
        let paceTarget = WorkoutTargetType.target(value: paceValue)
        let paceAlert = WorkoutAlert(type: .currentPace,
                                     target: paceTarget)

        // Work step
        let workStep = BlockStep(.work,
                                 goal: tenKilometersGoal,
                                 alert: paceAlert)

        // Block 1 - Recovery Step

        let twoKilometers = HKQuantity(unit: .meter(), doubleValue: 2_000)
        let twoKilometersGoal = WorkoutGoal.distance(twoKilometers)

        // Heart Rate Zone 1 Alert
        let heartRateAlert = WorkoutAlert(type: .currentHeartRate,
                                          target: .zone(zone: 1))

        // Recovery Step
        let recoveryStep = BlockStep(.rest,
                                     goal: twoKilometersGoal,
                                     alert: heartRateAlert)

        // Block 1 - 4 iterations
        let block1 = IntervalBlock(steps: [workStep, recoveryStep],
                                   iterations: 4)

        // MARK: Block Two

        // 2 minute goal
        let twoMinutes = HKQuantity(unit: .minute(), doubleValue: 2)
        let twoMinutesGoal = WorkoutGoal.time(twoMinutes)

        // Power range alert for 250W - 275W
        let powerMinValue = HKQuantity(unit: .watt(), doubleValue: 250)
        let powerMaxValue = HKQuantity(unit: .watt(), doubleValue: 275)
        let powerRange = WorkoutTargetType.range(min: powerMinValue, max: powerMaxValue)

        let powerAlert = WorkoutAlert(type: .currentPower,
                                      target: powerRange)

        // Work Step 2
        let workStep2 = BlockStep(.work,
                                  goal: twoMinutesGoal,
                                  alert: powerAlert)

        // 30 second goal
        let thirtySeconds = HKQuantity(unit: .second(), doubleValue: 30)
        let thirtySecondsGoal = WorkoutGoal.time(thirtySeconds)

        // Heart Rate Zone 1 Alert
        let heartRateAlert2 = WorkoutAlert(type: .currentHeartRate,
                                           target: .zone(zone: 1))

        // Recovery Step 2
        let recoveryStep2 = BlockStep(.rest,
                                      goal: thirtySecondsGoal,
                                      alert: heartRateAlert2)

        // Block 2 - 2 iterations
        let block2 = IntervalBlock(steps: [workStep2, recoveryStep2],
                                   iterations: 2)

        // MARK: Cooldown step

        // 5 minute goal
        let fiveMinutes = HKQuantity(unit: .minute(), doubleValue: 5)
        let fiveMinutesGoal = WorkoutGoal.time(fiveMinutes)

        // Cooldown
        let cooldownStep = CooldownStep(goal: fiveMinutesGoal)

        let cyclingActivity = HKWorkoutActivityType.cycling
        let location = HKWorkoutSessionLocationType.outdoor

        let composition = try CustomWorkoutComposition(activity: cyclingActivity,
                                            location: location,
                                            displayName: "My First Workout",
                                            warmup: warmupStep,
                                            blocks: [block1, block2],
                                            cooldown: cooldownStep)

        return WorkoutComposition(customComposition: composition)
    }
}

// MARK: Scheduling workouts for the user
struct WorkoutKitInterface {
    var workoutPlan = WorkoutPlan()

    func getAuthorizationState() async -> WorkoutPlan.AuthorizationState {
        do {
            return try await WorkoutPlan.authorizationState
        } catch {
            return .undetermined
        }
    }

    func requestAuthorization() async -> WorkoutPlan.AuthorizationState {
        do {
            return try await WorkoutPlan.requestAuthorization()
        } catch {
            return .undetermined
        }
    }

    mutating func getCurrentWorkoutPlan() async throws {
        self.workoutPlan = try await WorkoutPlan.current
    }

    func scheduledWorkouts() -> [ScheduledWorkoutComposition] {
        var scheduledCompositions: [ScheduledWorkoutComposition] = []

        do {
            let cyclingComposition1 = try WorkoutStore.createCyclingCustomComposition()
            let scheduledCycling1 = ScheduledWorkoutComposition(cyclingComposition1, scheduledDate: Date(timeIntervalSinceNow: 60 * 60))
            scheduledCompositions.append(scheduledCycling1)

            let cyclingComposition2 = try WorkoutStore.createCyclingCustomComposition()
            let scheduledCycling2 = ScheduledWorkoutComposition(cyclingComposition2, scheduledDate: Date(timeIntervalSinceNow: 60 * 60 * 24))
            scheduledCompositions.append(scheduledCycling2)
        } catch {
            // Handle validations here
        }

        return scheduledCompositions
    }

    mutating func save() async throws {
        let scheduledWorkouts = scheduledWorkouts()
        workoutPlan.scheduledCompositions.append(contentsOf: scheduledWorkouts)
        try await workoutPlan.save()
    }

    func isWorkoutCompleted(_ scheduledComposition: ScheduledWorkoutComposition) -> Bool {
        return scheduledComposition.completed
    }
}

final class WorkoutKitViewModel: ObservableObject {
    let cyclingWorkoutComposition = try? WorkoutStore.createCyclingCustomComposition()

    @Published var workoutInterface = WorkoutKitInterface()
    @Published var showAlert = false

    @MainActor func getWorkoutPlan() async throws {
        try await workoutInterface.getCurrentWorkoutPlan()
        showAlert = true
    }

    @MainActor func populateWorkoutPlans() async throws {
        try await workoutInterface.save()
    }
}

struct WorkoutKitView: View {
    @StateObject var viewModel = WorkoutKitViewModel()

    var body: some View {
        List {
            Section("Save workout to watch") {
                Button("Save Workout") {
                    let workoutComposition = viewModel.cyclingWorkoutComposition

                    Task {
                        try await workoutComposition.presentPreview()
                    }
                }

                Button("Schedule Workouts") {
                    Task {
                        do {
                            try await viewModel.populateWorkoutPlans()
                        } catch {
                            print(error)
                        }
                    }
                }
            }

            Section("Fetch from watch") {
                Button("Get Workout Plan") {
                    Task {
                        do {
                            try await viewModel.getWorkoutPlan()
                        } catch {
                            print(error)
                        }
                    }
                }
            }

            Section("Authorization") {
                Button("Request Authorization") {
                    Task {
                        let authorized = await viewModel.workoutInterface.requestAuthorization()
                        print(authorized)
                    }
                }
            }
        }
        .alert("Workout Plan Fetched", isPresented: $viewModel.showAlert, actions: {

        }, message: {
            Text("Fetch scheduled workout plans: \(viewModel.workoutInterface.workoutPlan.scheduledCompositions.count)")
        })
    }
}

#Preview {
    WorkoutKitView()
}
