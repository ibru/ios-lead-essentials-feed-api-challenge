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
				let (data, urlResponse) = try result.get()

				guard urlResponse.statusCode == 200 else { throw Error.invalidData }

				let feedResponse = try JSONDecoder().decode(FeedItemsResponse.self, from: data)
				let items = feedResponse.items.map(FeedImage.init)

				completionResult = .success(items)

			} catch let error as Error {
				completionResult = .failure(error)
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

extension FeedItemsResponse: Decodable {
	struct FeedImageDTO: Decodable {
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
