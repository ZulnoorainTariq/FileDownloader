import SwiftUI
import Photos
import UIKit

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct SavedLink: Identifiable, Codable {
    let id = UUID()
    let link: String
    let timestamp: Date
}

struct ContentView: View {
    @State private var link: String = ""
    @State private var savedLinks: [SavedLink] = []
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var fileURL: IdentifiableURL?
    @State private var showDeleteAlert = false
    @State private var selectedLink: SavedLink?

    init() {
        if let data = UserDefaults.standard.data(forKey: "savedLinks"),
           let decoded = try? JSONDecoder().decode([SavedLink].self, from: data) {
            savedLinks = decoded
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    Text("Save It")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Save media that suits your mood")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                .padding(.top, 50)

                HStack {
                    TextField("Paste your url link here", text: $link)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                        .padding(.horizontal)

                    Button(action: { saveLink(link) }) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(link.isEmpty ? .gray : .white)
                        }
                    }
                    .disabled(link.isEmpty)
                    .padding(.trailing)
                }
                .padding(.horizontal)


                Spacer()
                
                Text("Saved Item")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .center)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(savedLinks) { savedLink in
                            VStack(alignment: .leading, spacing: 5) {
                                AsyncImage(url: URL(string: savedLink.link)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(10)
                                } placeholder: {
                                    Color.gray.frame(width: 100, height: 100)
                                }

                                Text("Downloaded at: \(formattedDate(savedLink.timestamp))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: 100, alignment: .leading)
                            }
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .onLongPressGesture {
                                selectedLink = savedLink
                                showDeleteAlert = true
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 150)
            }
            .navigationBarHidden(true)
            .background(Color.blue.ignoresSafeArea())
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Download Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .alert("Delete Link?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let selected = selectedLink {
                        deleteLink(selected)
                    }
                }
            }
            .sheet(item: $fileURL) { identifiableURL in
                ActivityView(url: identifiableURL.url)
            }
        }
    }

    func saveLink(_ link: String) {
        if savedLinks.contains(where: { $0.link == link }) {
            alertMessage = "This file has already been downloaded."
            showAlert = true
            return
        }

        guard let url = URL(string: link) else { return }

        isLoading = true

        downloadFile(from: url) { localURL in
            isLoading = false
            guard let localURL = localURL else {
                alertMessage = "❌ Failed to download the file."
                showAlert = true
                return
            }

            let fileExtension = url.pathExtension.lowercased()

            if ["jpg", "jpeg", "png", "mp4"].contains(fileExtension) {
                saveToGallery(url: localURL)
            } else {
                saveToFiles(url: localURL)
                fileURL = IdentifiableURL(url: localURL)
            }

            DispatchQueue.main.async {
                let newLink = SavedLink(link: link, timestamp: Date())
                savedLinks.append(newLink)
                saveLinksToUserDefaults()
                alertMessage = "✅ Download complete."
                showAlert = true
            }
        }
    }

    func downloadFile(from url: URL, completion: @escaping (URL?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            guard let tempURL = tempURL, error == nil else {
                completion(nil)
                return
            }

            let fileManager = FileManager.default
            let destinationURL = fileManager.temporaryDirectory.appendingPathComponent(url.lastPathComponent)

            do {
                try fileManager.moveItem(at: tempURL, to: destinationURL)
                completion(destinationURL)
            } catch {
                completion(nil)
            }
        }
        task.resume()
    }

    func saveToFiles(url: URL) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsDirectory.appendingPathComponent(url.lastPathComponent)

        do {
            let data = try Data(contentsOf: url)
            try data.write(to: destinationURL)
        } catch {}
    }

    func saveToGallery(url: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }

            DispatchQueue.main.async {
                if ["jpg", "jpeg", "png"].contains(url.pathExtension.lowercased()) {
                    if let image = UIImage(contentsOfFile: url.path) {
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    }
                } else if url.pathExtension.lowercased() == "mp4" {
                    UISaveVideoAtPathToSavedPhotosAlbum(url.path, nil, nil, nil)
                }
            }
        }
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    func deleteLink(_ link: SavedLink) {
        savedLinks.removeAll { $0.id == link.id }
        saveLinksToUserDefaults()
    }

    func saveLinksToUserDefaults() {
        if let data = try? JSONEncoder().encode(savedLinks) {
            UserDefaults.standard.set(data, forKey: "savedLinks")
        }
    }
}

struct ActivityView: UIViewControllerRepresentable {
    var url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

