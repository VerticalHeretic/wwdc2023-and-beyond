//
//  ObservationView.swift
//  wwdc2023-and-beyond
//
//  Created by Łukasz Stachnik on 08/06/2023.
//

import SwiftUI
import Observation

struct Order: Identifiable {
    let id = UUID()
}

@Observable
class Donut: Identifiable, Equatable {
    let id = UUID()
    var name: String = ""
    let kcal: Double
    
    init(name: String, kcal: Double) {
        self.kcal = kcal
        self.name = name
    }
    
    static var all: [Donut] {
        return [Donut(name: "Glazed", kcal: 250),
                Donut(name: "Polish", kcal: 150),
                Donut(name: "Matcha", kcal: 200),
                Donut(name: "Nuttella", kcal: 500)
        ]
    }
    
    static var random: Donut {
        return all[Int.random(in: 1..<all.count)]
    }
    
    static func == (lhs: Donut, rhs: Donut) -> Bool {
        return lhs.id == rhs.id
    }
}

@Observable
class FoodTruckModel {
    var orders: [Order] = []
    var donuts = Donut.all
    var editMode = false
    
    func addDonut() {
        donuts.append(.random)
    }
    
    func removeDonut(donut: Donut) {
        donuts.removeAll(where: { $0.id == donut.id })
    }
    
    func sortDonuts() {
        donuts.sort(by: { $0.kcal < $1.kcal })
    }
    
    func toggleEdit() {
        editMode.toggle()
    }
}

struct ObservationView: View {
    let model: FoodTruckModel = FoodTruckModel()
    
    var body: some View {
        List {
            Section("Donuts") {
                ForEach(model.donuts) { donut in
                    if model.editMode {
                        DonutEditView(donut: donut)
                            .swipeActions {                                
                                Button(action: {
                                    model.toggleEdit()
                                }, label: {
                                    Label("Edit", systemImage: "pencil")
                                })
                            }
                    } else {
                        Text(donut.name)
                            .swipeActions {
                                Button(role: .destructive) {
                                    model.removeDonut(donut: donut)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button(action: {
                                    model.toggleEdit()
                                }, label: {
                                    Label("Edit", systemImage: "pencil")
                                })
                            }
                    }
                }
                
                Button("Add Donut") {
                    model.addDonut()
                }
                
                Button("Sort Donuts") {
                    model.sortDonuts()
                }
            }
        }
    }
}

struct DonutEditView: View {
    @Bindable var donut: Donut
    
    var body: some View {
        TextField("Name", text: $donut.name)
    }
}

#Preview {
    ObservationView()
}
