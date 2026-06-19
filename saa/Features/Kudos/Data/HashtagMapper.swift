import Foundation

// MARK: - HashtagMapper

/// Lifts a `HashtagDTO` (Data) into a `Hashtag` (Domain).
enum HashtagMapper {

    static func from(_ dto: HashtagDTO) -> Hashtag {
        Hashtag(id: dto.id, tag: dto.tag)
    }
}
