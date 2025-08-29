//
//  main.swift
//  InvestscreenshotAI
//
//  Created by Max Dawson on 28/08/2025.
//

import Foundation
import Cocoa
import Carbon
import UserNotifications


print("Loading App")

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var monitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.title = "📈"
        
        print("1")
        
        if !AXIsProcessTrusted() {
            print("App needs Accessibility permissions")
        }
        
        if Bundle.main.bundleURL.pathExtension == "app" {
            // Safe to use notifications
            UNUserNotificationCenter.current()
        } else {
            print("Not running as .app bundle, skipping notification.")
        }
        
        // Register global hotkey for 'z'
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 6 { // 'Z' key
                self?.handleZKey()
            }
        }
    }
    
    func handleZKey() {
        print("2")
        
        // Take screenshot
        let screenshotPath = NSTemporaryDirectory() + "screenshot.png"
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-x", screenshotPath]
        task.launch()
        task.waitUntilExit()
        
        guard let image = NSImage(contentsOfFile: screenshotPath) else { return }
        
        // Downscale image (example: half size)
        let targetSize = NSSize(width: image.size.width / 8, height: image.size.height / 8)
        let scaledImage = NSImage(size: targetSize)
        scaledImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: targetSize),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy,
                   fraction: 1.0)
        scaledImage.unlockFocus()
        
        // Convert to JPEG and Base64 with compression
        if let tiffData = scaledImage.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.3]) {
            
            let base64String = "data:image/jpeg;base64," + jpegData.base64EncodedString()
            let tempPath = NSTemporaryDirectory() + "test.txt"
            let url = URL(fileURLWithPath: tempPath)
            try? base64String.write(to: url, atomically: true, encoding: .utf8)
            print("Base64 saved at:", tempPath)
            sendToOpenAI(base64Image: base64String)
        }
        
        // Remove screenshot
        try? FileManager.default.removeItem(atPath: screenshotPath)
    }
    
    func sendToOpenAI(base64Image: String) {
        // Read API key from file (api_key.txt or .env)
        var apiKey: String? = nil
        if let path = Bundle.main.path(forResource: "api_key", ofType: "txt") {
            apiKey = try? String(contentsOfFile: path, encoding: .utf8)
        }
        let url = URL(string: "https://api.openai.com/v1/responses")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.setValue("Bearer \("API KEY")", forHTTPHeaderField: "Authorization")
        print("Screenshot captured and sent to OpenAI")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = [
            "model": "gpt-5-nano",
            "input": [[
                "role": "user",
                "content": [
                    ["type": "input_text", "text": "Based on the screenshot please predict if the market will go up or down, i know you don\'t have much data but this is fast pace so you are at no disadvantage, the entire screen is a very short time. I buy or sell order can be placed or nothing if it\'s not clear what it is. Just say what you think you should do on its own for example, buy, sell, hold, or there is no chart just say no chart. Please try to hold not very often and you can take risks, you don't have to be super certain. Don't worry I know you're not a finance expert just try your best no punishment if you get it wrong just try you best."],
                    ["type": "input_image", "image_url": base64Image]
                ]
            ]],
            "max_output_tokens": 5000
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return }
        request.httpBody = data
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                self.showNotification(title: "Error", message: error.localizedDescription)
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                self.showNotification(title: "Error", message: "Invalid response")
                return
            }
            if let output = json["output"] as? [[String: Any]],
               output.count > 1,
               let contentArray = output[1]["content"] as? [[String: Any]],
               let text = contentArray.first?["text"] as? String {
                self.showNotification(title: "OpenAI Response", message: String(text.prefix(200)))
            } else {
                self.showNotification(title: "OpenAI Response", message: String(describing: json))
            }
        }
        task.resume()
    }
    
    func showNotification(title: String, message: String) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted && error == nil {
                let content = UNMutableNotificationContent()
                content.title = title
                content.body = message
                content.sound = UNNotificationSound.default
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                center.add(request, withCompletionHandler: nil)
            }
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
