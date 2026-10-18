# Changelog

## Unreleased

- Added: ads tracking under the `ads` scope. Pixels: `ads.pixels`, `createPixel`,
  `pixel` (with the install `code`), `updatePixel`, `sharePixel`, `pixelStats`
  and `eventMatchQuality`. Custom conversions: `customConversions`,
  `createCustomConversion`, `customConversion`, `updateCustomConversion` and
  `deleteCustomConversion`. Conversions API: `sendPixelConversions(_:idempotencyKey:)`
  sends the required `Idempotency-Key` header, and `conversionBatches` lists the
  stored uploads with hashed events.
- Changed: `uploadConversions` takes an optional `idempotencyKey`, and
  `ConversionEvent` gained `eventId`, `actionSource`, `sourceUrl`, `externalId`,
  `clientIpAddress`, `clientUserAgent`, `clickId`, `browserId` and `contentIds`.
  `ConversionsAccepted` now also carries `id`, `eventCount` and `replayed`;
  `accepted` is unchanged.

## 0.4.0 - 2026-10-18

- Added: `client.queue`, the posting queue: `listSlots`, `createSlot`,
  `updateSlot`, `deleteSlot`, `next` and `preview`. `CreatePostRequest` and
  `UpdatePostRequest` take `schedule: "queue"` to drop a post into the next
  free slot.
- Added: `client.connectSessions` (`create`, `get`) for hosted connect links.
- Added: `posts.unpublish(_:)` takes a published post down from every platform
  that supports removal; `PostStatus.unpublished`.
- Added: `webhooks.deliveries(_:status:limit:)`, `webhooks.delivery(_:deliveryID:)`
  and `webhooks.redeliver(_:deliveryID:)`.
- Added: `automations.versions(_:page:perPage:)`, `automations.version(_:_:)`
  and `automations.restoreVersion(_:_:)`.
- Added: `client.logs.list(_:)`, the request log with its window totals.
- Added: `analytics.inbox(accountID:workspaceID:days:timeZone:)`.

## 0.3.0 - 2026-10-18

- Changed: the blog resource follows the live wire format: `workspace_id` on
  the query string, snake_case answers (bare objects, `{data: [...]}` lists),
  and `website_secret` beside the settings on update.
  `BlogSettingsUpdated.data` is now `settings`, and `BlogWebsiteTest.status` is
  now `httpStatus`; a failed website test returns `ok` false with the API's
  message instead of throwing.
- Removed (breaking): `BlogSettings.autoPublish` and
  `UpdateBlogSettingsRequest.autoPublish`. The API no longer auto-publishes; an
  article publishes only after `submitArticle` moves it to review.
- Added: `blog.suggestSeeds(workspaceID:seeds:prompt:)` suggests about 10 search
  terms from the blog goal and topics (`ai` scope, `BlogSeedSuggestions`); pass
  the current seeds to refine and a prompt to steer.
- Added: `blog.submitArticle(workspaceID:_:)` moves a draft, failed or rejected
  article to the new `BlogArticleStatus.inReview` (`posts` scope). Publishing
  and setting `publishAt` now need an article in review; a draft answers 409.
- Added: `BlogSettings.goal` (`BlogGoal`), `focusTopics`, `avoidTopics` and
  `planRun` (`BlogPlanRun`, `BlogPlanRunStatus`), with `goal`, `focusTopics` and
  `avoidTopics` on `UpdateBlogSettingsRequest`; `BlogKeyword.fitReason`.
- Changed: `planKeywords` no longer fills the calendar. Results land as
  `.suggested`, and setting a keyword to `.planned` picks it. `reviewHoldDays`
  is now the days before its planned date that a picked keyword starts being
  written.
- Added: `media.limits(workspaceID:)` returns `UploadLimits`: the largest file
  the account may upload by any route (`maxFileBytes`, growing with connected
  accounts or the Large Uploads add-on), the multipart ceiling
  (`multipartMaxFileBytes`), the next tier, and the allowed types.
- Added: `posts.create(_:files:)` and `posts.update(_:_:files:)` attach up to
  five files to the first content block. Files within the multipart ceiling go
  with the post in one `multipart/form-data` request; bigger files are
  direct-uploaded first and attached by URL. An update without `content` keeps
  the post's blocks and appends to the first.
- Added: `presign` and `uploadDirect` take `PresignOptions` (`folderID`,
  `origin`, `brandRole`, `brandVoiceID`, `personConsent`); `PresignedUpload`
  gains `maxFileBytes`. Direct upload now accepts files up to 5 GB.
- Added: `uploadDirect(workspaceID:fileURL:)` streams a file off disk with an
  upload task, so nothing but its size is held in memory. `UploadFile` carries
  a `source` (`.data` or `.file`) and `UploadFile(contentsOf:)` no longer reads
  the file on init.
- Added: a 413 `file_too_large` surfaces as `FoPostError` with `status` 413,
  `code`, `maxFileBytes`, and `upgradeURL`.
- Changed: sizes are `Int64` (`presign(size:)`, `UploadedMedia.size`,
  `MediaLibraryItem.size`).
- Added: Reddit destinations on a connected account: `accounts.redditSubreddits(_:)`,
  `accounts.redditSubredditRules(_:subreddit:)`, `accounts.redditFlairs(_:subreddit:)`
  and `accounts.setRedditDefaultSubreddit(_:subreddit:)` (`RedditSubreddit`,
  `RedditSubredditRules`, `RedditFlair`; a flair id is valid only in the
  subreddit it came from). `validate.subreddit(accountId:name:)` checks a
  subreddit before posting. `inbox.vote(_:direction:)` votes an item `up`,
  `down` or `none` where `canVote` is true (`publish` scope).
- Added: `client.blogs` for articles and products that already live on a
  connected site, addressed by the platform's own ids: `listBlogs`,
  `listArticles`, `getArticle`, `createArticle`, `updateArticle`,
  `deleteArticle`, `listProducts` and `updateProduct`. `updateArticle` edits the
  live article in place. Reads need `posts`, writes `publish`.
