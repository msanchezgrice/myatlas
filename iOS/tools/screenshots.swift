import SwiftUI
import UIKit

@MainActor
struct Shot: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Atlas Before & After").font(.largeTitle).bold()
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(colors: [.blue.opacity(0.7), .blue], startPoint: .top, endPoint: .bottom))
                .overlay(Text("Compare Before/After").font(.title2).bold().foregroundColor(.white))
                .frame(height: 260)
            HStack {
                Label("Eye alignment guide", systemImage: "eye")
                Spacer()
            }
            HStack {
                Label("Ghost overlay + level", systemImage: "camera.viewfinder")
                Spacer()
            }
            HStack {
                Label("Background replace export", systemImage: "square.and.arrow.up")
                Spacer()
            }
            Spacer()
        }.padding()
    }
}

func renderPNG(size: CGSize, path: String) {
    let controller = UIHostingController(rootView: Shot())
    controller.view.bounds = CGRect(origin: .zero, size: size)
    let window = UIWindow(frame: CGRect(origin: .zero, size: size))
    window.rootViewController = controller
    window.makeKeyAndVisible()
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { ctx in
        controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
    }
    if let data = image.pngData() {
        try? data.write(to: URL(fileURLWithPath: path))
        print("Wrote \(path)")
    }
}

@main
struct ScreenshotsApp {
    static func main() async {
        let fm = FileManager.default
        let root = fm.currentDirectoryPath
        let out = root + "/screenshots"
        try? fm.createDirectory(atPath: out, withIntermediateDirectories: true)
        // 6.7", 6.5", 5.5", 12.9"
        await renderPNG(size: CGSize(width: 1290, height: 2796), path: out + "/iphone_6.7_1.png")
        await renderPNG(size: CGSize(width: 1242, height: 2688), path: out + "/iphone_6.5_1.png")
        await renderPNG(size: CGSize(width: 1242, height: 2208), path: out + "/iphone_5.5_1.png")
        await renderPNG(size: CGSize(width: 2048, height: 2732), path: out + "/ipad_12.9_1.png")
    }
}


