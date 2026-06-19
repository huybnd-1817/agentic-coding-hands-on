import SwiftUI

// MARK: - KudosViewContainer

/// Owns the `KudosViewModel` lifecycle and adapts Domain entities to the UI structs
/// that `KudosView` consumes.
///
/// Bridging responsibility (Domain → UI structs) lives here, not in the VM, so the
/// VM stays pure-Domain and straightforward to unit-test without SwiftUI imports.
///
/// `selectedLanguage` is local `@State` because language selection is a UI-only concern
/// not tracked by the VM. Wiring it to `LanguagePreference` is deferred to phase-09.
struct KudosViewContainer: View {

    // MARK: - ViewModel

    @StateObject var vm: KudosViewModel

    // MARK: - Local UI-only state

    @State private var selectedLanguage: AppLanguage = .vi

    // MARK: - Body

    var body: some View {
        KudosView(
            highlights: vm.highlights.map(Self.cardData),
            feed: vm.feed.map(Self.cardData),
            hashtagOptions: vm.hashtags.map(Self.hashtagOption),
            departmentOptions: vm.departments.map(Self.departmentOption),
            stats: Self.personalStatsData(from: vm.stats),
            topRecipients: vm.topRecipients.map(Self.recipientData),
            showFireBadge: vm.showFireBadge,
            unreadCount: 0,
            selectedLanguage: $selectedLanguage,
            carouselIndex: carouselBinding,
            selectedHashtag: selectedHashtagBinding,
            selectedDepartment: selectedDepartmentBinding,
            isHashtagSheetPresented: $vm.hashtagSheetPresented,
            isDepartmentSheetPresented: $vm.departmentSheetPresented,
            onSendKudos: {},
            onCardCopyLink: { vm.copyLink($0) },
            onCardLike: { id in Task { await vm.toggleLike(id) } },
            onCardViewDetail: { _ in },
            onHashtagTagTap: { tag in Task { await vm.onHashtagTagTapped(tag) } },
            onSenderTap: { _ in },
            onRecipientTap: { _ in },
            onTopRecipientTap: { _ in },
            onOpenSecretBox: { vm.openSecretBox() },
            onViewAllKudos: {},
            onSelectHashtag: { id in Task { await vm.setHashtagFilter(id) } },
            onSelectDepartment: { id in Task { await vm.setDepartmentFilter(id) } }
        )
        .task { await vm.onAppear() }
    }

    // MARK: - Derived bindings

    /// Two-way binding for carousel index that routes writes through the VM method.
    private var carouselBinding: Binding<Int> {
        Binding(
            get: { vm.carouselIndex },
            set: { vm.onCarouselIndexChanged($0) }
        )
    }

    /// Converts `selectedHashtagId` → `HashtagOption?` for the view.
    /// On write, extracts the id and calls `setHashtagFilter` with re-tap-to-clear semantics.
    private var selectedHashtagBinding: Binding<HashtagOption?> {
        Binding(
            get: {
                guard let id = vm.selectedHashtagId,
                      let hashtag = vm.hashtags.first(where: { $0.id == id })
                else { return nil }
                return HashtagOption(id: hashtag.id, label: hashtag.tag)
            },
            set: { option in
                Task { await vm.setHashtagFilter(option?.id) }
            }
        )
    }

    /// Converts `selectedDepartmentId` → `DepartmentOption?` for the view.
    private var selectedDepartmentBinding: Binding<DepartmentOption?> {
        Binding(
            get: {
                guard let id = vm.selectedDepartmentId,
                      let dept = vm.departments.first(where: { $0.id == id })
                else { return nil }
                return DepartmentOption(id: dept.id, label: dept.name)
            },
            set: { option in
                Task { await vm.setDepartmentFilter(option?.id) }
            }
        )
    }
}

// MARK: - Domain → UI adapters (pure functions, no side-effects)

private extension KudosViewContainer {

    static func cardData(from kudos: Kudos) -> KudosCardData {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm - MM/dd/yyyy"
        formatter.timeZone = TimeZone(identifier: "Asia/Saigon")

        let senderName = kudos.isAnonymous
            ? (kudos.anonymousNickname ?? "Ẩn danh")
            : kudos.sender.displayName

        return KudosCardData(
            id: kudos.id,
            senderName: senderName,
            senderCode: kudos.sender.employeeCode ?? "",
            senderRole: starLabel(for: kudos.sender),
            senderAvatarAssetName: avatarAsset(for: kudos.sender),
            recipientName: kudos.recipient.displayName,
            recipientCode: kudos.recipient.employeeCode ?? "",
            recipientRole: starLabel(for: kudos.recipient),
            recipientAvatarAssetName: avatarAsset(for: kudos.recipient),
            timestampText: formatter.string(from: kudos.createdAt),
            title: kudos.title ?? "",
            body: kudos.message,
            hashtags: kudos.hashtags.map { $0.tag.hasPrefix("#") ? String($0.tag.dropFirst()) : $0.tag },
            heartCount: kudos.heartCount,
            isLikedByMe: kudos.isLikedByMe
        )
    }

    static func hashtagOption(from hashtag: Hashtag) -> HashtagOption {
        HashtagOption(id: hashtag.id, label: hashtag.tag)
    }

    static func departmentOption(from department: Department) -> DepartmentOption {
        DepartmentOption(id: department.id, label: department.name)
    }

    static func personalStatsData(from stats: UserStats) -> KudosPersonalStatsData {
        KudosPersonalStatsData(
            kudosReceived: stats.kudosReceivedCount,
            kudosSent: stats.kudosSentCount,
            heartsReceived: stats.kudosHeartsReceived,
            secretBoxesOpened: stats.secretBoxesOpened,
            secretBoxesUnopened: stats.secretBoxesUnopened
        )
    }

    static func recipientData(from author: KudosAuthor) -> KudosRecipientData {
        KudosRecipientData(
            // Use a stable deterministic string when userId is nil so SwiftUI's
            // ForEach diffing doesn't treat each render as a new item.
            // Strategy: derive a fixed string from displayName so identity is
            // consistent across renders (no random UUID per call).
            id: author.userId?.uuidString ?? "anon-\(author.displayName)",
            name: author.displayName,
            avatarAssetName: avatarAsset(for: author),
            rewardLabel: "Nhận được 1 áo phông SAA"
        )
    }

    // MARK: - Star tier label

    static func starLabel(for author: KudosAuthor) -> String {
        let tier = StarTier.from(received: author.kudosReceivedCount)
        switch tier {
        case .zero:  return "Newcomer"
        case .one:   return "Rising Hero"
        case .two:   return "Team Player"
        case .three: return "Legend Hero"
        }
    }

    // MARK: - Avatar asset name (local fallback until AsyncImage lands in phase-09)

    static func avatarAsset(for author: KudosAuthor) -> String {
        // Phase-09 will replace this with AsyncImage from author.avatarURL.
        // For now, deterministically pick a local asset based on author id parity.
        guard let id = author.userId else { return "kudos-card-avatar-recipient" }
        let lastByte = id.uuid.15
        return lastByte % 2 == 0 ? "kudos-card-avatar-female" : "kudos-card-avatar-male"
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    KudosViewContainer(
        vm: KudosViewModel(
            loadUseCase: LoadKudosScreenUseCase(repository: MockKudosRepository()),
            toggleReactionUseCase: ToggleKudosReactionUseCase(repository: MockKudosRepository()),
            clipboard: UIKitKudosClipboardService()
        )
    )
    .preferredColorScheme(.dark)
}
#endif
