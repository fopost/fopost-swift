# Changelog

## Unreleased

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
