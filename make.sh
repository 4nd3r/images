#!/bin/sh -e

_make_sysusers()
(
    printf 'g %s %s\n' "$_group" "$_gid"
    printf 'u %s %s:%s %s %s /bin/bash\n' "$_user" "$_uid" "$_gid" "$_user" "$_home"
    printf 'm %s sudo\n' "$_user"
)

_make_nspawn()
(
    echo '[Files]'
    for _ in \
        "Bind=$_bind:$_home" \
        "Bind=$_home/.kube" \
        "Bind=$_home/Desktop" \
        "Bind=$_home/Downloads" \
        "Bind=$_home/Repos" \
        "BindReadOnly=$_home/.bashrc" \
        "BindReadOnly=$_home/.profile" \
        "BindReadOnly=$_home/.tmux.conf"
    do
        if [ -e "$( echo "$_" | cut -d= -f2 | sed 's/:.*//' )" ]
        then
            echo "$_"
        fi
    done
    echo ''
    echo '[Network]'
    echo 'VirtualEthernet=yes'
    echo ''
    echo '[Exec]'
    echo 'SystemCallFilter=add_key keyctl bpf'
    echo 'PrivateUsers=no'
)

_make_service()
(
    echo '[Service]'
    echo 'Restart=on-failure'
    echo 'RestartSec=3'
    echo 'DevicePolicy=auto'
    echo 'DeviceAllow='
)

_root()
(
    if [ -n "$RUN0" ]
    then
        run0 "$@"
    else
        sudo "$@"
    fi
)

_make_build()
(
    test -n "$1"
    mkdir -vp "$( dirname "$_sysusers" )"
    _make_sysusers > "$_sysusers"
    mkosi -f --debug-shell --image-id "$_name" --profile "$1"
)

_make_install()
(
    mkdir -vp "$_bind"
    _root mkdir -vp "$( dirname "$_nspawn" )"
    _make_nspawn | _root tee "$_nspawn" > /dev/null
    _root mkdir -vp "$( dirname "$_service" )"
    _make_service | _root tee "$_service" > /dev/null
    _root importctl -m import-tar "$_image" "$_name"
    _root systemctl daemon-reload
    _root machinectl start "$_name"
)

_make_uninstall()
(
    _root machinectl terminate "$_name"
    sleep 3
    _root machinectl remove "$_name"
    _root rm -vrf "$_nspawn" "$( dirname "$_service" )"
    _root systemctl daemon-reload
)

if [ -n "$1" ] && [ -n "$2" ]
then
    _make="$1"
    _name="$2"
    shift 2
    _uid="$( id -u )"
    _user="$USER"
    _gid="$( id -g )"
    _group="$( id -gn )"
    _home="$HOME"
    _image="mkosi.output/$_name.tar"
    _sysusers='mkosi.extra/etc/sysusers.d/extra.conf'
    _bind="$_home/.nspawn/$_name"
    _nspawn="/etc/systemd/nspawn/$_name.nspawn"
    _service="/etc/systemd/system/systemd-nspawn@$_name.service.d/extra.conf"
    "_make_$_make" "$@"
fi
