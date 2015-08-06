NAME=	poudriere-plugins
PREFIX?=	/usr/local
DATADIR_REL?=	share/${NAME}
DATADIR?=	${PREFIX}/${DATADIR_REL}

BSD_INSTALL_SCRIPT?=    install -m 555
BSD_INSTALL_DATA?=      install -m 444

MKDIR?=	/bin/mkdir -p

install:
	@${MKDIR} ${DESTDIR}${PREFIX}/bin
	${BSD_INSTALL_SCRIPT} bin/${NAME} ${DESTDIR}${PREFIX}/bin
	@${MKDIR} ${DESTDIR}${DATADIR}
	${BSD_INSTALL_SCRIPT} ${DATADIR_REL}/*.sh ${DESTDIR}${DATADIR}

release:
	sed -i '' -e "s,POUD_VERSION=.*,POUD_VERSION=${VERSION}," ${DATADIR_REL}/_version.sh
	git add ${DATADIR_REL}/_version.sh
	git commit -m "Tag ${VERSION}"
	git tag ${VERSION}
	git push --tags
	git push

.PHONY: install release
