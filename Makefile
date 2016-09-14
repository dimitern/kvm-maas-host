#IGNORE := $(shell bash -c "source env.sh; env | sed 's/=/:=/' | sed 's/^/export /' > make.env")

.PHONY: all

NAME ?= vmtest
NET_NAME ?= vmtest-net
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
	virsh net-define net.xml
	virsh net-autostart $(NET_NAME)
	virsh net-start $(NET_NAME)

remove-net:
	-virsh net-undefine $(NET_NAME)
	-virsh net-destroy $(NET_NAME)

create-vm: config
	./create-vm $(NAME) $(NET_NAME)

delete-vm:
	./delete-vm $(NAME) $(NET_NAME)
