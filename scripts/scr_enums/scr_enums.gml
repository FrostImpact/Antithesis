// Shared IDs live here so UI, combat and map authoring never communicate with
// unexplained integers or mutable state strings.
enum UiAction {
    None = -1,
    Target,
    Charge,
    Move,
    AbilityDoubleTap,
    AbilityShockBolts,
    AbilityOverloaded,
    AbilityMove,
    Spawn,
    Count
}

enum TowerTargetMode {
    First,
    Strongest,
    Nearest,
    Count
}

enum TowerAbility {
    DoubleTap,
    ShockBolts,
    Overloaded,
    Count
}

enum TowerChargeState {
    Ready,
    Charging,
    Burst,
    Recovery
}

enum GlossaryTerm {
    None = -1,
    GreatPowers,
    Charge,
    Lock,
    Count
}

enum MapRegionKind {
    Surface,
    Void
}
