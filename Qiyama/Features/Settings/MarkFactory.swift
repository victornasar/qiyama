import CoreImage.CIFilterBuiltins
import PDFKit
import SwiftUI
import UIKit

enum MarkFactory {
    static func qrImage(payload: String, scale: CGFloat = 10) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let transformed = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let context = CIContext()
        guard let cg = context.createCGImage(transformed, from: transformed.extent) else { return nil }
        return UIImage(cgImage: cg)
    }

    static func pdfData(payload: String) -> Data? {
        guard let qr = qrImage(payload: payload, scale: 12) else { return nil }
        let page = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        return renderer.pdfData { ctx in
            ctx.beginPage()
            let title = "Qiyama" as NSString
            title.draw(at: CGPoint(x: 72, y: 72), withAttributes: [
                .font: UIFont.systemFont(ofSize: 28, weight: .semibold),
            ])
            let body = "Place away from the bed. Scan in the morning to prove you got up." as NSString
            body.draw(in: CGRect(x: 72, y: 120, width: 468, height: 60), withAttributes: [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.darkGray,
            ])
            let size: CGFloat = 200
            qr.draw(in: CGRect(x: (612 - size) / 2, y: 220, width: size, height: size))
            let payloadLine = payload as NSString
            let pw = payloadLine.size(withAttributes: [.font: UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)]).width
            payloadLine.draw(at: CGPoint(x: (612 - pw) / 2, y: 440), withAttributes: [
                .font: UIFont.monospacedSystemFont(ofSize: 12, weight: .regular),
            ])
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct PrintMarkView: UIViewControllerRepresentable {
    let data: Data

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        DispatchQueue.main.async {
            let printInfo = UIPrintInfo(dictionary: nil)
            printInfo.jobName = "Qiyama mark"
            printInfo.outputType = .general
            let printer = UIPrintInteractionController.shared
            printer.printInfo = printInfo
            printer.printingItem = data
            printer.present(animated: true)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
