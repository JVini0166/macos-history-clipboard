import AppKit
import ServiceManagement
import SwiftUI

@MainActor
final class LaunchSettings: ObservableObject {
    @Published private(set) var status = SMAppService.mainApp.status
    @Published var errorMessage: String?

    var isRegistered: Bool { status == .enabled || status == .requiresApproval }
    var isBundled: Bool { Bundle.main.bundleURL.pathExtension == "app" }

    func refresh() { status = SMAppService.mainApp.status }

    func setEnabled(_ enabled: Bool) {
        guard isBundled else {
            errorMessage = "Abra o ClipboardHistory.app para configurar o início com o computador."
            return
        }
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            errorMessage = "Não foi possível alterar o início automático: \(error.localizedDescription)"
        }
        refresh()
    }
}

struct SettingsView: View {
    @ObservedObject var settings: LaunchSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Ajustes").font(.title2.bold())
            Toggle("Iniciar sempre com o computador", isOn: Binding(
                get: { settings.isRegistered },
                set: { settings.setEnabled($0) }
            ))
            .disabled(!settings.isBundled)
            Text("Abre o ClipboardHistory na barra de menus ao entrar na sua conta do macOS.")
                .font(.callout).foregroundStyle(.secondary)
            if !settings.isBundled {
                Text("Execute a versão .app para habilitar esta opção.")
                    .font(.callout).foregroundStyle(.secondary)
            }
            if settings.status == .requiresApproval {
                Text("Aguardando sua autorização nos Itens de Início do macOS.")
                    .font(.callout).foregroundStyle(.secondary)
                Button("Abrir Itens de Início") { SMAppService.openSystemSettingsLoginItems() }
            }
            HStack {
                Spacer()
                Button("Concluído") { dismiss() }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(24).frame(width: 390)
        .onAppear { settings.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            settings.refresh()
        }
        .alert("Não foi possível atualizar o ajuste", isPresented: Binding(
            get: { settings.errorMessage != nil },
            set: { if !$0 { settings.errorMessage = nil } }
        )) {
            Button("OK") { settings.errorMessage = nil }
        } message: { Text(settings.errorMessage ?? "") }
    }
}
