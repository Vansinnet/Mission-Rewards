return {
    run = function()
        fassert(rawget(_G, "new_mod"), "`Mission Rewards` failed loading DMF.")
        new_mod("Mission Rewards", {
            mod_script = "Mission Rewards/scripts/mods/Mission Rewards/Mission Rewards",
            mod_data = "Mission Rewards/scripts/mods/Mission Rewards/Mission Rewards_data",
            mod_localization = "Mission Rewards/scripts/mods/Mission Rewards/Mission Rewards_localization",
        })
    end,
    packages = {},
}
