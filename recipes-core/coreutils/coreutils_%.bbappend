do_install_append_sdxpoorwills(){
	mv ${D}${base_bindir}/cp.coreutils ${D}/cp.coreutils;
	mv ${D}${bindir}/chcon ${D}/chcon;
	rm -rf ${D}${base_bindir};
	rm -rf ${D}/usr;
	install -d ${D}${base_bindir};
	install -d ${D}${bindir};
	mv ${D}/cp.coreutils ${D}${base_bindir}/cp.coreutils;
	mv ${D}/chcon ${D}${bindir}/chcon;
}
do_install_append_sdxprairie(){
        mv ${D}${base_bindir}/cp.coreutils ${D}/cp.coreutils;
        mv ${D}${bindir}/chcon ${D}/chcon;
        rm -rf ${D}${base_bindir};
        rm -rf ${D}/usr;
        install -d ${D}${base_bindir};
        install -d ${D}${bindir};
        mv ${D}/cp.coreutils ${D}${base_bindir}/cp.coreutils;
        mv ${D}/chcon ${D}${bindir}/chcon;
}

