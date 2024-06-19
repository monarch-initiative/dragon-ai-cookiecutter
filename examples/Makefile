test-with-%: %.yaml
	cookiecutter .. --no-input --config-file $< && \
	cd $* && make bootstrap && make install && make all
