import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var droppedText = "Drop text files here"
    
    var body: some View {
        VStack {
            Text(droppedText)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .onDrop(of: [UTType.fileURL], isTargeted: nil) { providers in
                    handleDrop(providers: providers)
                }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var allText = ""
        let group = DispatchGroup()
        
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (item, error) in
                    if let urlData = item as? Data, let url = URL(dataRepresentation: urlData, relativeTo: nil) {
                        if url.hasDirectoryPath {
                            processFolder(url: url, allText: &allText, group: group)
                        } else {
                            processFile(url: url, allText: &allText)
                        }
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(allText, forType: .string)
            droppedText = "Content copied to clipboard!"
        }
        
        return true
    }
    
    private func processFile(url: URL, allText: inout String) {
        do {
            let content = try String(contentsOf: url)
            allText += content + "\n"
        } catch {
            DispatchQueue.main.async {
                droppedText = "Failed to read one or more files"
            }
        }
    }
    
    private func processFolder(url: URL, allText: inout String, group: DispatchGroup) {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            for fileURL in fileURLs where fileURL.pathExtension != "" {
                group.enter()
                processFile(url: fileURL, allText: &allText)
                group.leave()
            }
        } catch {
            DispatchQueue.main.async {
                droppedText = "Failed to read folder"
            }
        }
    }
}

#Preview {
    ContentView()
}
