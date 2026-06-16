# 怨꾩빟:
# - Responsibility: convert narrative progress history into lookup form and mark shown beats without mutating callers.
# - Input: campaign progress dictionaries and narrative beat ids.
# - Output: copied progress dictionaries with `narrativeSeenBeatIds` maintained separately from domain progress.
# - Forbidden: combat, reward, inventory, node, or UI mutation.
#
# ?ㅽ뻾: define immutable narrative history helpers.
class_name NarrativeHistory
extends RefCounted

# ?ㅽ뻾: convert persisted progress ids into a quick lookup dictionary.
static func from_progress(progress: Dictionary) -> Dictionary:
	var seen := {}
	var ids: Array = progress.get("narrativeSeenBeatIds", []) if progress.get("narrativeSeenBeatIds", []) is Array else []
	for beat_id in ids:
		seen[str(beat_id)] = true
	return seen

# ?ㅽ뻾: return a copied progress dictionary with the beat id recorded once.
static func mark_seen(progress: Dictionary, beat_id: String) -> Dictionary:
	var next := progress.duplicate(true)
	var seen_ids: Array = next.get("narrativeSeenBeatIds", []).duplicate(true) if next.get("narrativeSeenBeatIds", []) is Array else []
	if not seen_ids.has(beat_id):
		seen_ids.append(beat_id)
	next["narrativeSeenBeatIds"] = seen_ids
	return next
