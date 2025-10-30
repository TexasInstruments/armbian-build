bootpart=1:1
bootdir=
finduuid=part uuid \${boot} 1:2 uuid
name_rd=uInitrd
get_rd_mmc=load mmc ${bootpart} ${rdaddr} ${bootdir}/${name_rd}

uenvcmd=run get_rd_${boot}; env set rd_spec ${rdaddr}:${filesize}; setexpr fdtfile sub ti/ti ti; run bootcmd_ti_mmc

optargs=vt.global_cursor_default=0

if test "${board_name}" = "am62lx"; then
    name_overlays=ti/k3-am62l3-evm-epaper.dtbo ti/k3-am62l3-evm-m2-cc3351.dtbo
fi
