import Foundation

public struct AzureConfiguration: Sendable {
    public let storageAccount: String
    public let storageKey: String
    public let containerName: String

    public var baseURL: URL {
        URL(string: "https://\(storageAccount).blob.core.windows.net/\(containerName)")!
    }

    public init(storageAccount: String, storageKey: String, containerName: String) {
        self.storageAccount = storageAccount
        self.storageKey = storageKey
        self.containerName = containerName
    }

    public static func fromEnvironment() -> AzureConfiguration? {
        guard
            let account = ProcessInfo.processInfo.environment["AZURE_STORAGE_ACCOUNT"],
            let key = ProcessInfo.processInfo.environment["AZURE_STORAGE_KEY"],
            let container = ProcessInfo.processInfo.environment["AZURE_CONTAINER_NAME"]
        else {
            return nil
        }
        return AzureConfiguration(storageAccount: account, storageKey: key, containerName: container)
    }
}
