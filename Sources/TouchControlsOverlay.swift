#if os(iOS)
import UIKit
import SpriteKit

@MainActor
final class TouchControlsOverlay: UIView {
    weak var gameScene: GameScene?

    private let stickBase = UIView()
    private let stickKnob = UIView()
    private let clubBtn = UIButton(type: .system)
    private let jumpBtn = UIButton(type: .system)
    private let pausePill = UIButton(type: .system)
    private let eraPill = UIButton(type: .system)
    private let chipPill = UIButton(type: .system)

    private var activeStickTouch: UITouch?
    private var stickOrigin: CGPoint = .zero
    private let stickRadius: CGFloat = 56

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        backgroundColor = .clear
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        stickBase.backgroundColor = UIColor(white: 0.08, alpha: 0.44)
        stickBase.layer.borderColor = UIColor(red: 1.0, green: 0.82, blue: 0.25, alpha: 0.72).cgColor
        stickBase.layer.borderWidth = 2.2
        stickBase.layer.cornerRadius = stickRadius
        stickBase.isUserInteractionEnabled = false
        addSubview(stickBase)

        stickKnob.backgroundColor = UIColor(red: 1.0, green: 0.82, blue: 0.25, alpha: 0.84)
        stickKnob.layer.cornerRadius = 23
        stickKnob.isUserInteractionEnabled = false
        addSubview(stickKnob)

        // CLUB (Crimson / Volcano Orange)
        configureArcadeButton(clubBtn, title: "CLUB", bg: UIColor(red: 0.93, green: 0.27, blue: 0.18, alpha: 0.82))
        clubBtn.addTarget(self, action: #selector(onClubDown), for: .touchDown)
        clubBtn.addTarget(self, action: #selector(onClubUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        addSubview(clubBtn)

        // JUMP (Emerald / Tropical Blue-Green)
        configureArcadeButton(jumpBtn, title: "JUMP", bg: UIColor(red: 0.14, green: 0.74, blue: 0.52, alpha: 0.82))
        jumpBtn.addTarget(self, action: #selector(onJumpDown), for: .touchDown)
        jumpBtn.addTarget(self, action: #selector(onJumpUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        addSubview(jumpBtn)

        configureTopPill(pausePill, title: "PAUSE")
        pausePill.addTarget(self, action: #selector(onPause), for: .touchUpInside)
        addSubview(pausePill)

        configureTopPill(eraPill, title: "ERA")
        eraPill.addTarget(self, action: #selector(onEra), for: .touchUpInside)
        addSubview(eraPill)

        configureTopPill(chipPill, title: "CHIP")
        chipPill.addTarget(self, action: #selector(onChip), for: .touchUpInside)
        addSubview(chipPill)
    }

    private func configureArcadeButton(_ btn: UIButton, title: String, bg: UIColor) {
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont.monospacedSystemFont(ofSize: 15, weight: .black)
        btn.backgroundColor = bg
        btn.layer.borderColor = UIColor(red: 1.0, green: 0.85, blue: 0.35, alpha: 0.88).cgColor
        btn.layer.borderWidth = 2.4
    }

    private func configureTopPill(_ btn: UIButton, title: String) {
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(UIColor(red: 1.0, green: 0.85, blue: 0.35, alpha: 1.0), for: .normal)
        btn.titleLabel?.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .bold)
        btn.backgroundColor = UIColor(red: 0.10, green: 0.08, blue: 0.07, alpha: 0.84)
        btn.layer.borderColor = UIColor(red: 1.0, green: 0.85, blue: 0.35, alpha: 0.70).cgColor
        btn.layer.borderWidth = 1.6
        btn.layer.cornerRadius = 14
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let safe = safeAreaInsets
        let w = bounds.width
        let h = bounds.height

        let cx = max(94, safe.left + 76)
        let cy = h - max(90, safe.bottom + 78)
        stickOrigin = CGPoint(x: cx, y: cy)
        stickBase.frame = CGRect(x: cx - stickRadius, y: cy - stickRadius, width: stickRadius * 2, height: stickRadius * 2)
        if activeStickTouch == nil {
            stickKnob.frame = CGRect(x: cx - 23, y: cy - 23, width: 46, height: 46)
        }

        let clubSize: CGFloat = 78
        clubBtn.frame = CGRect(x: w - max(100, safe.right + 90), y: h - max(100, safe.bottom + 88), width: clubSize, height: clubSize)
        clubBtn.layer.cornerRadius = clubSize * 0.5

        let jumpSize: CGFloat = 72
        jumpBtn.frame = CGRect(x: clubBtn.frame.minX - jumpSize - 18, y: clubBtn.frame.minY + 10, width: jumpSize, height: jumpSize)
        jumpBtn.layer.cornerRadius = jumpSize * 0.5

        let topY = max(12, safe.top + 8)
        pausePill.frame = CGRect(x: max(16, safe.left + 14), y: topY, width: 74, height: 28)
        chipPill.frame = CGRect(x: w - max(16, safe.right + 14) - 68, y: topY, width: 68, height: 28)
        eraPill.frame = CGRect(x: chipPill.frame.minX - 74, y: topY, width: 68, height: 28)
    }

    func syncVisibilityWithScene() {
        guard let sc = gameScene else { return }
        let showGameplay = sc.isActionArcadePhase
        stickBase.isHidden = !showGameplay
        stickKnob.isHidden = !showGameplay
        clubBtn.isHidden = !showGameplay
        jumpBtn.isHidden = !showGameplay
        pausePill.isHidden = !showGameplay
        eraPill.isHidden = !showGameplay
        chipPill.isHidden = !showGameplay

        if sc.mode == .gliderBonus {
            clubBtn.setTitle("FLAP", for: .normal)
            jumpBtn.setTitle("BOOST", for: .normal)
        } else {
            clubBtn.setTitle("CLUB", for: .normal)
            jumpBtn.setTitle("JUMP", for: .normal)
        }
    }

    // Pass non-control touches straight through to SKView on menus & modals!
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let sc = gameScene, sc.isActionArcadePhase else {
            return nil
        }
        for sub in [clubBtn, jumpBtn, pausePill, eraPill, chipPill] where !sub.isHidden {
            let p = sub.convert(point, from: self)
            if sub.bounds.insetBy(dx: -8, dy: -8).contains(p) {
                return sub
            }
        }
        if !stickBase.isHidden && point.x < bounds.width * 0.38 && point.y > bounds.height * 0.42 {
            return self
        }
        return nil
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard activeStickTouch == nil, let t = touches.first else { return }
        activeStickTouch = t
        updateStick(with: t.location(in: self))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let active = activeStickTouch, touches.contains(active) else { return }
        updateStick(with: active.location(in: self))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let active = activeStickTouch, touches.contains(active) {
            resetStick()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let active = activeStickTouch, touches.contains(active) {
            resetStick()
        }
    }

    private func updateStick(with pt: CGPoint) {
        let dx = pt.x - stickOrigin.x
        let dy = pt.y - stickOrigin.y
        let dist = hypot(dx, dy)
        let clamped = min(stickRadius, dist)
        let angle = atan2(dy, dx)
        let kx = stickOrigin.x + cos(angle) * clamped
        let ky = stickOrigin.y + sin(angle) * clamped
        stickKnob.center = CGPoint(x: kx, y: ky)

        TouchInputState.shared.moveDX = (clamped > 8) ? (cos(angle) * (clamped / stickRadius)) : 0
        // UIKit Y is downward, SpriteKit Y is upward -> invert dy for Jump/Ground-Pound!
        TouchInputState.shared.moveDY = (clamped > 8) ? (-sin(angle) * (clamped / stickRadius)) : 0
    }

    private func resetStick() {
        activeStickTouch = nil
        stickKnob.center = stickOrigin
        TouchInputState.shared.moveDX = 0
        TouchInputState.shared.moveDY = 0
    }

    @objc private func onClubDown() {
        TouchInputState.shared.primaryHeld = true
        TouchInputState.shared.primaryJustPressed = true
        HapticsManager.lightImpact()
    }

    @objc private func onClubUp() {
        TouchInputState.shared.primaryHeld = false
    }

    @objc private func onJumpDown() {
        TouchInputState.shared.secondaryHeld = true
        TouchInputState.shared.secondaryJustPressed = true
        HapticsManager.tap()
    }

    @objc private func onJumpUp() {
        TouchInputState.shared.secondaryHeld = false
    }

    @objc private func onPause() { gameScene?.togglePauseFromUI() }
    @objc private func onEra()   { gameScene?.cycleVisualTheme() }
    @objc private func onChip()  { gameScene?.cycleAudioChip() }
}
#endif
