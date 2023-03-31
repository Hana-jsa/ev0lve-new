press_me = gui.button("SetTagInvis", "scripts.elements_a", "invisible tag")


press_me:add_callback(function()
    tag = "\n"
    utils.set_clan_tag("⠀"..tag)
end)