GIT_COMMIT		:= $(shell git rev-parse --short HEAD || echo 'unknown')
GIT_BRANCH		:= $(shell echo $${WORKFLOW_BRANCH_OR_TAG-$$(git rev-parse --abbrev-ref HEAD || echo 'unknown')})
GIT_BRANCH_NUM	:= $(shell git rev-list --count HEAD || echo 'nan')
BUILD_DATE		:= $(shell date '+%d-%m-%Y' || echo 'unknown')
BUILD_TIME		:= $(shell date '+%H:%M:%S' || echo 'unknown')
VERSION			:= $(shell git describe --tags --abbrev=0 --exact-match 2>/dev/null || echo 'unknown')

TMPL_ENVS += \
	GIT_COMMIT=\"$(GIT_COMMIT)\" \
	GIT_BRANCH=\"$(GIT_BRANCH)\" \
	GIT_BRANCH_NUM=\"$(GIT_BRANCH_NUM)\" \
	BUILD_DATE=\"$(BUILD_DATE)\" \
	VERSION=\"$(VERSION)\" \

# if suffix is set in environment (by Github), use it
ifeq (${DIST_SUFFIX},)
	DIST_SUFFIX	:= local-$(GIT_COMMIT)$(GIT_DIRTY_SUFFIX)
else
	DIST_SUFFIX := ${DIST_SUFFIX}$(GIT_DIRTY_SUFFIX)
endif

VERSION_STRING  := $(DIST_SUFFIX), $(GIT_BRANCH)

