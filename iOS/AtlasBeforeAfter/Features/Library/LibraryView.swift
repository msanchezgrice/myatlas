import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var repo: AppRepository
    @State private var showingNewCase: Bool = false
    @State private var patientName: String = ""
    @State private var selectedProcedure: Procedure = .upperBlepharoplasty

    var body: some View {
        NavigationStack {
            List {
                if repo.db.cases.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No cases yet").font(.headline)
                            Text("Tap New Case to begin.").font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                }
                ForEach(repo.db.cases) { scase in
                    NavigationLink(destination: CaseDetailView(caseId: scase.id).environmentObject(repo)) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.08))
                                Image(systemName: "photo.on.rectangle").foregroundStyle(.secondary)
                            }
                            .frame(width: 52, height: 52)
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
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewCase = true }) { Label("New Case", systemImage: "plus") }
                }
            }
            .sheet(isPresented: $showingNewCase) { newCaseSheet }
        }
    }

    private var newCaseSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Patient")) {
                    TextField("Full name", text: $patientName)
                }
                Section(header: Text("Procedure")) {
                    Picker("Procedure", selection: $selectedProcedure) {
                        ForEach(Procedure.allCases) { p in Text(p.rawValue).tag(p) }
                    }
                }
            }
            .navigationTitle("New Case")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingNewCase = false } }
                ToolbarItem(placement: .confirmationAction) { Button("Create") { addWithProcedure(selectedProcedure) }.disabled(patientName.isEmpty) }
            }
        }
    }

    private func addWithProcedure(_ procedure: Procedure) {
        let patient = repo.createPatient(fullName: patientName, dateOfBirth: nil)
        _ = repo.createCase(for: patient.id, title: procedure.rawValue, specialty: "Oculoplastics", procedure: procedure)
        showingNewCase = false
        patientName = ""
    }
}

#Preview { LibraryView().environmentObject(AppRepository()) }
