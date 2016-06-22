INPUTS=example-inputs.yaml
M4INPUTS=$(INPUTS).m4
BLUEPRINT=example-blueprint.yaml
M4BLUEPRINT=$(BLUEPRINT).m4
CFM_BLUEPRINT=example
CFM_DEPLOYMENT=example
RETRIES=10
VIRTUALENV=~/cfy


# blueprints
cfy-$(BLUEPRINT): $(M4BLUEPRINT)
	m4 $? >$@

cfm-$(BLUEPRINT): $(M4BLUEPRINT)
	m4 -D_CFM_ $? >$@

# inputs
cfy-$(INPUTS): $(M4INPUTS) resources/ssh/id_rsa
	m4 $(M4INPUTS) >$@

cfm-$(INPUTS): $(M4INPUTS) resources/ssh/id_rsa
	m4 -D_CFM_ -D_CFM_BLUEPRINT_=$(CFM_BLUEPRINT) $(M4INPUTS) >$@

validate: cfy-$(BLUEPRINT) cfm-$(BLUEPRINT)
	cfy blueprints validate -p cfy-$(BLUEPRINT)
	cfy blueprints validate -p cfm-$(BLUEPRINT)

clean:
	rm -rf cfy-$(INPUTS) cfm-$(INPUTS) cfy-$(BLUEPRINT) cfm-$(BLUEPRINT) resources/puppet.tar.gz resources/ssh/ local-storage/

cfy-deploy: cfy-init cfy-exec-install

cfy-undeploy: cfy-exec-uninstall

cfy-test: cfy-deploy cfy-undeploy

cfm-deploy: cfm-init cfm-exec-install

cfm-test: cfm-deploy cfm-exec-uninstall cfm-clean


### Resources ####################################

resources/ssh/id_rsa:
	mkdir -p resources/ssh/
	ssh-keygen -N '' -f resources/ssh/id_rsa

resources/puppet.tar.gz: resources/puppet/
	tar -czvf $@ -C $? .


### Standalone deployment ########################

cfy-init: cfy-$(BLUEPRINT) cfy-$(INPUTS) resources/puppet.tar.gz
	cfy local init -p cfy-$(BLUEPRINT) -i cfy-$(INPUTS) --install-plugins

# execute deployment
cfy-exec-%:
	cfy local execute -w $* --task-retries $(RETRIES)


### Cloudify Manager managed deployment ##########

cfm-init: cfm-$(BLUEPRINT) cfm-$(INPUTS) resources/puppet.tar.gz
	cfy blueprints upload -b $(CFM_BLUEPRINT) -p cfm-$(BLUEPRINT)
	cfy deployments create -b $(CFM_BLUEPRINT) -d $(CFM_DEPLOYMENT) -i cfm-$(INPUTS)

cfm-exec-%:
	cfy executions start -d $(CFM_DEPLOYMENT) -w $*
	sleep 10

cfm-clean:
	cfy deployments delete -d $(CFM_DEPLOYMENT)
	cfy blueprints delete -b $(CFM_BLUEPRINT)


### Bootstrap cfy ################################

bootstrap:
	test -f get-cloudify.py && unlink get-cloudify.py || /bin/true
	yum install -y python-virtualenv python-pip
	wget -O get-cloudify.py 'http://repository.cloudifysource.org/org/cloudify3/get-cloudify.py'
	python get-cloudify.py -e $(VIRTUALENV)
	unlink get-cloudify.py
