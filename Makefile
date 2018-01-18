ISO	:= $(wildcard ~/Downloads/isos/installer-*.x86_64.iso)
UEFISH	:= $(wildcard ~/Downloads/isos/UefiShell.iso)

VMS	:= test
VCPUS	:= 1
RAM	:= 2048		# MiB
DISKS	:= 20 20	# GB

define TEMPLATE =
$(1):
	sudo virt-install \
		--name		$(1) \
		--arch		x86_64 \
		--machine	q35 \
		--features	smm=on \
		--vcpus		$$(VCPUS) \
		--memory	$$(RAM) \
		--boot		uefi,loader=/usr/share/edk2/ovmf/OVMF_CODE.secboot.fd,loader_ro=yes,loader_secure=yes,loader_type=pflash \
		--os-variant	rhel7.4 \
		--location	$$(ISO) \
		--extra-args	"ks=cdrom:/ks.cfg console=ttyS0" \
		--disk		device=cdrom,path=$$(UEFISH),boot_order=1 \
		--disk		bus=sata,size=$$(word 1,$$(DISKS)),boot_order=2 \
		--disk		bus=sata,size=$$(word 2,$$(DISKS)) \
		--network	network=default,model=e1000 \
		--graphics	none \
		--controller	usb,model=none \
		--virt-type	kvm \
		--check		path_in_use=off \
		--noreboot
	expect	-c "set timeout -1" \
		-c "spawn sudo virsh start $(1) --console" \
		-c 'expect "in * seconds to skip"' \
		-c 'send "\r"' \
		-c 'expect "Shell> "' \
		-c 'send "EnrollDefaultKeys.efi\r"' \
		-c 'expect "info: success"' \
		-c 'send "reset -s\r"' \
		-c 'expect eof'

clean-$(1):
	-sudo virsh destroy  $(1)
	-sudo virsh undefine $(1) --nvram --storage sdb,sdc
endef
$(foreach vm,$(VMS),$(eval $(call TEMPLATE,$(vm))))

all: $(VMS)
clean: $(addprefix clean-,$(VMS))

.PHONY: all clean $(VMS) $(addprefix clean-,$(VMS))
.NOTPARALLEL:
