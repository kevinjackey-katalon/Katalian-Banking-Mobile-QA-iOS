import SwiftUI
import PDFKit

struct DocumentLibraryView: View {
    @EnvironmentObject var appState: AppState

    @State private var pdfData: Data = StatementPDF.makeLoanRequestForm()
    @State private var showShareSheet = false
    @State private var pdfURL: URL?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("ASSET MANAGEMENT").font(.system(size: 10, weight: .black)).tracking(2).foregroundColor(KTheme.textMuted)
                    Text("Document Library").font(.system(size: 30, weight: .black)).foregroundColor(.white)
                    Text("Secure document repository for standardized client forms. The Loan Request Form below includes generic lending fields and electronic signature sections.")
                        .font(.system(size: 13)).foregroundColor(KTheme.textMuted)

                    HStack(spacing: 12) {
                        KButton(title: "Download Loan Form (PDF)") { share() }
                        KButton(title: "Dashboard", variant: .secondary) { appState.goToDashboard() }
                    }
                    .padding(.top, 8)
                }
                .padding(24)
                .background(KTheme.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: KTheme.cardRadius))
                .overlay(RoundedRectangle(cornerRadius: KTheme.cardRadius).stroke(KTheme.border, lineWidth: 1))

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Loan Request Form").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                        Spacer()
                        Text("PDF PREVIEW").font(.system(size: 9, weight: .black)).foregroundColor(KTheme.emerald)
                    }
                    PDFKitPreview(data: pdfData)
                        .frame(height: 500)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(KTheme.border, lineWidth: 1))
                }
                .padding(16)
                .background(KTheme.bgCard.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: KTheme.cardRadius))
                .overlay(RoundedRectangle(cornerRadius: KTheme.cardRadius).stroke(KTheme.border, lineWidth: 1))
            }
            .padding(20)
        }
        .kBackground()
        .navigationTitle("Document Library")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            if let pdfURL { ShareSheet(items: [pdfURL]) }
        }
    }

    private func share() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Loan Request Form.pdf")
        try? pdfData.write(to: url)
        pdfURL = url
        showShareSheet = true
    }
}

struct PDFKitPreview: UIViewRepresentable {
    let data: Data
    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.document = PDFDocument(data: data)
        return view
    }
    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = PDFDocument(data: data)
    }
}
