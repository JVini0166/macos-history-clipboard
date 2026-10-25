import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case portuguese = "pt-BR"
    case english = "en-US"

    var id: String { rawValue }
    var locale: Locale { Locale(identifier: rawValue) }
    var name: String { self == .portuguese ? "Português (Brasil)" : "English (US)" }

    func text(_ portuguese: String) -> String {
        self == .portuguese ? portuguese : Self.englishText[portuguese, default: portuguese]
    }

    static let englishText: [String: String] = [
        "Histórico de Clipboard": "Clipboard History",
        "Imagem": "Image",
        "Sair do ClipboardHistory": "Quit ClipboardHistory",
        "Ajustes": "Settings",
        "Abrir como janela flutuante para arrastar": "Open as a movable floating window",
        "Buscar textos…": "Search text…",
        "Seu histórico está vazio": "Your history is empty",
        "Nenhum resultado": "No results",
        "Copie textos ou imagens para vê-los aqui.": "Copy text or images to see them here.",
        "Excluir item": "Delete item",
        "Pausar": "Pause",
        "Limpar": "Clear",
        "Fechar": "Close",
        "Fechar a janela e manter o app em execução": "Close the window and keep the app running",
        "Selecione para colar no app anterior": "Select an item to paste into the previous app",
        "Apagar todo o histórico salvo?": "Delete all saved history?",
        "Apagar histórico": "Delete history",
        "Atalho indisponível": "Shortcut unavailable",
        "Não foi possível registrar Control + Command + V. Abra o histórico pelo ícone na barra de menus.": "Could not register Control + Command + V. Open history using the menu bar icon.",
        "Permita a colagem automática": "Allow automatic pasting",
        "O item já foi copiado. Para colar ao clicar, habilite ClipboardHistory em Ajustes do Sistema → Privacidade e Segurança → Acessibilidade. Sem essa permissão, volte ao app e use Command + V.": "The item has been copied. To paste on selection, enable ClipboardHistory in System Settings → Privacy & Security → Accessibility. Without this permission, switch back to your app and press Command + V.",
        "Abrir Ajustes": "Open Settings",
        "Agora não": "Not Now",
        "Abra o ClipboardHistory.app para configurar o início com o computador.": "Open ClipboardHistory.app to configure launch at login.",
        "Não foi possível alterar o início automático:": "Could not change launch at login:",
        "Iniciar sempre com o computador": "Launch at login",
        "Abre o ClipboardHistory na barra de menus ao entrar na sua conta do macOS.": "Opens ClipboardHistory in the menu bar when you log in to your macOS account.",
        "Execute a versão .app para habilitar esta opção.": "Run the .app version to enable this option.",
        "Aguardando sua autorização nos Itens de Início do macOS.": "Waiting for your approval in macOS Login Items.",
        "Abrir Itens de Início": "Open Login Items",
        "Histórico": "History",
        "Quantidade máxima de itens": "Maximum number of items",
        "Itens": "Items",
        "De 1 a 1.000 itens. Ao reduzir o limite, os itens mais antigos são removidos.": "From 1 to 1,000 items. Reducing the limit removes the oldest items.",
        "Limpar itens antigos automaticamente": "Automatically delete old items",
        "Remover itens após": "Delete items after",
        "5 minutos": "5 minutes",
        "30 minutos": "30 minutes",
        "1 hora": "1 hour",
        "6 horas": "6 hours",
        "1 dia": "1 day",
        "7 dias": "7 days",
        "30 dias": "30 days",
        "Cada item expira a partir da data em que foi copiado. A limpeza também funciona com a captura pausada e é aplicada ao reabrir o app.": "Each item expires based on when it was copied. Cleanup also runs while capture is paused and when the app is reopened.",
        "Concluído": "Done",
        "Não foi possível atualizar o ajuste": "Could not update setting",
        "Cancelar": "Cancel",
        "Idioma": "Language",
        "A mudança de idioma é aplicada imediatamente.": "Language changes take effect immediately.",
    ]
}
