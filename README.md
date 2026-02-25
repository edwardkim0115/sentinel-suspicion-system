Sentinel Suspicion Demo (Godot)
A small Godot 4.x project showcasing a "suspicion-based" NPC behavior loop:
WANDER: the sentinel roams via jittered lattice waypoints
Suspicion meter: fills when the sentinel has line-of-sight within a view cone
PURSUE: triggers when suspicion hits 100%
INVESTIGATE: moves to last-seen position when LOS breaks
TAG + knockback: close-range tag with a small cooldown
Run
Open in Godot 4.x
Press Play
Controls
Arrow keys: move
Enter/Space: toggle HUD
Why this is useful
This is a compact prototype for state-driven AI with:
view cones + LOS gating (raycast)
suspicion accumulation/decay
last-known-position investigation
small “interaction” (tag + knockback) with cooldown
