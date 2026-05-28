# 계약:
# - 책임: heartbeat 효과음 AudioStreamWAV를 생성한다.
# - 입력: 없음.
# - 출력: 재사용 가능한 AudioStreamWAV.
# - 금지: AudioStreamPlayer 생성, UI node 접근, playback 제어.
#
# 실행: define a stateless heartbeat synthesis helper.
class_name HeartbeatSynth
extends RefCounted

# 실행: create the double-pulse heartbeat audio stream.
static func create_stream() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 8000
	stream.stereo = false
	var data = PackedByteArray()
	data.resize(6400)
	for i in range(6400):
		var t = float(i) / 8000.0
		var sample = 0.0
		if t >= 0.0 and t < 0.15:
			sample = sin(t * 2.0 * PI * 55.0) * sin((t / 0.15) * PI) * 90.0
		elif t >= 0.2 and t < 0.35:
			sample = sin(t * 2.0 * PI * 45.0) * sin(((t - 0.2) / 0.15) * PI) * 70.0
		data[i] = int(clamp(sample, -128.0, 127.0))
	stream.data = data
	return stream
