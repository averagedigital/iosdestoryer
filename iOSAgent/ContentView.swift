import SwiftUI

struct ContentView: View {
  private let registry = ToolRegistry.defaultRegistry()
  @State private var message = ""
  @State private var auditLog = AuditLog()

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 14) {
            ChatBubble(
              text:
                "Ask me to work with files, photos, contacts, calendar items, OCR, or your app shortcuts. I will preview risky changes first.",
              isUser: false)
            ToolSection(registry: registry)
            AuditSection(entries: auditLog.entries)
          }
          .padding()
        }

        HStack(spacing: 10) {
          TextField("Message", text: $message, axis: .vertical)
            .textFieldStyle(.roundedBorder)
            .lineLimit(1...4)

          Button("Send") {
            auditLog.record(
              toolName: "agent.chat", summary: message.isEmpty ? "empty message ignored" : message,
              status: .succeeded)
            message = ""
          }
          .buttonStyle(.borderedProminent)
          .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .background(.regularMaterial)
      }
      .navigationTitle("iOS Agent")
    }
  }
}

private struct ChatBubble: View {
  let text: String
  let isUser: Bool

  var body: some View {
    Text(text)
      .padding(12)
      .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
      .background(isUser ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.12))
      .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
  }
}

private struct ToolSection: View {
  let registry: ToolRegistry

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Tools")
        .font(.headline)

      ForEach(registry.tools) { tool in
        HStack {
          VStack(alignment: .leading, spacing: 2) {
            Text(tool.name)
              .font(.subheadline.monospaced())
            Text(tool.appleFrameworks.joined(separator: ", "))
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          Spacer()
          if tool.requiresPreview {
            Text("Preview")
              .font(.caption.weight(.semibold))
              .padding(.horizontal, 8)
              .padding(.vertical, 4)
              .background(Color.orange.opacity(0.18))
              .clipShape(Capsule())
          }
        }
        .padding(.vertical, 6)
      }
    }
  }
}

private struct AuditSection: View {
  let entries: [AuditEntry]

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Audit")
        .font(.headline)

      if entries.isEmpty {
        Text("No tool calls yet.")
          .foregroundStyle(.secondary)
      } else {
        ForEach(entries) { entry in
          Text("\(entry.toolName): \(entry.summary)")
            .font(.caption)
        }
      }
    }
  }
}
