# 怨꾩빟:
# - Responsibility: expose narrative seen-state progress updates as a vocabulary action.
# - Input: campaign progress dictionaries and selected narrative beat ids.
# - Output: copied progress dictionaries with narrative history updated.
# - Forbidden: combat, reward, inventory, node, telemetry, or UI mutation.
#
# ?ㅽ뻾: define the narrative seen-state vocabulary wrapper.
class_name MarkNarrativeSeen
extends RefCounted

const NarrativeHistoryScript = preload("res://src/models/NarrativeHistory.gd")

# ?ㅽ뻾: mark a non-empty beat id as seen on a copied progress dictionary.
static func mark_seen(progress: Dictionary, beat_id: String) -> Dictionary:
	if beat_id.is_empty():
		return progress.duplicate(true)
	return NarrativeHistoryScript.mark_seen(progress, beat_id)
