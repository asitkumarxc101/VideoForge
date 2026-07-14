import SwiftUI
import AVKit

public struct ExportPreviewModal: View {
    public let videoURL: URL
    @Environment(\.dismiss) private var dismiss
    
    public init(videoURL: URL) {
        self.videoURL = videoURL
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Export Completed Successfully!")
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding(.top)
                
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(height: 320)
                    .cornerRadius(12)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Export File Information")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text("File Name:")
                        Spacer()
                        Text(videoURL.lastPathComponent)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("File Size:")
                        Spacer()
                        if let attrs = try? FileManager.default.attributesOfItem(atPath: videoURL.path),
                           let size = attrs[.size] as? Int64 {
                            Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                                .foregroundColor(.secondary)
                        } else {
                            Text("Unknown")
                        }
                    }
                    HStack {
                        Text("Path:")
                        Spacer()
                        Text(videoURL.path)
                            .font(.system(.caption, design: .monospaced))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .foregroundColor(.secondary)
                    }
                }
                .font(.caption)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Exported Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}
