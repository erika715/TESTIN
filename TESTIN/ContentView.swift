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
        _layers = State(initialValue: [baseLayer])
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
        let freshLayer = NSMutableAttributedString(string: lastLayer.string)
        layers.append(freshLayer)
    }
}

