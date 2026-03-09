import Foundation
import PDFKit
import Vision
import UIKit

/// Extracts text from PDF files and images using PDFKit and VisionKit OCR.
enum TextExtractor {

    // MARK: - Public API

    /// Extract text from data, auto-detecting PDF vs image.
    static func extractText(from data: Data) async -> String? {
        if isPDF(data) {
            return await extractFromPDF(data)
        } else if let image = UIImage(data: data) {
            return await ocrImage(image)
        }
        return nil
    }

    // MARK: - PDF Text Extraction

    /// Extract text from PDF using PDFKit first; if insufficient, OCR each page.
    static func extractFromPDF(_ data: Data) async -> String? {
        guard let document = PDFDocument(data: data) else { return nil }

        // 1. Try PDFKit text extraction (fast, works for digital PDFs)
        let pdfKitText = (0..<document.pageCount).compactMap { pageIndex in
            document.page(at: pageIndex)?.string
        }.joined(separator: "\n")

        // If we got reasonable text, use it
        if pdfKitText.trimmingCharacters(in: .whitespacesAndNewlines).count > 50 {
            return pdfKitText
        }

        // 2. Fallback: OCR each page (for scanned PDFs)
        var ocrResults: [String] = []
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }

            // Render page to image
            let pageRect = page.bounds(for: .mediaBox)
            let scale: CGFloat = 2.0 // 2x for better OCR accuracy
            let size = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)

            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { ctx in
                ctx.cgContext.translateBy(x: 0, y: size.height)
                ctx.cgContext.scaleBy(x: scale, y: -scale)
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }

            if let text = await ocrImage(image) {
                ocrResults.append(text)
            }
        }

        let combined = ocrResults.joined(separator: "\n")
        return combined.isEmpty ? nil : combined
    }

    // MARK: - Image OCR

    /// Perform OCR on a UIImage using Apple Vision framework.
    static func ocrImage(_ image: UIImage) async -> String? {
        guard let cgImage = image.cgImage else { return nil }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: nil)
                    return
                }

                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")

                continuation.resume(returning: text.isEmpty ? nil : text)
            }

            request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }

    // MARK: - Helpers

    /// Check if data is a PDF by examining magic bytes.
    private static func isPDF(_ data: Data) -> Bool {
        guard data.count >= 5 else { return false }
        let header = data.prefix(5)
        return header.elementsEqual([0x25, 0x50, 0x44, 0x46, 0x2D]) // %PDF-
    }
}
