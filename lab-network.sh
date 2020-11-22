#! /bin/bash

function network_define () {
	local value_network_file="$value_parameters"
	virsh net-define "$value_network_file"
}

function network_undefine () {
	local value_network_name="$value_parameters"
	virsh net-undefine "$value_network_name"
}

function network_start () {
	local value_network_name="$value_parameters"
	virsh net-start "$value_network_name"
}

function network_stop () {
	local value_network_name="$value_parameters"
	virsh net-destroy "$value_network_name"
}

function network_info () {
	local value_network_name="$value_parameters"
	virsh net-list --all | grep "$value_network_name"
	ip addr show "$value_network_name"
}

function network_autostart () {
	local value_network_name="$value_parameters"
	virsh net-autostart "$value_network_name"
}

function network_disable_autostart () {
	local value_network_name="$value_parameters"
	virsh net-autostart "$value_network_name" --disable
}

function tear_up () {
	local value_network_name="$value_parameters"
	network_start "$value_network_name"
}

function tear_down () {
	local value_network_name="$value_parameters"
	network_stop "$value_network_name"
}



function main () {
	local value_action="$action"
	local value_parameters="$parameters"
	case "$value_action" in
		"--define")
			network_define "$value_parameters"
		;;
		"--undefine")
			network_undefine "$value_parameters"
		;;
		"--up")
			tear_up "$value_parameters"
		;;
		"--down")
			tear_down "$value_parameters"
		;;
		"--autostart")
			network_autostart "$value_parameters"
		;;
		"--no-autostart")
			network_disable_autostart "$value_parameters"
		;;
		"--info")
			network_info "$value_parameters"
		;;
		*)
		printf "$0 - Option \"$value_action\" was not recognized...\n"
		printf "  --define       : Define network [XML_FILE]\n"
		printf "  --undefine     : Undefine network [NAME]\n"
		printf "  --up           : Bring network up [NAME]\n"
		printf "  --down         : Bring network down [NAME]\n"
		printf "  --autostart    : Enable network [NAME] auto-start after host boot\n"
		printf "  --no-autostart : Disable network [NAME] auto-start after host boot\n"
		printf "  --info         : Display network information [NULL] | [NAME]\n"
		;;
	esac
}

action="$1"
parameters="${*: 2}"

main "$action" "$parameters"
