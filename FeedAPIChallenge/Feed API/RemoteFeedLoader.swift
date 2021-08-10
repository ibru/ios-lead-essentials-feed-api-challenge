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
			guard self != nil else { return }

			var completionResult: FeedLoader.Result = .failure(Error.invalidData)
			defer {
				completion(completionResult)
			}

			do {
				let successResult = try result.get()

				guard successResult.1.statusCode == 200 else {
					completionResult = .failure(Error.invalidData)
					return
				}

				let response = try JSONDecoder().decode(FeedItemsResponse.self, from: successResult.0)
				let items = response.items.map(FeedImage.init)

				completionResult = .success(items)

			} catch is DecodingError {
				completionResult = .failure(Error.invalidData)
			} catch {
				completionResult = .failure(Error.connectivity)
			}
		})
	}
}

private struct FeedItemsResponse {
	let items: [FeedImageDTO]
}

extension FeedItemsResponse: Codable {
	struct FeedImageDTO: Codable {
		let imageId: UUID
		let imageDescription: String?
		let imageLocation: String?
		let imageURL: URL

		enum CodingKeys: String, CodingKey {
			case imageId = "image_id"
			case imageDescription = "image_desc"
			case imageLocation = "image_loc"
			case imageURL = "image_url"
		}
	}
}

private extension FeedImage {
	init(with image: FeedItemsResponse.FeedImageDTO) {
		id = image.imageId
		description = image.imageDescription
		location = image.imageLocation
		url = image.imageURL
	}
}
