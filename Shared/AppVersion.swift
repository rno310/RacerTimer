import Foundation

public enum AppVersion {
    public static var marketing: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }

    public static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }

    public static var displayString: String {
        "\(marketing) (\(build))"
    }
}
