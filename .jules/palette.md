# Palette's Journal

## 2024-05-22 - Initial Setup
**Learning:** This is a PowerShell CLI tool. UX here means console output, colors, emojis, progress indicators, and clear text feedback.
**Action:** Focus on scripts in `scripts/` to improve visual feedback and clarity.

## 2024-05-22 - Visual Quota Indicators
**Learning:** Adding ASCII progress bars (e.g., `[=====.....]`) to quota percentages significantly improves scanability in CLI tools.
**Action:** Use the `Get-ProgressBar` helper function pattern for any future percentage-based displays.

## 2024-05-22 - Relative Time Context
**Learning:** In CLI dashboards showing reset times or deadlines, absolute timestamps require cognitive effort to translate. Relative time (e.g., "in 2h") provides immediate, actionable context.
**Action:** When displaying future timestamps in CLIs, always pair them with a relative duration helper.
