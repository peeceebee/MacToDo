import Foundation
import CryptoKit

struct AzureRequestSigner: Sendable {
    let accountName: String
    let accountKey: Data

    init(accountName: String, base64Key: String) {
        self.accountName = accountName
        self.accountKey = Data(base64Encoded: base64Key) ?? Data()
    }

    func sign(_ request: URLRequest) -> URLRequest {
        var request = request
        let method = request.httpMethod ?? "GET"
        let contentLength = request.httpBody.map { String($0.count) } ?? ""
        let contentType = request.value(forHTTPHeaderField: "Content-Type") ?? ""

        let headers = [
            "Content-Encoding", "Content-Language", "Content-Length",
            "Content-MD5", "Content-Type", "Date", "If-Modified-Since",
            "If-Match", "If-None-Match", "If-Unmodified-Since", "Range",
        ]

        let headerValues: [String] = headers.map { header in
            switch header {
            case "Content-Length":
                return contentLength.isEmpty ? "" : contentLength
            case "Content-Type":
                return contentType
            default:
                return request.value(forHTTPHeaderField: header) ?? ""
            }
        }

        let canonicalizedHeaders = buildCanonicalizedHeaders(request)
        let canonicalizedResource = buildCanonicalizedResource(request)

        let stringToSign = ([method] + headerValues + [canonicalizedHeaders, canonicalizedResource])
            .joined(separator: "\n")

        let key = SymmetricKey(data: accountKey)
        let signature = HMAC<SHA256>.authenticationCode(
            for: Data(stringToSign.utf8),
            using: key
        )
        let base64Signature = Data(signature).base64EncodedString()

        request.setValue("SharedKey \(accountName):\(base64Signature)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func buildCanonicalizedHeaders(_ request: URLRequest) -> String {
        guard let allHeaders = request.allHTTPHeaderFields else { return "" }

        let msHeaders = allHeaders
            .filter { $0.key.lowercased().hasPrefix("x-ms-") }
            .sorted { $0.key.lowercased() < $1.key.lowercased() }
            .map { "\($0.key.lowercased()):\($0.value)" }

        return msHeaders.joined(separator: "\n")
    }

    private func buildCanonicalizedResource(_ request: URLRequest) -> String {
        guard let url = request.url else { return "" }

        var resource = "/\(accountName)\(url.path)"

        if let query = url.query {
            let params = query.split(separator: "&")
                .compactMap { pair -> (String, String)? in
                    let parts = pair.split(separator: "=", maxSplits: 1)
                    guard parts.count == 2 else { return nil }
                    return (String(parts[0]).lowercased(), String(parts[1]))
                }
                .sorted { $0.0 < $1.0 }

            for (key, value) in params {
                resource += "\n\(key):\(value)"
            }
        }

        return resource
    }
}
