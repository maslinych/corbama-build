DOCKERHOST := cormande
localarch := export
remoteroot := corpora
remotearch := setup
corplist = $(corpora) $(corpora-prl)
configfiles := $(patsubst %,config/%,$(corplist)) 
corpvertfiles := $(patsubst %,%.vert,$(corplist))
corpprlfiles := corbama-bam-fra.prl corbama-fra-bam.prl
archfile := corbama.tar.xz 

exportfiles: $(configfiles) $(corpvertfiles) $(corpprlfiles)
	rm -f $(localarch)/registry/*
	rm -f $(localarch)/vert/*
	cp -f $(configfiles) $(localarch)/registry
	cp -f $(corpvertfiles) $(localarch)/vert
	cp -f $(corpprlfiles) $(localarch)/vert
	sed -i '/^\s*<doc/d' $(corpprlfiles)

docker-local:
	docker run -dit --name $(corpsite) -v $$(pwd)/$(localarch)/vert:/var/lib/manatee/vert -v $$(pwd)/$(localarch)/registry:/var/lib/manatee/registry -p 127.0.0.1:8088:8080 -e CORPLIST="$(corplist)" maslinych/noske-alt:2.130.1-alt4-1

upload-files: 
	tar cJvf $(localarch)/$(archfile) $(localarch)/registry $(localarch)/vert
	rsync -avP -e ssh $(localarch)/$(archfile) $(DOCKERHOST):$(remotearch)
	ssh $(DOCKERHOST) 'tar xvf $(remotearch)/$(archfile) -C $(remoteroot)'

remove-testing-docker:
	ssh $(DOCKERHOST) 'docker stop testing'
	ssh $(DOCKERHOST) 'docker rm testing'

create-testing-docker: 
	ssh $(DOCKERHOST) 'docker run -dit --name testing -v $$(pwd)/$(remoteroot)/vert:/var/lib/manatee/vert -v $$(pwd)/$(remoteroot)/registry:/var/lib/manatee/registry -p 127.0.0.1:8088:8080 -e CORPLIST="$(corplist)" maslinych/noske-alt:2.130.1-alt4-1'

