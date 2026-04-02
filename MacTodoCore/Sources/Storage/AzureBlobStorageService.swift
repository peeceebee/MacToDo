import Foundation
import Models

public final class AzureBlobStorageService: StorageService, @unchecked Sendable {
    private let config: AzureConfiguration
    private let signer: AzureRequestSigner
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let apiVersion = "2024-11-04"

    public init(config: AzureConfiguration, session: URLSession = .shared) {
        self.config = config
        self.signer = AzureRequestSigner(accountName: config.storageAccount, base64Key: config.storageKey)
        self.session = session

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func loadWorkspace(id: UUID) async throws -> Workspace {
        let url = blobURL(for: id)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addCommonHeaders(&request)
        request = signer.sign(request)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw StorageError.networkError("Invalid response")
        }

        switch httpResponse.statusCode {
        case 200:
            do {
                return try decoder.decode(Workspace.self, from: data)
            } catch {
                throw StorageError.decodingError(error.localizedDescription)
            }
        case 404:
            throw StorageError.workspaceNotFound(id)
        case 403:
            throw StorageError.authenticationError("Access denied")
        default:
            throw StorageError.unexpectedResponse(httpResponse.statusCode)
        }
    }

    public func saveWorkspace(_ workspace: Workspace) async throws {
        let url = blobURL(for: workspace.id)
        let data: Data
        do {
            data = try encoder.encode(workspace)
        } catch {
            throw StorageError.encodingError(error.localizedDescription)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(String(data.count), forHTTPHeaderField: "Content-Length")
        request.setValue("BlockBlob", forHTTPHeaderField: "x-ms-blob-type")
        addCommonHeaders(&request)
        request = signer.sign(request)

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw StorageError.networkError("Invalid response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 403 {
                throw StorageError.authenticationError("Access denied")
            }
            throw StorageError.unexpectedResponse(httpResponse.statusCode)
        }
    }

    public func listWorkspaces() async throws -> [UUID] {
        var components = URLComponents(url: config.baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "restype", value: "container"),
            URLQueryItem(name: "comp", value: "list"),
            URLQueryItem(name: "prefix", value: "workspace-"),
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        addCommonHeaders(&request)
        request = signer.sign(request)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw StorageError.unexpectedResponse(code)
        }

        return parseBlobNames(from: data)
    }

    public func deleteWorkspace(id: UUID) async throws {
        let url = blobURL(for: id)
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        addCommonHeaders(&request)
        request = signer.sign(request)

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw StorageError.unexpectedResponse(code)
        }
    }

    // MARK: - Helpers

    private func blobURL(for workspaceID: UUID) -> URL {
        config.baseURL.appendingPathComponent("workspace-\(workspaceID.uuidString).json")
    }

    private func addCommonHeaders(_ request: inout URLRequest) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
        request.setValue(formatter.string(from: Date()), forHTTPHeaderField: "x-ms-date")
        request.setValue(apiVersion, forHTTPHeaderField: "x-ms-version")
    }

    private func parseBlobNames(from data: Data) -> [UUID] {
        let parser = BlobListXMLParser(data: data)
        return parser.parse()
    }
}

// MARK: - XML Parser for List Blobs response

private final class BlobListXMLParser: NSObject, XMLParserDelegate {
    private let data: Data
    private var blobNames: [UUID] = []
    private var currentElement: String = ""
    private var currentText: String = ""
    private var insideBlob = false

    init(data: Data) {
        self.data = data
    }

    func parse() -> [UUID] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return blobNames
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]) {
        currentElement = elementName
        if elementName == "Blob" { insideBlob = true }
        if elementName == "Name" && insideBlob { currentText = "" }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if currentElement == "Name" && insideBlob {
            currentText += string
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        if elementName == "Name" && insideBlob {
            let name = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
            if name.hasPrefix("workspace-") && name.hasSuffix(".json") {
                let uuidString = String(name.dropFirst("workspace-".count).dropLast(".json".count))
                if let uuid = UUID(uuidString: uuidString) {
                    blobNames.append(uuid)
                }
            }
        }
        if elementName == "Blob" { insideBlob = false }
        currentElement = ""
    }
}
