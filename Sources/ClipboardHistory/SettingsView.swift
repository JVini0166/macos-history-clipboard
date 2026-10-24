import AppKit
import ServiceManagement
import SwiftUI

@MainActor
final class LaunchSettings: ObservableObject {
    @Published private(set) var status = SMAppService.mainApp.status
    @Published var errorMessage: String?
    @Published var itemLimit: Int {
        didSet { defaults.set(itemLimit, forKey: "historyItemLimit") }
    }
    @Published var autoClearEnabled: Bool {
        didSet { defaults.set(autoClearEnabled, forKey: "historyAutoClearEnabled") }
    }
    @Published var retentionSeconds: Int {
        didSet { defaults.set(retentionSeconds, forKey: "historyRetentionSeconds") }
    }
    private let defaults: UserDefaults
    static let durations = [300, 1800, 3600, 21600, 86400, 604800, 2592000]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let savedLimit = defaults.object(forKey: "historyItemLimit") as? Int ?? 100
        itemLimit = min(1000, max(1, savedLimit))
        autoClearEnabled = defaults.bool(forKey: "historyAutoClearEnabled")
        let savedDuration = defaults.integer(forKey: "historyRetentionSeconds")
        retentionSeconds = Self.durations.contains(savedDuration) ? savedDuration : 86400
    }

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
            Divider()
            Text("Histórico").font(.headline)
            HStack {
                Text("Quantidade máxima de itens")
                Spacer()
                TextField("Itens", value: Binding(
                    get: { settings.itemLimit },
                    set: { settings.itemLimit = min(1000, max(1, $0)) }
                ), format: .number.grouping(.never))
                .textFieldStyle(.roundedBorder).frame(width: 65)
                Stepper("Quantidade máxima de itens", value: $settings.itemLimit, in: 1...1000)
                    .labelsHidden()
            }
            Text("De 1 a 1.000 itens. Ao reduzir o limite, os itens mais antigos são removidos.")
                .font(.caption).foregroundStyle(.secondary)
            Toggle("Limpar itens antigos automaticamente", isOn: $settings.autoClearEnabled)
            if settings.autoClearEnabled {
                Picker("Remover itens após", selection: $settings.retentionSeconds) {
                    Text("5 minutos").tag(300)
                    Text("30 minutos").tag(1800)
                    Text("1 hora").tag(3600)
                    Text("6 horas").tag(21600)
                    Text("1 dia").tag(86400)
                    Text("7 dias").tag(604800)
                    Text("30 dias").tag(2592000)
                }
                Text("Cada item expira a partir da data em que foi copiado. A limpeza também funciona com a captura pausada e é aplicada ao reabrir o app.")
                    .font(.caption).foregroundStyle(.secondary)
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
