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
		client.get(from: url, completion: { [weak self] result in
			guard let self = self else { return }

			let completionResult: FeedLoader.Result

			do {
				let (data, urlResponse) = try result.get()
				completionResult = self.parse(response: urlResponse, having: data)
			} catch {
				completionResult = .failure(Error.connectivity)
			}

			completion(completionResult)
		})
	}
}

private extension RemoteFeedLoader {
	func parse(response urlResponse: HTTPURLResponse, having data: Data) -> FeedLoader.Result {
		guard
			urlResponse.statusCode == 200,
			let feedResponse = try? JSONDecoder().decode(FeedItemsResponse.self, from: data)
		else {
			return .failure(Error.invalidData)
		}

		let items = feedResponse.items.map(FeedImage.init)
		return .success(items)
	}
}

private struct FeedItemsResponse {
	let items: [FeedImageDTO]
}

extension FeedItemsResponse: Decodable {
	struct FeedImageDTO: Decodable {
		let image_id: UUID
		let image_desc: String?
		let image_loc: String?
		let image_url: URL
	}
}

private extension FeedImage {
	init(with image: FeedItemsResponse.FeedImageDTO) {
		id = image.image_id
		description = image.image_desc
		location = image.image_loc
		url = image.image_url
	}
}
