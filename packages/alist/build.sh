TERMUX_PKG_HOMEPAGE=https://alist-doc.nn.ci
TERMUX_PKG_DESCRIPTION="A file list program that supports multiple storage"
TERMUX_PKG_LICENSE="AGPL-V3"
TERMUX_PKG_MAINTAINER="2096779623 <admin@utermux.dev>"
TERMUX_PKG_VERSION=2.6.1
TERMUX_PKG_SRCURL=https://github.com/alist-org/alist/archive/v${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=abc4b68ff5166998da3615a673570e87f65fc1667a4fd820977b20afee6c4fa8
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_AUTO_UPDATE=true

termux_step_pre_configure() {
	# Switch to local to prevent some countries from not connecting to cdn.
	sed -i 's|https://npm.*/dist|/|g' ./conf/config.go
}

termux_step_make() {
	termux_setup_golang

	# Get alist-web:
	(
		mkdir -p alist-web
		cd alist-web && cp ../build.sh .
		bash ./build.sh cdn
		sed -ri 's|(lang=")zh-CN"|\1en-US"|g' dist/index.html
		mv dist/* ../public
	)

	local ldflags webTag
	webTag=$(
		wget -qO- -t1 -T2 "https://api.github.com/repos/alist-org/alist-web/releases/latest" \
			| grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g'
	)
	ldflags="-w -s \
		-X 'github.com/Xhofe/alist/conf.BuiltAt=$(date +'%F %T %z')' \
		-X 'github.com/Xhofe/alist/conf.GoVersion=$(go version | sed 's/go version //')' \
		-X 'github.com/Xhofe/alist/conf.WebTag=${webTag}' \
		-X 'github.com/Xhofe/alist/conf.GitTag=v${TERMUX_PKG_VERSION}'
		"

	go build -ldflags="${ldflags}" -tags=jsoniter -o "${TERMUX_PKG_NAME}" .
}

termux_step_make_install() {
	install -Dm700 ./"${TERMUX_PKG_NAME}" "${TERMUX_PREFIX}"/bin
}
