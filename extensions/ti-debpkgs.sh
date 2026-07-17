function post_repo_customize_image__100_install_ti_packages() {
	# Check if OS suite is supported by TI debian package repo
	local http_code=$(curl -s -o /dev/null -w "%{http_code}" https://raw.githubusercontent.com/TexasInstruments/ti-debpkgs/main/dists/${RELEASE}/InRelease)

	if [[ "${http_code}" == "200" ]]; then
		# Get the sources file
		run_host_command_logged "mkdir -p \"$SDCARD/tmp\""
		run_host_command_logged "wget -qO $SDCARD/tmp/ti-debpkgs.sources https://raw.githubusercontent.com/TexasInstruments/ti-debpkgs/main/ti-debpkgs.sources"

		# Update suite in source file
		chroot_sdcard "sed -i 's/Suites: .*/Suites: ${RELEASE}/g' /tmp/ti-debpkgs.sources"

		# Copy updated sources file into chroot
		chroot_sdcard "cp /tmp/ti-debpkgs.sources /etc/apt/sources.list.d/ti-debpkgs.sources"

		# Clean up inside the chroot
		chroot_sdcard "rm -f /tmp/ti-debpkgs.sources"

		chroot_sdcard "mkdir -p /etc/apt/preferences.d/"
		run_host_command_logged "cp \"$SRC/packages/bsp/ti/ti-debpkgs/ti-debpkgs\" \"$SDCARD/etc/apt/preferences.d/\""

		# Remove excluded packages
		if [[ ${#TI_PACKAGES_REMOVE[@]} -gt 0 ]] ; then
			for rm_pkg in "${TI_PACKAGES_REMOVE[@]}" ; do
				for i in "${!TI_PACKAGES[@]}" ; do
					[[ "${TI_PACKAGES[$i]}" == "${rm_pkg}" ]] && unset "TI_PACKAGES[$i]"
				done
			done
			TI_PACKAGES=("${TI_PACKAGES[@]}")
		fi

		# Install packages
		if [[ ${#TI_PACKAGES[@]} -gt 0 ]] ; then
			do_with_retries 3 chroot_sdcard_apt_get_update
			do_with_retries 3 chroot_sdcard_apt_get -o "Dpkg::Options::=--force-overwrite" --no-install-recommends install "${TI_PACKAGES[@]}"
		fi

	elif [[ "${http_code}" == "404" ]]; then
		local valid_suites=$(curl -s "https://github.com/TexasInstruments/ti-debpkgs/tree/main/dists" | grep -oP '(?<=/ti-debpkgs/tree/main/dists/)[^"]+' | grep -v "^stable$" | sort -u | tr '\n' ' ')
		exit_with_error "Detected OS suite ${RELEASE} is not supported by TI debian package repo. Exiting!" "Valid OS suites are: ${valid_suites}"
	else
		exit_with_error "Failed to access TI debian package repo (HTTP code ${http_code}). Exiting!"
	fi
}

function post_repo_customize_image__200_enable_services() {
	run_host_command_logged "mkdir -p $DEST/lib/systemd/system/"
	run_host_command_logged "cp -v $SRC/packages/bsp/ti/weston/weston.socket $SDCARD/lib/systemd/system/weston.socket"
	run_host_command_logged "cp -v $SRC/packages/bsp/ti/weston/weston.service $SDCARD/lib/systemd/system/weston.service"
	run_host_command_logged "cp -v $SRC/packages/bsp/ti/weston/weston $SDCARD/etc/default/weston"

	chroot_sdcard "systemctl enable weston" || display_alert "systemctl enable failed"

	chroot_sdcard "systemctl disable NetworkManager" || display_alert "systemctl disable for NetworkManager failed"
	chroot_sdcard "systemctl disable wpa_supplicant.service" || display_alert "systemctl disable for wpa_supplicant failed"
	chroot_sdcard "systemctl enable NetworkManager" || display_alert "systemctl enable for NetworkManager failed"
}

function post_repo_customize_image__300_activate_dkms() {
    if [[ ${GPU_SUPPORT} == "yes" ]] ; then
        kernel_version=$(grab_version "${SRC}/cache/sources/${LINUXSOURCEDIR}")
        kernel_version_family="${kernel_version}-${BRANCH}-${LINUXFAMILY}"
        chroot_sdcard "dkms autoinstall --verbose --kernelver ${kernel_version_family}"
    fi
}

function post_repo_customize_image__400_rm_aptconf() {
    display_alert "Removing apt.conf file"
    run_host_command_logged "rm -f ${SDCARD}/etc/apt/apt.conf"
    chroot_sdcard_apt_get_update || true
    display_alert "Removed apt.conf"
}
