#!/bin/sh -eu

_mkosi()
(
    mkosi -f --debug-shell --image-id "$_image" "$@"
)

_root()
(
    sudo "$@"
)

_make_sysusers()
(
    _uid="$( id -u )"
    _gid="$( id -g )"
    _group="$( id -gn )"
    printf 'g %s %s\n' "$_group" "$_gid"
    printf 'u %s %s:%s %s %s /bin/bash\n' "$USER" "$_uid" "$_gid" "$USER" "$HOME"
    printf 'm %s sudo\n' "$USER"
)

_make_build()
(
    _sysusers='mkosi.extra/etc/sysusers.d/extra.conf'
    mkdir -vp "$( dirname "$_sysusers" )"
    _make_sysusers > "$_sysusers"
    _mkosi
)

_make_summary()
(
    _mkosi summary
)

_make_nspawn()
(
    echo '[Files]'
    for l in \
        "Bind=$_bind:$HOME" \
        "Bind=$HOME/.kube" \
        "Bind=$HOME/Desktop" \
        "Bind=$HOME/Downloads" \
        "Bind=$HOME/Repos" \
        "BindReadOnly=$HOME/.bashrc" \
        "BindReadOnly=$HOME/.profile" \
        "BindReadOnly=$HOME/.tmux.conf"
    do
        if [ -e "$( echo "$l" | cut -d= -f2 | sed 's/:.*//' )" ]
        then
            echo "$l"
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

_make_install()
(
    mkdir -vp "$_bind"
    _root mkdir -vp "$( dirname "$_nspawn" )"
    _make_nspawn | _root tee "$_nspawn" > /dev/null
    _root mkdir -vp "$( dirname "$_service" )"
    _make_service | _root tee "$_service" > /dev/null
    _root importctl -m import-tar "mkosi.output/$_image.tar" "$_machine"
    _root systemctl daemon-reload
    _root machinectl start "$_machine"
)

_make_uninstall()
(
    _root machinectl terminate "$_machine"
    sleep 3
    _root machinectl remove "$_machine"
    _root rm -vrf "$_nspawn" "$( dirname "$_service" )"
    _root systemctl daemon-reload
)

if [ -n "$1" ] && [ -n "$2" ]
then
    _make="$1"
    _image="$2"
    case "$_make" in
        install|uninstall)
            _machine="$3"
            _bind="$HOME/.nspawn/$_machine"
            _nspawn="/etc/systemd/nspawn/$_machine.nspawn"
            _service="/etc/systemd/system/systemd-nspawn@$_machine.service.d/extra.conf"
        ;;
    esac
    "_make_$_make"
fi
