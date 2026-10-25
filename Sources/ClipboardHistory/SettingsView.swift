import AppKit
import ServiceManagement
import SwiftUI

@MainActor
final class LaunchSettings: ObservableObject {
    @Published private(set) var status = SMAppService.mainApp.status
    @Published var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: "appLanguage") }
    }
    func text(_ portuguese: String) -> String { language.text(portuguese) }

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
        language = AppLanguage(rawValue: defaults.string(forKey: "appLanguage") ?? "") ?? .portuguese
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
            errorMessage = text("Abra o ClipboardHistory.app para configurar o início com o computador.")
            return
        }
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            errorMessage = text("Não foi possível alterar o início automático:") + " " + error.localizedDescription
        }
        refresh()
    }
}

struct SettingsView: View {
    @ObservedObject var settings: LaunchSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(settings.text("Ajustes")).font(.title2.bold())
                Picker(settings.text("Idioma"), selection: $settings.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.name).tag(language)
                    }
                }
                Text(settings.text("A mudança de idioma é aplicada imediatamente."))
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                Divider()
                Toggle(settings.text("Iniciar sempre com o computador"), isOn: Binding(
                    get: { settings.isRegistered },
                    set: { settings.setEnabled($0) }
                ))
                .disabled(!settings.isBundled)
                Text(settings.text("Abre o ClipboardHistory na barra de menus ao entrar na sua conta do macOS."))
                    .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                if !settings.isBundled {
                    Text(settings.text("Execute a versão .app para habilitar esta opção."))
                        .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
                if settings.status == .requiresApproval {
                    Text(settings.text("Aguardando sua autorização nos Itens de Início do macOS."))
                        .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    Button(settings.text("Abrir Itens de Início")) { SMAppService.openSystemSettingsLoginItems() }
                }
                Divider()
                Text(settings.text("Histórico")).font(.headline)
                HStack {
                    Text(settings.text("Quantidade máxima de itens"))
                    Spacer()
                    TextField(settings.text("Itens"), value: Binding(
                        get: { settings.itemLimit },
                        set: { settings.itemLimit = min(1000, max(1, $0)) }
                    ), format: .number.grouping(.never))
                    .textFieldStyle(.roundedBorder).frame(width: 65)
                    Stepper(settings.text("Quantidade máxima de itens"), value: $settings.itemLimit, in: 1...1000)
                        .labelsHidden()
                }
                Text(settings.text("De 1 a 1.000 itens. Ao reduzir o limite, os itens mais antigos são removidos."))
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                Toggle(settings.text("Limpar itens antigos automaticamente"), isOn: $settings.autoClearEnabled)
                if settings.autoClearEnabled {
                    Picker(settings.text("Remover itens após"), selection: $settings.retentionSeconds) {
                        Text(settings.text("5 minutos")).tag(300)
                        Text(settings.text("30 minutos")).tag(1800)
                        Text(settings.text("1 hora")).tag(3600)
                        Text(settings.text("6 horas")).tag(21600)
                        Text(settings.text("1 dia")).tag(86400)
                        Text(settings.text("7 dias")).tag(604800)
                        Text(settings.text("30 dias")).tag(2592000)
                    }
                    Text(settings.text("Cada item expira a partir da data em que foi copiado. A limpeza também funciona com a captura pausada e é aplicada ao reabrir o app."))
                        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
                HStack {
                    Spacer()
                    Button(settings.text("Concluído")) { dismiss() }.keyboardShortcut(.defaultAction)
                }
            }
            .padding(24)
        }
        .frame(width: 420, height: 550)
        .environment(\.locale, settings.language.locale)
        .onAppear { settings.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            settings.refresh()
        }
        .alert(settings.text("Não foi possível atualizar o ajuste"), isPresented: Binding(
            get: { settings.errorMessage != nil },
            set: { if !$0 { settings.errorMessage = nil } }
        )) {
            Button("OK") { settings.errorMessage = nil }
        } message: { Text(settings.errorMessage ?? "") }
    }
}
