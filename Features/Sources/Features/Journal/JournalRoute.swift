import JournalCore

/// Every destination `JournalCoordinator`'s stack can push. `JournalListView`
/// pushes `.followUp`/`.entryDetail` directly via `NavigationLink(value:)`;
/// `.draftReview` is only ever pushed by the coordinator itself, in response to
/// `FollowUpView`'s `onContinue` callback.
enum JournalRoute: Hashable {
    case followUp(Entry)
    case entryDetail(Entry)
    case draftReview(DraftReviewParams)
}
