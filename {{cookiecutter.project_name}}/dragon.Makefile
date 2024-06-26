## Add your own custom Makefile targets here


KB_NAME = {{cookiecutter.__project_slug}}_kb
CATEGORY = {{cookiecutter.main_schema_class}}
COLLECTION = {{cookiecutter.__collection}}
INDEX_SLOTS = {{cookiecutter.__index_slot}}

KB = kb/$(KB_NAME).yaml

setup: bootstrap all

bootstrap:
	test -f $(SOURCE_SCHEMA_PATH) && echo already have schema || ( curategpt bootstrap schema -C kb_config.yaml > $(SOURCE_SCHEMA_PATH).tmp && mv $(SOURCE_SCHEMA_PATH).tmp $(SOURCE_SCHEMA_PATH) )
	test -f $(KB) && echo already kb || ( curategpt bootstrap data -s $(SOURCE_SCHEMA_PATH) > $(KB).tmp && mv $(KB).tmp $(KB) )

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

normalized: kb/$(KB_NAME)-clean.yaml
	mv kb/$(KB_NAME)-clean.yaml kb/$(KB_NAME).yaml

kb-docs: derived-yaml all_html

derived-yaml:
	cd derived && yq -s '.name | sub("\\s+|[^[:alnum:]]+"; "_")' ../kb/$(KB_NAME).yaml

tmp/complete-%.yaml:
	curategpt complete  -X yaml  --model gpt-4o -p db -c $(COLLECTION) -P name "$*"   > $@

derived/%.html: derived/%.yml
	$(RUN) linkml-render -c config/render.yaml -r $(CATEGORY) -s src/$(KB_NAME)/schema/$(KB_NAME).yaml  $< -o $@

# list the yml files via shell to get the list of files
all_html: $(patsubst %.yml, %.html, $(shell find derived -name '*.yml'))
