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
            let size: CGFloat = 96
            qr.draw(in: CGRect(x: 36, y: 36, width: size, height: size))
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
