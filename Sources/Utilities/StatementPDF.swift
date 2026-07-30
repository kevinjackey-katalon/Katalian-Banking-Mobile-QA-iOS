import Foundation
import PDFKit
import UIKit

/// Mirrors the jsPDF-based statement builder in AccountDetailsScreen.tsx.
enum StatementPDF {

    static func makeStatement(account: Account, transactions: [Transaction], period: String) -> Data {
        let pageWidth: CGFloat = 612 // 8.5in @72dpi
        let pageHeight: CGFloat = 792
        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)

        return renderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = 40

            draw("KATALIAN BANK", at: CGPoint(x: 40, y: y), size: 22, weight: .heavy, color: UIColor(KTheme.emerald))
            y += 26
            draw("PRIVATE WEALTH MANAGEMENT FACILITY", at: CGPoint(x: 40, y: y), size: 10, weight: .regular, color: .darkGray)
            y += 20

            drawLine(from: CGPoint(x: 40, y: y), to: CGPoint(x: pageWidth - 40, y: y))
            y += 20

            draw("\(account.type.rawValue) Statement", at: CGPoint(x: 40, y: y), size: 14, weight: .bold, color: .black)
            y += 18
            draw("Account Number: \(account.accountNumber)", at: CGPoint(x: 40, y: y), size: 10, weight: .regular, color: .black)
            drawRight("Available Balance: \(currency(account.balance))", rightEdge: pageWidth - 40, y: y, size: 10)
            y += 14
            draw("Period: \(period)", at: CGPoint(x: 40, y: y), size: 10, weight: .regular, color: .black)
            drawRight("Date of Issue: \(DateFormatter.shortDate.string(from: Date()))", rightEdge: pageWidth - 40, y: y, size: 10)
            y += 26

            // Table header
            let headerRect = CGRect(x: 40, y: y - 12, width: pageWidth - 80, height: 20)
            UIColor(white: 0.95, alpha: 1).setFill()
            UIGraphicsGetCurrentContext()?.fill(headerRect)
            draw("DATE", at: CGPoint(x: 46, y: y - 8), size: 9, weight: .bold, color: .black)
            draw("DESCRIPTION", at: CGPoint(x: 130, y: y - 8), size: 9, weight: .bold, color: .black)
            draw("CATEGORY", at: CGPoint(x: 340, y: y - 8), size: 9, weight: .bold, color: .black)
            drawRight("AMOUNT", rightEdge: pageWidth - 46, y: y - 8, size: 9, weight: .bold)
            y += 20

            for tx in transactions {
                if y > pageHeight - 60 {
                    context.beginPage()
                    y = 40
                }
                let dateStr = DateFormatter.shortDate.string(from: tx.date)
                draw(dateStr, at: CGPoint(x: 46, y: y), size: 9, weight: .regular, color: .black)
                let desc = tx.description.count > 34 ? String(tx.description.prefix(31)) + "..." : tx.description
                draw(desc.uppercased(), at: CGPoint(x: 130, y: y), size: 9, weight: .regular, color: .black)
                draw(tx.category.uppercased(), at: CGPoint(x: 340, y: y), size: 9, weight: .regular, color: .black)
                let amountStr = (tx.type == .credit ? "+" : "-") + currency(tx.amount)
                drawRight(amountStr, rightEdge: pageWidth - 46, y: y, size: 9,
                          color: tx.type == .credit ? UIColor(KTheme.emerald) : .black)
                y += 16
                drawLine(from: CGPoint(x: 40, y: y - 6), to: CGPoint(x: pageWidth - 40, y: y - 6), color: .init(white: 0.92, alpha: 1))
            }

            draw("This is an electronically generated document. Securely stored and encrypted at Katalian Global HQ.",
                 at: CGPoint(x: 40, y: pageHeight - 36), size: 7, weight: .regular, color: .gray)
        }
    }

    /// Mirrors DocumentLibraryScreen.tsx's generic fillable Loan Request Form.
    static func makeLoanRequestForm() -> Data {
        let pageWidth: CGFloat = 595 // A4 @72dpi
        let pageHeight: CGFloat = 842
        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)

        func field(_ label: String, y: CGFloat, x: CGFloat = 48, width: CGFloat = 230) {
            draw(label, at: CGPoint(x: x, y: y), size: 10, weight: .regular, color: .init(white: 0.3, alpha: 1))
            drawLine(from: CGPoint(x: x, y: y + 16), to: CGPoint(x: x + width, y: y + 16), color: .init(white: 0.66, alpha: 1))
        }

        return renderer.pdfData { context in
            context.beginPage()
            let ctx = context.cgContext
            ctx.setFillColor(UIColor(red: 0.06, green: 0.09, blue: 0.15, alpha: 1).cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: pageWidth, height: 92))
            draw("Loan Request Form", at: CGPoint(x: 48, y: 32), size: 20, weight: .heavy, color: .white)
            draw("Katalian Banking - Generic Loan Application", at: CGPoint(x: 48, y: 58), size: 10, weight: .regular, color: .white)

            draw("Applicant Information", at: CGPoint(x: 48, y: 120), size: 12, weight: .bold, color: .black)
            field("Full Name", y: 148, width: 240)
            field("Date of Birth (MM/DD/YYYY)", y: 148, x: 320, width: 220)
            field("Phone Number", y: 186, width: 180)
            field("Email Address", y: 186, x: 248, width: 280)
            field("Street Address", y: 224, width: 420)
            field("City", y: 262, width: 180)
            field("State", y: 262, x: 248, width: 90)
            field("ZIP Code", y: 262, x: 360, width: 110)

            draw("Loan Details", at: CGPoint(x: 48, y: 314), size: 12, weight: .bold, color: .black)
            field("Loan Type (Personal / Auto / Mortgage / Other)", y: 336, width: 300)
            field("Requested Amount (USD)", y: 374, width: 190)
            field("Requested Term (Months)", y: 374, x: 270, width: 190)
            field("Purpose of Loan", y: 412, width: 500)

            draw("Employment & Income", at: CGPoint(x: 48, y: 464), size: 12, weight: .bold, color: .black)
            field("Employer Name", y: 486, width: 240)
            field("Job Title", y: 486, x: 320, width: 240)
            field("Annual Gross Income (USD)", y: 524, width: 230)

            draw("Declarations", at: CGPoint(x: 48, y: 574), size: 12, weight: .bold, color: .black)
            draw("[ ] I certify all information provided is accurate and complete.", at: CGPoint(x: 48, y: 596), size: 10, weight: .regular, color: .black)
            draw("[ ] I authorize Katalian Banking to verify credit and employment records.", at: CGPoint(x: 48, y: 614), size: 10, weight: .regular, color: .black)

            draw("Electronic Signature", at: CGPoint(x: 48, y: 658), size: 12, weight: .bold, color: .black)
            field("Borrower Electronic Signature (type full legal name)", y: 680, width: 320)
            field("Borrower Signature Date", y: 680, x: 392, width: 155)
            field("Co-Borrower Electronic Signature (if applicable)", y: 718, width: 320)
            field("Co-Borrower Signature Date", y: 718, x: 392, width: 155)

            draw("System metadata: Signature IP, timestamp, and consent hash are recorded upon submission.",
                 at: CGPoint(x: 48, y: 772), size: 9, weight: .regular, color: .gray)
        }
    }

    // MARK: - Drawing helpers

    private static func draw(_ text: String, at point: CGPoint, size: CGFloat, weight: UIFont.Weight, color: UIColor) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: color
        ]
        text.draw(at: point, withAttributes: attrs)
    }

    private static func drawRight(_ text: String, rightEdge: CGFloat, y: CGFloat, size: CGFloat, weight: UIFont.Weight = .regular, color: UIColor = .black) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: color
        ]
        let width = (text as NSString).size(withAttributes: attrs).width
        text.draw(at: CGPoint(x: rightEdge - width, y: y), withAttributes: attrs)
    }

    private static func drawLine(from: CGPoint, to: CGPoint, color: UIColor = .init(white: 0.85, alpha: 1)) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(0.75)
        ctx.move(to: from)
        ctx.addLine(to: to)
        ctx.strokePath()
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    static let monthYear: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        return f
    }()
}
