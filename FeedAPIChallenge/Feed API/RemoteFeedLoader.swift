//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient

	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}

	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}

	public func load(completion: @escaping (FeedLoader.Result) -> Void) {
		client.get(from: url, completion: { result in
			do {
				let successResult = try result.get()

				guard successResult.1.statusCode == 200 else {
					completion(.failure(Error.invalidData))
					return
				}

				_ = try JSONDecoder().decode([String: [[String]]].self, from: successResult.0)

				completion(.success([]))
			} catch is DecodingError {
				completion(.failure(Error.invalidData))
			} catch {
				completion(.failure(Error.connectivity))
			}
		})
	}
}
