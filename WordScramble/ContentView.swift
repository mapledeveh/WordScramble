//
//  ContentView.swift
//  WordScramble
//
//  Created by Alex Nguyen on 2023-05-09.
//

import SwiftUI

struct ContentView: View {
    
    @State private var usedWords = [String]()
    @State private var rootWord = ""
    @State private var newWord = ""
    
    @State private var score = 0
    @State private var letterCount = 0
    
    @State private var errorTitle = ""
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var confirmRestart = false
    @FocusState private var typingNow: Bool
    
    func addNewWord() {
        let answer = newWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard answer.count > 2 else {
            wordError(title: "Word too short", message: "Must be longer than 3 letters")
            return
        }
        
        guard isOriginal(word: answer) else {
            wordError(title: "Word used already", message: "Be more original!")
            return
        }
        
        guard isPossible(word: answer) else {
            wordError(title: "Word not possible", message: "You can't spell that word from \"\(rootWord)\"!")
            return
        }
        
        guard isReal(word: answer) else {
            wordError(title: "Word not recognized!", message: "You can't make that up!")
            return
        }
        
        if answer == rootWord {
            wordError(title: "Word not different!", message: "Don't just type in the question word!")
            return
        }
        
        withAnimation {
            usedWords.insert(answer, at: 0)
        }
        
        score += 1
        letterCount += answer.count
        
        newWord = ""
    }
    
    func startGame() {
        guard let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") else {
            fatalError("Could not load start.txt from bundle.")
        }
        
        guard let startWords = try? String(contentsOf: startWordsURL) else { return }
        
        let allWords = startWords.components(separatedBy: "\n")
        
        rootWord = allWords.randomElement() ?? "gotcha"
    }
    
    func isOriginal(word: String) -> Bool {
        !usedWords.contains(word)
    }
    
    func isPossible(word: String) -> Bool {
        var tempWord = rootWord
        
        for letter in word {
            guard let pos = tempWord.firstIndex(of: letter) else { return false }
            tempWord.remove(at: pos)
            /*
            if let pos = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: pos)
            } else {
                return false
            }
             */
        }
        
        return true
    }
    
    func isReal(word: String) -> Bool {
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        
        return misspelledRange.location == NSNotFound
    }
    
    func wordError(title: String, message: String) {
        errorTitle = title
        errorMessage = message
        showingError = true
    }
    
    func restartGame() {
        errorMessage = "Restart the game will erase all scores. Do you want to restart the game?"
        startGame()
        usedWords = [String]()
        score = 0
        letterCount = 0
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                Spacer()
                
                HStack {
                    Spacer()
                    VStack {
                        Text("\(score)")
                            .font(.system(size: 100))
                        Text("Word\(score == 1 ? "" : "s")")
                    }
                    
                    Spacer()
                    Spacer()
                    
                    VStack {
                        Text("\(letterCount)")
                            .font(.system(size: 100))
                        Text("Letter\(letterCount == 1 ? "" : "s")")
                    }
                    Spacer()
                }
                .padding()
                Divider()
                
                List {
                    ForEach(usedWords, id: \.self) { word in
                        HStack {
                            Image(systemName: "\(word.count).circle")
                            Text(word)
                        }
                        .accessibilityElement()
                        .accessibilityLabel("\(word)")
                        .accessibilityHint("\(word.count) letters")
                    }
                }
                
                Divider()
                    .padding(0)
                
                HStack {
                    TextField("Enter your word", text: $newWord)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($typingNow)
                        .padding(10)
                        .background(.background)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .shadow(radius: 1)
                    
                    Button {
                        addNewWord()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.title)
                    }
                }
                .padding()
                .background(.thinMaterial)
            }
            .navigationTitle(rootWord)
            .toolbar {
                ToolbarItem(placement: .destructiveAction) {
                    Button("Restart", role: .destructive, action: { confirmRestart = true })
                        .alert("Are you sure?", isPresented: $confirmRestart) {
                            Button("Restart", role: .destructive, action: restartGame)
                        } message: {
                            Text(errorMessage)
                        }
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    
                    Button("Done") {
                        typingNow = false
                    }
                }
            }
            .onSubmit(addNewWord)
            .onAppear(perform: startGame)
            .alert(errorTitle, isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
