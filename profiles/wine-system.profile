# Mount all the relevant stuff for running system Wine installation in the box
# Use after wine.profile
--ro-bind /usr/lib/wine /usr/lib/wine
--ro-bind /usr/share/wine /usr/share/wine
--ro-bind /usr/share/fonts /usr/share/fonts
--ro-bind /etc/fonts /etc/fonts
