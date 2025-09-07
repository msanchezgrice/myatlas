import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var repo: AppRepository

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
                            Text(scase.specialty).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: addExample) { Image(systemName: "plus") }
                }
            }
        }
    }

    private func addExample() {
        let patient = repo.createPatient(fullName: "Jane Doe", dateOfBirth: nil)
        _ = repo.createCase(for: patient.id, title: "Upper Blepharoplasty", specialty: "Oculoplastics")
    }
}

#Preview { LibraryView().environmentObject(AppRepository()) }
