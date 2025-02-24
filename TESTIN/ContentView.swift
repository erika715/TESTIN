//
//  TESTINApp.swift
//  TESTIN
//
//  Created by Эрика Манучарян on 20.02.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedRange: NSRange = NSRange(location: 0, length: 0)
    @State private var selectedText: NSMutableAttributedString
    @State private var showPopup: Bool = false
    @State private var highlightedText: String = ""
    
    init() {
        let initialText = "Выделите часть этого текста и нажмите на кнопку."
        self._selectedText = State(initialValue: NSMutableAttributedString(string: initialText))
    }
    
    var body: some View {
        VStack {
            TextView(selectedText: $selectedText, selectedRange: $selectedRange, showPopup: $showPopup, highlightedText: $highlightedText)
                .padding()
                .alert(isPresented: $showPopup) {
                    Alert(title: Text("Выделенный текст"), message: Text(highlightedText), dismissButton: .default(Text("OK")))
                }
            
            Button("Button") {
                applyStyle()
            }
            .padding()
        }
        .padding()
    }
    
    func applyStyle() {
        guard selectedRange.length > 0 else { return }
        
        let attributes: [NSAttributedString.Key: Any] = [
            .backgroundColor: UIColor.red.withAlphaComponent(0.5),
            //.strikethroughStyle: NSUnderlineStyle.single.rawValue
        ]
        
        selectedText.addAttributes(attributes, range: selectedRange)
        selectedText = NSMutableAttributedString(attributedString: selectedText)
    }
}

struct TextView: UIViewRepresentable {
    @Binding var selectedText: NSMutableAttributedString
    @Binding var selectedRange: NSRange
    @Binding var showPopup: Bool
    @Binding var highlightedText: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.attributedText = selectedText
        textView.isEditable = false
        textView.delegate = context.coordinator
        textView.backgroundColor = .white
        textView.isUserInteractionEnabled = true
        
        let font = UIFont.systemFont(ofSize: 25)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        selectedText.addAttributes(attributes, range: NSRange(location: 0, length: selectedText.length))
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        textView.addGestureRecognizer(tapGesture)
        
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
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let textView = gesture.view as? UITextView else { return }
            let location = gesture.location(in: textView)
            if let position = textView.closestPosition(to: location),
               let range = textView.tokenizer.rangeEnclosingPosition(position, with: .character, inDirection: UITextDirection.layout(.left)) {
                
                let startOffset = textView.offset(from: textView.beginningOfDocument, to: range.start)
                let endOffset = textView.offset(from: textView.beginningOfDocument, to: range.end)
                
                
                let tappedRange = NSRange(location: startOffset, length: endOffset - startOffset)
                
                if tappedRange.length > 0, let color = textView.attributedText.attribute(.backgroundColor, at: tappedRange.location, effectiveRange: nil) as? UIColor, color == .red.withAlphaComponent(0.5) {
                    
                    
                    let fullText = textView.attributedText!
                    let lenght = fullText.length
                    var start = startOffset
                    var end = endOffset
                    
                    while start > 0, let color = fullText.attribute(.backgroundColor, at: start-1, effectiveRange: nil) as? UIColor, color == .red.withAlphaComponent(0.5) {
                        start -= 1
                    }
                    while end < lenght, let color = fullText.attribute(.backgroundColor, at: end, effectiveRange: nil) as? UIColor, color == .red.withAlphaComponent(0.5) {
                        end += 1
                    }
                    let highlightedRange = NSRange(location: start, length: end-start)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
