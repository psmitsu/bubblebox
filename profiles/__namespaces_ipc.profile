# Create new linux namespaces for the box
# Keep the IPC profile, which is needed for graphics
# Can share network namespaces back: include __share_net after this
--unshare-user-try 
--unshare-pid 
--unshare-uts 
--unshare-cgroup-try
--unshare-net 
