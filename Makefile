#IGNORE := $(shell bash -c "source env.sh; env | sed 's/=/:=/' | sed 's/^/export /' > make.env")

.PHONY: all

NAME ?= maas20
NET ?= maas20-net
DS := $(NAME).iso

ifdef MAAS_HOST_DOMAIN_NAME
MAAS_HOST_NAME := $(NAME).$(MAAS_HOST_DOMAIN_NAME)
else
MAAS_HOST_NAME := $(NAME)
endif

IMAGE_DIR := /var/lib/libvirt/images

all: install

config: $(DS)

%.iso: user-data Makefile network-config vendor-data
	@echo generating $@
	cloud-localds -H $(MAAS_HOST_NAME) -N network-config -V vendor-data -m net $@ user-data

install: $(patsubst %,$(IMAGE_DIR)/%,$(DS))

user-data: user-data.d user-data.d/*.yaml Makefile
	write-mime-multipart -o $@ user-data.d/*.yaml

$(IMAGE_DIR)/%.iso: %.iso
	sudo cp -v $< $@

.PHONY: clean redo-net remove-net create-vm delete-vm

clean:
	$(RM) $(DS) user-data

redo-net: remove-net
	virsh net-define $(NET).xml
	virsh net-autostart $(NET)
	virsh net-start $(NET)

remove-net:
	-virsh net-undefine $(NET)
	-virsh net-destroy $(NET)

create-vm: config
	./create-vm $(NAME) $(NET)

delete-vm:
	./delete-vm $(NAME) $(NET)
