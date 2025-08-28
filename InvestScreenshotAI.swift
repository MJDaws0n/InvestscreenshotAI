import Cocoa
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var monitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.title = "🤖"
        
        // Register global hotkey for 'z'
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if let chars = event.charactersIgnoringModifiers, chars.lowercased() == "z" {
                self?.handleZKey()
            }
        }
    }
    
    func handleZKey() {
        // Take screenshot
        let screenshotPath = NSTemporaryDirectory() + "screenshot.png"
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-x", screenshotPath]
        task.launch()
        task.waitUntilExit()
        
        // Read screenshot as base64
        if let imageData = try? Data(contentsOf: URL(fileURLWithPath: screenshotPath)) {
            let base64String = imageData.base64EncodedString()
            // Call OpenAI API
            sendToOpenAI(base64Image: base64String)
        }
        // Remove screenshot file
        try? FileManager.default.removeItem(atPath: screenshotPath)
    }
    
    func sendToOpenAI(base64Image: String) {
        guard let apiKey = ProcessInfo.processInfo.environment["API_KEY"] else {
            showNotification(title: "Error", message: "API_KEY not set in environment.")
            return
        }
        let url = URL(string: "https://api.openai.com/v1/responses")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = [
            "model": "gpt-5-nano",
            "input": [[
                "role": "user",
                "content": [
                    ["type": "input_text", "text": "Hello. Just testing something."],
                    ["type": "image", "image": base64Image]
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
            if let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                self.showNotification(title: "OpenAI Response", message: String(content.prefix(200)))
            } else {
                self.showNotification(title: "OpenAI Response", message: String(describing: json))
            }
        }
        task.resume()
    }
    
    func showNotification(title: String, message: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
