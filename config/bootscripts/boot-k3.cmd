bootpart=1:1
bootdir=
finduuid=part uuid \${boot} 1:2 uuid
if test "${fdtfile}" != "ti/k3-am62l3-badge.dtb"; then
    name_rd=uInitrd
    get_rd_mmc=load mmc ${bootpart} ${rdaddr} ${bootdir}/${name_rd}
fi

uenvcmd=run get_rd_${boot}; env set rd_spec ${rdaddr}:${filesize}; setexpr fdtfile sub ti/ti ti; run bootcmd_ti_mmc

optargs=vt.global_cursor_default=0

if test "${fdtfile}" = "ti/k3-am62l3-badge.dtb"; then
    setenv name_overlays ti/k3-am62l3-evm-eink-gdey042t81.dtbo
fi
