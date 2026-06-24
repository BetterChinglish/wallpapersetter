import Foundation

// MARK: - API Client

actor APIClient {
    static let shared = APIClient()

    // Configure your backend URL here
    private let baseURL: String
    private var session: URLSession
    private let decoder: JSONDecoder

    private init() {
        // Default to localhost; override via Info.plist or environment in production
        self.baseURL = ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://localhost:3000"
        self.session = URLSession.shared
        self.decoder = JSONDecoder()

        // Configure longer timeout for uploads
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }

    // MARK: - Generic Request

    func request<T: Decodable>(
        method: String = "GET",
        path: String,
        body: Data? = nil,
        token: String? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            urlRequest.httpBody = body
        }

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Multipart Upload

    func upload(
        path: String,
        fileData: Data,
        fileName: String,
        mimeType: String,
        fields: [String: String],
        token: String? = nil
    ) async throws -> Data {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }

        let boundary = UUID().uuidString
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let token {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var bodyData = Data()
        for (key, value) in fields {
            bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
            bodyData.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            bodyData.append("\(value)\r\n".data(using: .utf8)!)
        }
        bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
        bodyData.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        bodyData.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        bodyData.append(fileData)
        bodyData.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        urlRequest.httpBody = bodyData

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.uploadFailed
        }

        return data
    }
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, data: Data)
    case decodingError(Error)
    case uploadFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL: "无效的请求地址"
        case .invalidResponse: "服务器无响应"
        case .httpError(let code, _): "请求失败 (\(code))"
        case .decodingError: "数据解析错误"
        case .uploadFailed: "上传失败"
        }
    }
}
