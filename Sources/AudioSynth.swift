import Foundation
import AVFoundation

enum MusicTrack: Int {
    case none = 0
    case campfireTitle
    case palmJungle
    case amberCavern
    case magmaRidge
    case glacierPeak
    case gliderSkyBonus
    case bossRex
    case feastVictory
}

enum SoundEffect {
    case clubSwing
    case clubBonk
    case groundPound
    case dizzyStars
    case foodGobble
    case megaFeastFull
    case springBounce
    case jumpSlideWhistle
    case stoneCrack
    case rexRoar
    case spitRoastSizzle
    case gliderWhoosh
    case hurtOof
    case gemChime
    case menuMove
    case menuSelect
}

final class AudioSynth: @unchecked Sendable {
    static let shared = AudioSynth()

    private let lock = NSLock()
    private var engine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private var sampleRate: Double = 44100.0

    private var currentTrack: MusicTrack = .campfireTitle
    private var chipMode: AudioChipMode = .modernSynth
    private var musicVol: Double = 0.80
    private var sfxVol: Double = 0.85
    private var isPaused: Bool = false

    // Sequencer & FM/Marimba Oscillator State
    private var beatPhase: Double = 0.0
    private var stepIndex: Int = 0
    private var leadPhase: Double = 0.0
    private var leadModPhase: Double = 0.0
    private var chordPhase: Double = 0.0
    private var bassPhase: Double = 0.0
    private var bassModPhase: Double = 0.0
    private var tomPhase: Double = 0.0
    private var arpTick: Int = 0
    private var noiseSeed: UInt32 = 0x1991_D190

    private struct ActiveVoice {
        var freqStart: Double
        var freqEnd: Double
        var duration: Double
        var elapsed: Double = 0
        var phase: Double = 0
        var modPhase: Double = 0
        var gain: Double
        var noiseMix: Double
        var fmRatio: Double = 0.0
        var vibratoHz: Double = 0.0
    }

    private var voices: [ActiveVoice] = []

    private init() {
        startRealtimeEngine()
    }

    private func startRealtimeEngine() {
        let eng = AVAudioEngine()
        let outFmt = eng.outputNode.inputFormat(forBus: 0)
        let sr = outFmt.sampleRate > 8000 ? outFmt.sampleRate : 44100.0
        self.sampleRate = sr

        let renderFmt = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 2)!
        let node = AVAudioSourceNode(format: renderFmt) { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let count = Int(frameCount)
            self.renderFrames(count: count, sampleRate: sr) { idx, l, r in
                if abl.count >= 2 {
                    abl[0].mData?.assumingMemoryBound(to: Float.self)[idx] = l
                    abl[1].mData?.assumingMemoryBound(to: Float.self)[idx] = r
                } else if abl.count == 1 {
                    let ptr = abl[0].mData?.assumingMemoryBound(to: Float.self)
                    ptr?[idx * 2] = l
                    ptr?[idx * 2 + 1] = r
                }
            }
            return noErr
        }

        eng.attach(node)
        eng.connect(node, to: eng.mainMixerNode, format: renderFmt)
        do {
            #if os(iOS)
            try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try? AVAudioSession.sharedInstance().setActive(true)
            #endif
            try eng.start()
            self.engine = eng
            self.sourceNode = node
        } catch {
            self.engine = nil
        }
    }

    func stopRealtimeEngineForOfflineRender() {
        lock.lock()
        engine?.stop()
        engine = nil
        sourceNode = nil
        voices.removeAll()
        beatPhase = 0
        stepIndex = 0
        lock.unlock()
    }

    func syncSettings(_ s: PlayerSettings) {
        lock.lock()
        chipMode = s.audioChip
        musicVol = Double(s.musicVolume)
        sfxVol = Double(s.sfxVolume)
        lock.unlock()
    }

    func setTrack(_ track: MusicTrack) {
        lock.lock()
        if currentTrack != track {
            currentTrack = track
            stepIndex = 0
            beatPhase = 0
        }
        lock.unlock()
    }

    func setPaused(_ paused: Bool) {
        lock.lock()
        isPaused = paused
        lock.unlock()
    }

    func trigger(_ sfx: SoundEffect) {
        lock.lock()
        defer { lock.unlock() }
        if voices.count > 22 { voices.removeFirst(5) }

        switch sfx {
        case .clubSwing:
            voices.append(ActiveVoice(freqStart: 320, freqEnd: 115, duration: 0.11, gain: 0.28, noiseMix: 0.55, fmRatio: 1.5))

        case .clubBonk:
            // Classic Prehistorik hollow coconut/wood BONK + comical overtone!
            voices.append(ActiveVoice(freqStart: 240, freqEnd: 82, duration: 0.15, gain: 0.52, noiseMix: 0.30, fmRatio: 2.4))
            voices.append(ActiveVoice(freqStart: 520, freqEnd: 760, duration: 0.14, elapsed: -0.03, gain: 0.34, noiseMix: 0.0, fmRatio: 2.0))

        case .groundPound:
            voices.append(ActiveVoice(freqStart: 145, freqEnd: 28, duration: 0.38, gain: 0.62, noiseMix: 0.68, fmRatio: 1.5))
            voices.append(ActiveVoice(freqStart: 92, freqEnd: 24, duration: 0.44, gain: 0.45, noiseMix: 0.40, fmRatio: 1.0))

        case .dizzyStars:
            voices.append(ActiveVoice(freqStart: 380, freqEnd: 740, duration: 0.32, gain: 0.30, noiseMix: 0.0, fmRatio: 2.0, vibratoHz: 24.0))

        case .foodGobble:
            // Juicy chomp + happy rising chime
            voices.append(ActiveVoice(freqStart: 280, freqEnd: 560, duration: 0.09, gain: 0.35, noiseMix: 0.18, fmRatio: 2.0))
            voices.append(ActiveVoice(freqStart: 659.25, freqEnd: 987.77, duration: 0.15, elapsed: -0.06, gain: 0.34, noiseMix: 0.0, fmRatio: 2.0))

        case .megaFeastFull:
            let notes: [Double] = [523.25, 659.25, 783.99, 1046.50, 1318.51]
            for (i, n) in notes.enumerated() {
                voices.append(ActiveVoice(freqStart: n, freqEnd: n * 1.01, duration: 0.20, elapsed: -Double(i) * 0.07, gain: 0.36, noiseMix: 0.0, fmRatio: 2.0))
            }

        case .springBounce:
            voices.append(ActiveVoice(freqStart: 190, freqEnd: 780, duration: 0.28, gain: 0.38, noiseMix: 0.0, fmRatio: 1.5, vibratoHz: 18.0))

        case .jumpSlideWhistle:
            voices.append(ActiveVoice(freqStart: 330, freqEnd: 690, duration: 0.15, gain: 0.25, noiseMix: 0.02, fmRatio: 1.0))

        case .stoneCrack:
            voices.append(ActiveVoice(freqStart: 210, freqEnd: 48, duration: 0.26, gain: 0.48, noiseMix: 0.78, fmRatio: 2.3))

        case .rexRoar:
            voices.append(ActiveVoice(freqStart: 165, freqEnd: 52, duration: 0.62, gain: 0.58, noiseMix: 0.62, fmRatio: 1.4, vibratoHz: 16.0))
            voices.append(ActiveVoice(freqStart: 110, freqEnd: 38, duration: 0.66, gain: 0.44, noiseMix: 0.35, fmRatio: 0.5))

        case .spitRoastSizzle:
            voices.append(ActiveVoice(freqStart: 900, freqEnd: 420, duration: 0.34, gain: 0.34, noiseMix: 0.88, fmRatio: 3.0))
            voices.append(ActiveVoice(freqStart: 587.33, freqEnd: 880.0, duration: 0.18, elapsed: -0.08, gain: 0.32, noiseMix: 0.0, fmRatio: 2.0))

        case .gliderWhoosh:
            voices.append(ActiveVoice(freqStart: 260, freqEnd: 480, duration: 0.16, gain: 0.26, noiseMix: 0.42, fmRatio: 1.0))

        case .hurtOof:
            voices.append(ActiveVoice(freqStart: 360, freqEnd: 130, duration: 0.28, gain: 0.42, noiseMix: 0.15, fmRatio: 2.0, vibratoHz: 14.0))

        case .gemChime:
            voices.append(ActiveVoice(freqStart: 987.77, freqEnd: 987.77, duration: 0.11, gain: 0.30, noiseMix: 0.0, fmRatio: 3.0))
            voices.append(ActiveVoice(freqStart: 1479.98, freqEnd: 1479.98, duration: 0.22, elapsed: -0.07, gain: 0.32, noiseMix: 0.0, fmRatio: 3.0))

        case .menuMove:
            voices.append(ActiveVoice(freqStart: 520, freqEnd: 660, duration: 0.055, gain: 0.22, noiseMix: 0.0, fmRatio: 2.0))

        case .menuSelect:
            voices.append(ActiveVoice(freqStart: 523.25, freqEnd: 783.99, duration: 0.13, gain: 0.30, noiseMix: 0.0, fmRatio: 2.0))
        }
    }

    func renderOfflineInterleavedInt16(frames: Int, sampleRate: Double) -> [Int16] {
        var out = [Int16](repeating: 0, count: frames * 2)
        renderFrames(count: frames, sampleRate: sampleRate) { idx, l, r in
            let cl = max(-1.0, min(1.0, Double(l)))
            let cr = max(-1.0, min(1.0, Double(r)))
            out[idx * 2] = Int16(cl * 30500.0)
            out[idx * 2 + 1] = Int16(cr * 30500.0)
        }
        return out
    }

    private func nextNoise() -> Double {
        noiseSeed = noiseSeed &* 1664525 &+ 1013904223
        return Double(Int32(bitPattern: noiseSeed)) / Double(Int32.max)
    }

    private static func midiHz(_ m: Int) -> Double {
        guard m > 0 else { return 0 }
        return 440.0 * pow(2.0, Double(m - 69) / 12.0)
    }

    // 16-step original comical Stone Age melodies & slap-basslines (MIDI notes)
    private static let campfireLead: [Int] = [72, 76, 79, 84, 81, 79, 76, 72, 74, 77, 81, 79, 76, 74, 72, 67]
    private static let campfireBass: [Int] = [48, 55, 52, 55, 53, 60, 57, 60, 50, 57, 55, 59, 48, 55, 52, 48]

    private static let jungleLead:   [Int] = [76, 79, 84, 79, 81, 84, 79, 76, 74, 79, 83, 79, 76, 79, 74, 72]
    private static let jungleBass:   [Int] = [48, 48, 55, 52, 53, 53, 60, 57, 55, 55, 62, 59, 48, 52, 55, 48]

    private static let cavernLead:   [Int] = [69, 72, 76, 81, 79, 76, 72, 69, 71, 74, 79, 83, 81, 76, 72, 69]
    private static let cavernBass:   [Int] = [45, 52, 45, 52, 48, 55, 48, 55, 43, 50, 43, 50, 45, 52, 48, 45]

    private static let magmaLead:    [Int] = [74, 74, 77, 81, 79, 77, 74, 69, 72, 76, 79, 84, 81, 79, 76, 74]
    private static let magmaBass:    [Int] = [50, 50, 57, 50, 48, 48, 55, 48, 46, 46, 53, 46, 45, 52, 49, 45]

    private static let glacierLead:  [Int] = [79, 84, 88, 84, 86, 84, 79, 76, 77, 81, 84, 81, 79, 76, 74, 79]
    private static let glacierBass:  [Int] = [48, 55, 60, 55, 52, 55, 60, 55, 53, 57, 60, 57, 55, 59, 62, 55]

    private static let gliderLead:   [Int] = [76, 79, 83, 84, 88, 86, 84, 79, 81, 84, 88, 91, 88, 84, 79, 84]
    private static let gliderBass:   [Int] = [48, 55, 52, 55, 57, 64, 60, 57, 53, 60, 57, 60, 55, 62, 59, 55]

    private static let bossLead:     [Int] = [64, 67, 70, 71, 76, 75, 71, 67, 64, 67, 72, 71, 69, 67, 66, 64]
    private static let bossBass:     [Int] = [40, 40, 46, 47, 40, 40, 47, 43, 40, 40, 48, 47, 45, 43, 42, 40]

    private static let victoryLead:  [Int] = [72, 76, 79, 84, 84, 86, 88, 84, 81, 84, 79, 76, 74, 79, 84, 84]
    private static let victoryBass:  [Int] = [48, 52, 55, 60, 53, 57, 60, 53, 55, 59, 62, 55, 48, 55, 48, 48]

    private func trackData(_ t: MusicTrack) -> (stepsPerSec: Double, lead: [Int], bass: [Int]) {
        switch t {
        case .none:           return (6.0, Self.campfireLead, Self.campfireBass)
        case .campfireTitle:  return (7.5, Self.campfireLead, Self.campfireBass)
        case .palmJungle:     return (8.6, Self.jungleLead,   Self.jungleBass)
        case .amberCavern:    return (7.8, Self.cavernLead,   Self.cavernBass)
        case .magmaRidge:     return (9.2, Self.magmaLead,    Self.magmaBass)
        case .glacierPeak:    return (8.8, Self.glacierLead,  Self.glacierBass)
        case .gliderSkyBonus: return (9.8, Self.gliderLead,   Self.gliderBass)
        case .bossRex:        return (9.4, Self.bossLead,     Self.bossBass)
        case .feastVictory:   return (8.2, Self.victoryLead,  Self.victoryBass)
        }
    }

    private func renderFrames(count: Int, sampleRate sr: Double, write: (Int, Float, Float) -> Void) {
        lock.lock()
        defer { lock.unlock() }

        let dt = 1.0 / sr
        let (stepsPerSec, leadSeq, bassSeq) = trackData(currentTrack)
        let isAdLib = (chipMode == .retroAdLib)

        for i in 0..<count {
            var mixL = 0.0
            var mixR = 0.0

            if !isPaused && currentTrack != .none && musicVol > 0.001 {
                beatPhase += dt * stepsPerSec
                if beatPhase >= 1.0 {
                    beatPhase -= 1.0
                    stepIndex = (stepIndex + 1) % 16
                    tomPhase = 0.0
                }
                arpTick += 1

                let leadMidi = leadSeq[stepIndex]
                let bassMidi = bassSeq[stepIndex]
                let noteEnv = max(0.0, 1.0 - beatPhase * 0.78)

                // Voice 1: Tropical Marimba (Modern) vs 1991 AdLib YM3812 2-Op FM + Amiga Arp
                if leadMidi > 0 {
                    let arpSemi = isAdLib ? ([0, 4, 7, 12][(arpTick / 580) % 4]) : 0
                    let fLead = Self.midiHz(leadMidi + arpSemi)
                    leadPhase = fmod(leadPhase + fLead * dt, 1.0)
                    leadModPhase = fmod(leadModPhase + fLead * 2.0 * dt, 1.0)

                    let wave: Double
                    if isAdLib {
                        // Classic OPL2 / YM3812 glassy FM twang
                        let modIdx = 1.85 * max(0.15, 1.0 - beatPhase * 0.9)
                        wave = sin(leadPhase * .pi * 2.0 + modIdx * sin(leadModPhase * .pi * 2.0))
                    } else {
                        // Bouncy woody Tropical Marimba + bright mallet transient
                        let malletTransient = exp(-beatPhase * 7.5) * sin(leadPhase * .pi * 8.0) * 0.42
                        let body = sin(leadPhase * .pi * 2.0) * 0.78 + sin(leadPhase * .pi * 4.0) * 0.18
                        wave = body + malletTransient
                    }
                    mixL += wave * noteEnv * 0.16 * musicVol
                    mixR += wave * noteEnv * 0.13 * musicVol
                }

                // Voice 2: Offbeat Island Brass / AdLib Square Harmony
                if leadMidi > 0 && (stepIndex % 2 == 1) {
                    let fChord = Self.midiHz(leadMidi - 5)
                    chordPhase = fmod(chordPhase + fChord * dt, 1.0)
                    let cw: Double
                    if isAdLib {
                        cw = chordPhase < 0.38 ? 0.65 : -0.65
                    } else {
                        cw = sin(chordPhase * .pi * 2.0) * 0.65 + sin(chordPhase * .pi * 6.0) * 0.25
                    }
                    mixL += cw * noteEnv * 0.08 * musicVol
                    mixR += cw * noteEnv * 0.11 * musicVol
                }

                // Voice 3: Funky Slap-Bass (Modern) vs AdLib FM Synth Bass
                if bassMidi > 0 {
                    let fBass = Self.midiHz(bassMidi)
                    bassPhase = fmod(bassPhase + fBass * dt, 1.0)
                    bassModPhase = fmod(bassModPhase + fBass * dt, 1.0)
                    let bassEnv = max(0.0, 1.0 - beatPhase * 0.84)
                    let bw: Double
                    if isAdLib {
                        bw = sin(bassPhase * .pi * 2.0 + 1.4 * sin(bassModPhase * .pi * 2.0))
                    } else {
                        let slapPop = exp(-beatPhase * 6.0) * sin(bassPhase * .pi * 6.0) * 0.35
                        bw = sin(bassPhase * .pi * 2.0) * 0.80 + slapPop
                    }
                    mixL += bw * bassEnv * 0.18 * musicVol
                    mixR += bw * bassEnv * 0.18 * musicVol
                }

                // Voice 4: Prehistoric Bongo / Log-Tom + Shaker Groove
                if beatPhase < 0.24 {
                    let pNorm = beatPhase / 0.24
                    if stepIndex % 4 == 0 {
                        // Low Stone-Age Log Drum Kick
                        let fTom = 135.0 - 75.0 * pNorm
                        tomPhase = fmod(tomPhase + fTom * dt, 1.0)
                        let tom = sin(tomPhase * .pi * 2.0) * (1.0 - pNorm) * 0.15 * musicVol
                        mixL += tom
                        mixR += tom
                    } else if stepIndex % 2 == 1 {
                        // Crisp Shaker / Bongo Rim
                        let n = nextNoise() * (1.0 - pNorm) * 0.065 * musicVol
                        mixL += n
                        mixR += n
                    }
                }
            }

            // Active Cartoon Sound Effects
            if !voices.isEmpty && sfxVol > 0.001 {
                var vIdx = voices.count - 1
                while vIdx >= 0 {
                    voices[vIdx].elapsed += dt
                    let el = voices[vIdx].elapsed
                    let dur = voices[vIdx].duration
                    if el >= dur {
                        voices.remove(at: vIdx)
                    } else if el >= 0 {
                        let t = el / max(0.001, dur)
                        let baseF = voices[vIdx].freqStart + (voices[vIdx].freqEnd - voices[vIdx].freqStart) * t
                        let vib = voices[vIdx].vibratoHz > 0 ? (1.0 + 0.09 * sin(el * voices[vIdx].vibratoHz * .pi * 2.0)) : 1.0
                        let freq = max(20.0, baseF * vib)
                        voices[vIdx].phase = fmod(voices[vIdx].phase + freq * dt, 1.0)

                        let tone: Double
                        if isAdLib || voices[vIdx].fmRatio > 0 {
                            let ratio = max(1.0, voices[vIdx].fmRatio)
                            voices[vIdx].modPhase = fmod(voices[vIdx].modPhase + freq * ratio * dt, 1.0)
                            let idxMod = (isAdLib ? 1.8 : 0.9) * (1.0 - t * 0.6)
                            tone = sin(voices[vIdx].phase * .pi * 2.0 + idxMod * sin(voices[vIdx].modPhase * .pi * 2.0))
                        } else {
                            tone = sin(voices[vIdx].phase * .pi * 2.0)
                        }

                        let nz = nextNoise()
                        let mixed = tone * (1.0 - voices[vIdx].noiseMix) + nz * voices[vIdx].noiseMix
                        let amp = (1.0 - t) * voices[vIdx].gain * sfxVol * 0.58
                        mixL += mixed * amp
                        mixR += mixed * amp
                    }
                    vIdx -= 1
                }
            }

            let outL = Float(tanh(mixL))
            let outR = Float(tanh(mixR))
            write(i, outL, outR)
        }
    }
}
