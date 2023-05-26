DOCKERHOST := cormande
localarch := export
remoteroot := corpora
remotearch := setup
corplist = $(corpora) $(corpora-prl)
configfiles := $(patsubst %,config/%,$(corplist)) 
corpvertfiles := $(patsubst %,%.vert,$(corplist))
corpprlfiles := corbama-bam-fra.prl corbama-fra-bam.prl corbama-bam-fra2.prl corbama-fra2-bam.prl
archfile := corbama.tar.xz 
udhome := ../UD_Bambara

exportfiles: $(configfiles) $(corpvertfiles) $(corpprlfiles)
	rm -f $(localarch)/registry/*
	rm -f $(localarch)/vert/*
	cp -f $(configfiles) $(localarch)/registry
	cp -f $(corpvertfiles) $(localarch)/vert
	cp -f $(corpprlfiles) $(localarch)/vert
	sed -i '/^\s*<doc/d' $(patsubst %,$(localarch)/vert/%,$(corpprlfiles))
	$(MAKE) add-corbama-ud

add-corbama-ud:
	cp -f $(udhome)/config/corbama-ud $(localarch)/registry
	cp -f $(udhome)/corbama-ud.vert $(localarch)/vert


docker-local:
	docker run -dit --name $(corpsite) -v $$(pwd)/$(localarch)/vert:/var/lib/manatee/vert -v $$(pwd)/$(localarch)/registry:/var/lib/manatee/registry -p 127.0.0.1:8088:8080 -e CORPLIST="$(corplist) corbama-ud" maslinych/noske-alt:2.130.1-alt4-1

pack-files: 
	rm -f $(localarch)/$(archfile)
	tar cJvf $(localarch)/$(archfile) $(localarch)/registry $(localarch)/vert

upload-files: 
	rsync -avP -e ssh $(localarch)/$(archfile) $(DOCKERHOST):$(remotearch)
	ssh $(DOCKERHOST) 'tar xvf $(remotearch)/$(archfile) -C $(remoteroot)'

remove-testing-docker:
	ssh $(DOCKERHOST) 'docker stop testing'
	ssh $(DOCKERHOST) 'docker rm testing'

create-testing-docker: 
	ssh $(DOCKERHOST) 'docker run -dit --name testing -v $$(pwd)/$(remoteroot)/vert:/var/lib/manatee/vert -v $$(pwd)/$(remoteroot)/registry:/var/lib/manatee/registry -p 127.0.0.1:8088:8080 -e CORPLIST="$(corplist) corbama-ud" maslinych/noske-alt:2.130.1-alt4-1'

