KBS = \
antibody \
assaykb \
cell-type \
complexkb \
flybehave \
gcprkb \
human-gene-kb \
microbe-media \
mouse-strain \
natprodkb \
signaling-pathway-kb \
virus

test-with-%: %.yaml
	cookiecutter .. --no-input --config-file $< && \
	cd $* && make dragon-init

sync: $(patsubst %, sync-%, $(KBS))

sync-%:
	cp $*.yaml historic && cp -pr $* historic
