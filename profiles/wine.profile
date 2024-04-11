# Profile to run Wine
# To use your system Wine installation, also include wine-system.profile
# To use a standalone Wine build, you can specify it in bwrap args like this: `--ro-bind /path/to/wine /usr/local`
# To use winetricks, include __share_net and wine-winetricks
# This profile is created for xorg and nvidia gpu 
!include __basic
!include __home
# Namespaces: keep IPC - https://github.com/jessfraz/dockerfiles/issues/359
--unshare-user-try 
--unshare-pid 
--unshare-net 
--unshare-uts 
--unshare-cgroup-try
# Needed in graphic apps
--dir /run/user/"$(id -u)"
# Display Manager
--ro-bind /tmp/.X11-unix/X0 /tmp/.X11-unix/X0
--ro-bind "$XAUTHORITY" "$XAUTHORITY"
# --ro-bind /run/user/${UID}/wayland-0 /run/user/${UID}/wayland-0
--setenv DISPLAY "$DISPLAY" 
# Nvidia and Vulkan
--dev-bind /dev/nvidia0 /dev/nvidia0
--dev-bind /dev/nvidiactl /dev/nvidiactl
--dev-bind /dev/nvidia-modeset /dev/nvidia-modeset
--dev-bind /dev/dri /dev/dri # ?
--ro-bind /usr/share/nvidia /usr/share/nvidia
--ro-bind /sys/devices/pci0000:00 /sys/devices/pci0000:00 # try
--ro-bind /sys/bus/pci/devices /sys/bus/pci/devices # try
--ro-bind /usr/share/vulkan /usr/share/vulkan # try
--ro-bind /sys/class/drm /sys/class/drm # try
--ro-bind /etc/vulkan /etc/vulkan # try
--ro-bind /usr/share/drirc.d /usr/share/drirc.d # try
--bind "${HOME}/.cache/nvidia" "${HOME}/.cache/nvidia" 
--bind-try "${HOME}/.nvidia-aftermath-rc" "${HOME}/.nvidia-aftermath-rc"
# Not sure
--dev-bind /dev/shm /dev/shm
--ro-bind /run/user/$UID/bus /run/user/$UID/bus
--ro-bind /sys/dev/char /sys/dev/char
--ro-bind /sys/devices /sys/devices
--ro-bind /run/dbus /run/dbus
--setenv DBUS_SESSION_BUS_ADDRESS "unix:path=/run/user/$UID/bus" # try
--setenv XDG_RUNTIME_DIR "/run/user/$UID" # try
--ro-bind /etc/selinux /etc/selinux
# Sound
--ro-bind /run/user/${UID}/pulse /run/user/${UID}/pulse
# --ro-bind /run/user/${UID}/pipewire-0 /run/user/${UID}/pipewire-0
# Input device for gamepad support.
--ro-bind /sys/class/input /sys/class/input
--dev-bind /dev/input /dev/input
