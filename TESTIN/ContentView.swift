//
//  TESTINApp.swift
//  TESTIN
//
//  Created by Эрика Манучарян on 20.02.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedRange: NSRange = NSRange(location: 0, length: 0)
    @State private var layers: [NSMutableAttributedString] = []
    @State private var showPopup: Bool = false
    @State private var highlightedText: String = ""
    
    init() {
        let initialText = "Выделите часть этого текста и нажмите на кнопку."
        let baseLayer = NSMutableAttributedString(string: initialText)
        _layers = State(initialValue: [NSMutableAttributedString(string: initialText), baseLayer])
    }
    
    var body: some View {
        VStack {
            ZStack {
                ForEach(layers.indices, id: \..self) { index in
                    TextView(selectedText: $layers[index], selectedRange: $selectedRange, showPopup: $showPopup, highlightedText: $highlightedText, layers: $layers)
                        .opacity(index == layers.count - 1 ? 1.0 : 0.5)
                }
            }
            .padding()
            .alert(isPresented: $showPopup) {
                Alert(title: Text("Выделенный текст"), message: Text(highlightedText), dismissButton: .default(Text("OK")))
            }
            
            Button("Выделить") {
                applyStyle()
            }
            .padding()
        }
        .padding()
    }
    
    func applyStyle() {
        guard selectedRange.length > 0, let lastLayer = layers.last else { return }
        let attributes: [NSAttributedString.Key: Any] = [
            .backgroundColor: UIColor.red.withAlphaComponent(0.25)]
        lastLayer.addAttributes(attributes, range: selectedRange)
        layers[0].addAttributes(attributes, range: selectedRange) //layer содержащий все изменения
        let freshLayer = NSMutableAttributedString(string: lastLayer.string)
        layers.append(freshLayer)
    }
}

struct TextView: UIViewRepresentable {
    @Binding var selectedText: NSMutableAttributedString
    @Binding var selectedRange: NSRange
    @Binding var showPopup: Bool
    @Binding var highlightedText: String
    @Binding var layers: [NSMutableAttributedString]
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
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
            if let position = textView.closestPosition(to: location),
               let range = textView.tokenizer.rangeEnclosingPosition(position, with: .character, inDirection: UITextDirection.layout(.left)) {
                let startOffset = textView.offset(from: textView.beginningOfDocument, to: range.start)
                let endOffset = textView.offset(from: textView.beginningOfDocument, to: range.end)
                
                let tappedRange = NSRange(location: startOffset, length: endOffset - startOffset)
                if tappedRange.length > 0, let color = parent.layers[0].attribute(.backgroundColor, at: tappedRange.location, effectiveRange: nil) as? UIColor, color == .red.withAlphaComponent(0.25) {
                    let fullText = parent.layers[0]
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
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

