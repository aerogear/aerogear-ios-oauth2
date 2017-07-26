import UIKit

class ForcedHEURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        return ForcedHEManager.shouldFetchThroughCellular(request.url?.absoluteString)
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        let dict = ForcedHEManager.openUrlThroughCellular(request.url?.absoluteString)
        if dict!["responseCode"] != nil {
            let contentType = String(describing: dict!["contentType"]!)
            let data = dict!["data"] as! NSData
            let response = URLResponse(url: self.request.url!, mimeType: contentType, expectedContentLength: data.length, textEncodingName: "")
            self.client!.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            self.client!.urlProtocol(self, didLoad: data as Data)
            self.client!.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {
        print("Stop loading request URL = \(String(describing: request.url?.absoluteString))")
    }
}
