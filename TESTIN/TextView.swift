//
//  TextView.swift
//  TESTIN
//
//  Created by Эрика Манучарян on 24.02.2025.
//

import SwiftUI


struct TextView: UIViewRepresentable {
    @Binding var selectedText: NSMutableAttributedString
    @Binding var selectedRange: NSRange
    @Binding var showPopup: Bool
    @Binding var highlightedText: String
    @Binding var layers: [NSMutableAttributedString]
    
    func makeUIView(context: Context) -> UITextView {
        let textView = CustomTextView()
        textView.attributedText = selectedText
        textView.isEditable = false
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        let font = UIFont.systemFont(ofSize: 25)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        selectedText.addAttributes(attributes, range: NSRange(location: 0, length: selectedText.length))
        
        let singleTapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSingleTap(_:)))
        textView.addGestureRecognizer(singleTapGesture)
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = selectedText
    }
    
    
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: TextView
        
        init(_ parent: TextView) {
            self.parent = parent
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            DispatchQueue.main.async {
                if let selectedTextRange = textView.selectedTextRange {
                    let location = textView.offset(from: textView.beginningOfDocument, to: selectedTextRange.start)
                    let length = textView.offset(from: selectedTextRange.start, to: selectedTextRange.end)
                    self.parent.selectedRange = NSRange(location: location, length: length)
                }
            }
        }
        
        @objc func handleSingleTap(_ gesture: UITapGestureRecognizer) {
            guard let textView = gesture.view as? UITextView else { return }
            let location = gesture.location(in: textView)
            
            for layer in parent.layers {
                
                if let position = textView.closestPosition(to: location),
                   let range = textView.tokenizer.rangeEnclosingPosition(position, with: .character, inDirection: UITextDirection.layout(.left)) {
                    let startOffset = textView.offset(from: textView.beginningOfDocument, to: range.start)
                    let endOffset = textView.offset(from: textView.beginningOfDocument, to: range.end)
                    
                    let tappedRange = NSRange(location: startOffset, length: endOffset - startOffset)
                    if tappedRange.length > 0, let color = layer.attribute(.backgroundColor, at: tappedRange.location, effectiveRange: nil) as? UIColor, color == .red.withAlphaComponent(0.25) {
                        let fullText = layer
                        let length = fullText.length
                        var start = startOffset
                        var end = endOffset
                        
                        while start > 0, let color = fullText.attribute(.backgroundColor, at: start - 1, effectiveRange: nil) as? UIColor, color == .red.withAlphaComponent(0.25) {
                            start -= 1
                        }
                        while end < length, let color = fullText.attribute(.backgroundColor, at: end, effectiveRange: nil) as? UIColor, color == .red.withAlphaComponent(0.25) {
                            end += 1
                        }
                        let highlightedRange = NSRange(location: start, length: end - start)
                        let tappedText = (fullText.string as NSString).substring(with: highlightedRange)
                        
                        DispatchQueue.main.async {
                            self.parent.highlightedText = tappedText
                            self.parent.showPopup = true
                        }
                    }
                }
            }
        }

    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

class CustomTextView: UITextView {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool { return false } // отключаю всплывающ меню
}
