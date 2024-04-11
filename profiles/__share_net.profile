# Allow network namespace and mount relevant files
# Use this together with __namespaces or __namespaces_ipc
--share-net
--ro-bind /etc/resolv.conf /etc/resolv.conf
--ro-bind /etc/ssl /etc/ssl
