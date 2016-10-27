
RELEASE=dist/md380tools-`date "+%Y-%m-%d"`

##This strips out all unicode characters.
##We'd rather just drop the accents.
#ICONV=iconv -c -f UTF-8 -t ascii//TRANSLIT

.PHONY: dist

all: image_D13
	
distclean: clean
	rm -rf dist
		
clean: mostlyclean
	"${MAKE}" -C firmware clean
	
# mostlyclean does not cause re-download firmware
mostlyclean:
	"${MAKE}" -C patches/2.032 clean
	"${MAKE}" -C patches/3.020 clean
	"${MAKE}" -C patches/s13.020 clean
	"${MAKE}" -C patches/d13.020 clean
	"${MAKE}" -C applet clean
	"${MAKE}" -C db clean
	rm -f *~ *.pyc
	rm -f data data.csv	
	-rm *.bin
	

#patches: firmwares
#	"${MAKE}" -C patches/2.032 all
#	"${MAKE}" -C patches/d13.020 all

#applets: patches
#	"${MAKE}" -C applet all

#firmwares:
#	"${MAKE}" -C firmware all

image_D02:
	"${MAKE}" -C applet FW=D02_032 all  

image_D13:
	"${MAKE}" -C applet FW=D13_020 all  
	
image_S13:
	"${MAKE}" -C applet FW=S13_020 all  
	
flash:
	"${MAKE}" -C applet clean flash
	
flash_d02.032:
	"${MAKE}" -C applet FW=D02_032 clean flash
	
flash_s13.020:
	"${MAKE}" -C applet FW=S13_020 clean flash
	
#.PHONY: data
#data:
#	"${MAKE}" -C db
#	if [ -e db/custom.csv ]; then cat db/custom.csv >> db/users.csv; sort -n -t , -k 1 db/users.csv > db/sorted.csv; mv db/sorted.csv db/users.csv; fi
#	$(ICONV) db/users.csv | cut -d',' -f1-3,5-6 | sed 's/,\s+/,/g' > data.csv
#	wc -c < data.csv > data
#	cat data.csv >> data

.PHONY: updatedb flashdb
updatedb:
	"${MAKE}" -C db update
	
user.bin: db/stripped.csv db/users.csv
	"${MAKE}" -C db stripped.csv
	wc -c < db/stripped.csv > user.bin
	cat db/stripped.csv >> user.bin
	
flashdb: user.bin
	./md380-tool spiflashwrite user.bin 0x100000

dist: 
	rm -rf $(RELEASE) $(RELEASE).zip
	mkdir -p $(RELEASE)/python
#Main release.
	"${MAKE}" mostlyclean image_D13
	cp applet/experiment.bin $(RELEASE)/firmware-`date "+%Y-%m-%d-NoGPS"`.bin
#For GPS radios.
	"${MAKE}" mostlyclean image_S13
	cp applet/experiment.bin $(RELEASE)/firmware-`date "+%Y-%m-%d-GPS"`.bin
#Older
	"${MAKE}" mostlyclean image_D02
	cp applet/experiment.bin $(RELEASE)/firmware-`date "+%Y-%m-%d-OLD"`.bin
#Include the Official Installer
	cd $(RELEASE) && unzip ../../firmware/dl/D002.032.zip
	mv $(RELEASE)/Firmware\ 2.32 $(RELEASE)/windows
	rm $(RELEASE)/windows/MD-380-D2.32\(AD\).bin $(RELEASE)/windows/Operation.doc.pdf
	cp *.py 99-md380.rules md380-dfu md380-tool $(RELEASE)/python/
#Clean out some gunk
	rm -rf $(RELEASE)/__MACOSX
#Zip it up for distribution.
	zip -r $(RELEASE).zip $(RELEASE)

doflash: image_D13
	./md380-dfu upgrade applet/experiment.bin


# or else make will fail.
#download:
#	"${MAKE}" -C firmware download

all_images: 
	"${MAKE}" -C applet ci
	
ci: mostlyclean 
	"${MAKE}" -C applet ci
	"${MAKE}" -C db ci
	"${MAKE}" user.bin

check-ignore:
	find -type f | git check-ignore -v --stdin | less

