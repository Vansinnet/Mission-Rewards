local function loc(en, sv)
    return { en = en, sv = sv }
end

return {
    mod_name = loc("Mission Rewards", "Mission Rewards"),
    mod_description = loc("Shows each mission's XP, Ordo Dockets, and distance efficiency on the mission board, including Special Assignments.", "Visar XP, Ordo Dockets och distanseffektivitet för varje uppdrag på mission boarden, inklusive Special Assignments."),
    show_xp = loc("Show XP", "Visa XP"),
    show_xp_tooltip = loc("Shows the main mission XP, including circumstance rewards but excluding side objectives.", "Visar huvuduppdragets XP inklusive circumstance-belöningar, men utan sidouppdrag."),
    show_dockets = loc("Show Ordo Dockets", "Visa Ordo Dockets"),
    show_dockets_tooltip = loc("Shows the main mission Ordo Dockets, including circumstance rewards but excluding side objectives.", "Visar huvuduppdragets Ordo Dockets inklusive circumstance-belöningar, men utan sidouppdrag."),
    show_efficiency = loc("Show XP per metre", "Visa XP per meter"),
    show_efficiency_tooltip = loc("Shows main mission XP divided by the map's main-path length. Higher is more efficient by distance.", "Visar huvuduppdragets XP delat med kartans main-path-längd. Högre är effektivare per distans."),
    show_dockets_efficiency = loc("Show Ordo Dockets per metre", "Visa Ordo Dockets per meter"),
    show_dockets_efficiency_tooltip = loc("Shows main mission Ordo Dockets divided by the map's main-path length. Higher is more efficient by distance.", "Visar huvuduppdragets Ordo Dockets delat med kartans main-path-längd. Högre är effektivare per distans."),
    show_hub_xp_bar = loc("Show XP bar in the Mourningstar", "Visa XP-bar i Mourningstar"),
    show_hub_xp_bar_tooltip = loc("Shows the character's total level and progress towards the next level beside the portrait in the Mourningstar.", "Visar karaktärens totalnivå och framsteg mot nästa nivå bredvid porträttet i Mourningstar."),
}
