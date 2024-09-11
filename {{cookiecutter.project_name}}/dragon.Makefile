## Add your own custom Makefile targets here


KB_STEM = {{cookiecutter.__project_slug}}
KB_NAME = {{cookiecutter.__project_slug}}_kb
CATEGORY = {{cookiecutter.main_schema_class}}
COLLECTION = {{cookiecutter.__collection}}
INDEX_SLOTS = {{cookiecutter.__index_slot}}

KB = kb/$(KB_NAME).yaml

dragon-init:
	make check-config git-init install
	make bootstrap
	make derived-yaml
	make derived-html
	make cp-html
	make gen-project
	make gendoc
	make git-add git-commit
	echo "Next steps:"
	make help


help: status
	@echo ""
	@echo "make dragon-init -- initial setup and bootstrap schema and kb (run this first)"
	@echo "make serve -- deploy local server"
	@echo "make add-evidence"
	@echo "make validate-data"
	@echo "make html -- generate HTML"
	@echo "make help -- show this help"
	@echo ""

.PHONY: dragon-init

setup1: check-config git-init install
	echo "initial setup complete"
.PHONY: setup1

setup2: bootstrap all_html
	echo "bootstrap and html building complete"
.PHONY: setup2

setup3: gen-project git-add git-commit
	echo "all complete"
.PHONY: setup3

#setup: bootstrap all_html all

bootstrap:
	test -f $(SOURCE_SCHEMA_PATH) && echo already have schema || ( curategpt bootstrap schema -C kb_config.yaml > $(SOURCE_SCHEMA_PATH).tmp && mv $(SOURCE_SCHEMA_PATH).tmp $(SOURCE_SCHEMA_PATH) )
	test -f $(KB) && echo already kb || ( curategpt bootstrap data -s $(SOURCE_SCHEMA_PATH) > $(KB).tmp && mv $(KB).tmp $(KB) )
	echo completed bootstrapping

test-examples: test-data validate-data

test-data: $(KB)
	yq . $<


validate-data: $(KB) $(SOURCE_SCHEMA_PATH)
	yq ea '[.]' $< | yq e '{"$(INDEX_SLOTS)": .}' - > tmp/data.yaml && \
	$(RUN) linkml-validate -s $(SOURCE_SCHEMA_PATH) tmp/data.yaml

index: kb/$(KB_NAME)-no-evidence.yaml
	curategpt index -p db -c $(COLLECTION) $< 

list:
	curategpt collections list -p db

app:
	curgptapp

%-no-evidence.yaml: %.yaml
	yq eval 'del(.. | .evidence?)' $< > $@.tmp && mv $@.tmp $@
%-clean.yaml: %.yaml
	yq . $< > $@

tmp/with-evidence.yaml:
	curategpt  citeseek --model gpt-4o $(KB) > $@

add-evidence: tmp/with-evidence.yaml
	cp $< $(KB)

tmp/new.yaml: $(KB)
	curategpt complete-auto -X yaml --model gpt-4o -p db -c $(COLLECTION) -P name > $@

add-entries: tmp/new.yaml
	cp $< $(KB)

normalized: kb/$(KB_NAME)-clean.yaml
	mv kb/$(KB_NAME)-clean.yaml kb/$(KB_NAME).yaml

kb-docs: derived-yaml all_html

tmp/complete-%.yaml:
	curategpt complete  -X yaml  --model gpt-4o -p db -c $(COLLECTION) -P name "$*"   > $@

derived-yaml:
	echo generating YAML from KB
	cd derived && yq -s '.name | sub("\\s+|[^[:alnum:]]+"; "_")' ../kb/$(KB_NAME).yaml
.PHONY: derived-yaml

derived/%.html: derived/%.yml
	$(RUN) linkml-render -c config/render.yaml -r $(CATEGORY) -s $(SOURCE_SCHEMA_PATH)  $< -o $@

# list the yml files via shell to get the list of files
YAML_FILES = $(patsubst %.yml, %.html, $(shell find derived -name '*.yml'))
derived-html: derived-yaml $(YAML_FILES)
.PHONY: derived-html


cp-html: derived-html
	mkdir -p docs/kb
	cp derived/*html docs/kb
	ls docs/kb/*html | ./utils/mk-kb-index.awk > docs/kb/index.md
.PHONY: cp-html

html: cp-html

serve:
	$(RUN) mkdocs serve
