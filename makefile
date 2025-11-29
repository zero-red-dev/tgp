# Variables
OUT_FILE ?= tpg.sh
HEADER_PATH ?= ./scripts/header.sh
MAIN_PATH ?= ./scripts/main.sh
SCRIPTS_PATH ?= ./scripts/fn

$(OUT_FILE):
	sh ./make.sh \
		$(OUT_FILE) \
		$(HEADER_PATH) \
		$(MAIN_PATH) \
		$(SCRIPTS_PATH)


all: $(OUT_FILE)

clean:
	rm -rf $(OUT_FILE)

.PHONY: all clean
