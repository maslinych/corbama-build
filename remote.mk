remote-setup:
	@echo Remote host: $(HOST)
	@echo Corpus archive basename: $(corpbasename)
	@echo Corpus site name: $(corpsite)
	@echo A list of corpora to be installed: $(corpora)

install-remote-scripts:
	$(RSYNC) remote/*.sh $(HOST):bin

create-testing: install-remote-scripts
	ssh $(HOST) "bin/create-hsh.sh"
	ssh $(HOST) "bin/install-all-corpora.sh"
	ssh $(HOST) "bin/setup-all-corpora.sh"

setup-bonito: install-remote-scripts
	ssh $(HOST) "bin/setup-corpus.sh $(corpsite) $(corpora)"

install-corpus-%: export/%.tar.xz
	$(RSYNC) $< $(HOST):$(BUILT)/
	ssh $(HOST) "echo $(corpsite-$*) $(corpora-$*) > $(BUILT)/$*.setup.txt"
	ssh $(HOST) "bin/stop-env.sh testing"
	ssh $(HOST) "bin/install-corpus.sh $*"
	ssh $(HOST) "bin/start-env.sh testing"

uninstall-testing:
	ssh $(HOST) "rm -f $(BUILT)/$(corpbasename).tar.xz"
	ssh $(HOST) "rm -f $(BUILT)/$(corpbasename).setup.txt"

start-%:
	ssh $(HOST) "bin/start-env.sh $*"

stop-%:
	ssh $(HOST) "bin/stop-env.sh $*"

update-corpus:
	make compile
	make stop-testing
	make install-testing
	make start-testing

production: stop-production stop-testing
	$(RSYNC) remote/testing2production.sh $(HOST):$(TESTING)/chroot/.in/
	ssh $(HOST) hsh-run --rooter $(TESTING) -- 'sh testing2production.sh $(TESTPORT) $(PRODPORT)'
	ssh $(HOST) sh -c 'test -d $(ROLLBACK)/chroot && hsh --clean $(ROLLBACK) || echo empty rollback'
	ssh $(HOST) rm -rf $(ROLLBACK)
	ssh $(HOST) mv $(PRODUCTION) $(ROLLBACK)
	ssh $(HOST) mv $(TESTING) $(PRODUCTION)

rollback: stop-production
	$(RSYNC) remote/testing2production.sh $(HOST):$(PRODUCTION)/chroot/.in/
	ssh $(HOST) hsh-run --rooter $(PRODUCTION) -- 'sh testing2production.sh $(PRODPORT) $(TESTPORT)'
	ssh $(HOST) sh -c 'test -d $(TESTING)/chroot && hsh --clean $(TESTING)'
	ssh $(HOST) rm -rf $(TESTING)
	ssh $(HOST) mv $(PRODUCTION) $(TESTING)
	ssh $(HOST) mv $(ROLLBACK) $(PRODUCTION)


