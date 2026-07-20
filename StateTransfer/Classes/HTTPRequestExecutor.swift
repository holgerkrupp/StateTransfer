import Foundation

struct HTTPRequestExecutor {
    func execute(
        _ request: URLRequest,
        followRedirects: Bool
    ) async throws -> HTTPResponseSnapshot {
        let delegate = RedirectTaskDelegate(followRedirects: followRedirects)
        let start = DispatchTime.now()
        let (data, response) = try await URLSession.shared.data(
            for: request,
            delegate: delegate
        )
        guard let response = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        let end = DispatchTime.now()
        let elapsed = Double(end.uptimeNanoseconds - start.uptimeNanoseconds)
            / 1_000_000
        return HTTPResponseSnapshot.response(
            data: data,
            response: response,
            elapsedTime: elapsed,
            expectedContentLength: response.expectedContentLength > 0
                ? response.expectedContentLength
                : nil
        )
    }
}

private final class RedirectTaskDelegate: NSObject, URLSessionTaskDelegate {
    let followRedirects: Bool

    init(followRedirects: Bool) {
        self.followRedirects = followRedirects
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        completionHandler(followRedirects ? request : nil)
    }
}
