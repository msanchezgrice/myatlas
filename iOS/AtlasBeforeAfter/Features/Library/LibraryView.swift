import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var repo: AppRepository
    @State private var showingNewCase: Bool = false
    @State private var selectedProcedure: Procedure = .upperBlepharoplasty

    var body: some View {
        NavigationStack {
            List {
                if repo.db.cases.isEmpty {
                    Section {
                        Text("No cases yet. Tap + to add an example.")
                            .foregroundStyle(.secondary)
                    }
                }
                ForEach(repo.db.cases) { scase in
                    NavigationLink(destination: CaseDetailView(caseId: scase.id).environmentObject(repo)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(scase.title).font(.headline)
                            HStack(spacing: 8) {
                                Text(scase.specialty).font(.subheadline)
                                if let p = scase.procedure { Text("• \(p.rawValue)").font(.subheadline) }
                            }.foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Quick Example") { addExample() }
                        Divider()
                        Picker("Procedure", selection: $selectedProcedure) {
                            ForEach(Procedure.allCases) { p in Text(p.rawValue).tag(p) }
                        }
                        Button("New Case with Selected Procedure") { addWithProcedure(selectedProcedure) }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private func addExample() {
        let patient = repo.createPatient(fullName: "Jane Doe", dateOfBirth: nil)
        _ = repo.createCase(for: patient.id, title: "Upper Blepharoplasty", specialty: "Oculoplastics", procedure: .upperBlepharoplasty)
    }

    private func addWithProcedure(_ procedure: Procedure) {
        let patient = repo.createPatient(fullName: "Case Patient", dateOfBirth: nil)
        _ = repo.createCase(for: patient.id, title: procedure.rawValue, specialty: "Oculoplastics", procedure: procedure)
    }
}

#Preview { LibraryView().environmentObject(AppRepository()) }
