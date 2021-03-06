PATH := $(PATH):UTIL
SRC  := $(shell find . -type f -name '*.pl' | grep -v OFF/ | xargs grep -l '\#!' | cut -b3-)
BIN  := $(SRC:%.pl=%)

all: $(BIN) ll README.md

%: %.pl *.pl
	perlpp $< > $@
	@chmod 755 $@

ll: llast
	ln -s llast ll

IMG := ![]\(test/sshot/1.png)
IMG := <p align="center"><img src=test/sshot/1.png width=580></p>

README.md: $(BIN)
	$< -h | man2md | sed "s:### OPTIONS:$(IMG)\n\n### OPTIONS:" > $@

push: $(BIN) ll README.md
	git add .
	git commit -m update
	git push -f origin master

install: all
	makeinstall -f $(BIN) ll

clean:
	rm -fv $(BIN) ll

mrproper: clean
	rm -fv README.md

