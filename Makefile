OCAMLFIND = ocamlfind
LIB_DIR = lib/
DHT_DIR = dht/
LIBTEST_DIR = lib_test/
DOC_DIR = doc/
STDLIB_DIR = `$(OCAMLFIND) printconf stdlib`
CFLAGS = -Wall -std=c99
OCAMLFLAGS = -safe-string -g -bin-annot
CC = cc

all: lib test_lib

$(DHT_LIB)dht.o: $(DHT_LIB)dht.h $(DHT_LIB)dht.c
	$(MAKE) -C dht

$(LIB_DIR)dhtstubs.o: $(LIB_DIR)dhtstubs.c
	$(CC) $(CFLAGS) -I $(DHT_DIR) -I $(STDLIB_DIR) -I $(LIB_DIR) -o $@ -c $<

$(LIB_DIR)dht.cmo: $(LIB_DIR)dht.mli $(LIB_DIR)dht.ml
	$(OCAMLFIND) ocamlc $(OCAMLFLAGS) -I $(LIB_DIR) -o $@ -c $^

$(LIB_DIR)dht.cmx: $(LIB_DIR)dht.mli $(LIB_DIR)dht.ml
	$(OCAMLFIND) ocamlopt $(OCAMLFLAGS) -I $(LIB_DIR) -o $@ -c $^

$(LIBTEST_DIR)find_ih: $(LIBTEST_DIR)find_ih.ml $(LIB_DIR)dht.cma
	$(OCAMLFIND) ocamlc $(OCAMLFLAGS) -package lwt.unix -I $(LIB_DIR) -linkpkg -o $@ dht.cma $<

$(LIBTEST_DIR)find_ih.opt: $(LIBTEST_DIR)find_ih.ml $(LIB_DIR)dht.cmxa
	$(OCAMLFIND) ocamlopt $(OCAMLFLAGS) -package lwt.unix -I $(LIB_DIR) -linkpkg -o $@ dht.cmxa $<

lib: $(LIB_DIR)dhtstubs.o $(DHT_DIR)dht.o $(LIB_DIR)dht.cmo $(LIB_DIR)dht.cmx
	ocamlmklib -custom -o $(LIB_DIR)dht $^

install: lib $(LIB_DIR)META
	$(OCAMLFIND) install dht $(LIB_DIR)META $(LIB_DIR)dht.cma $(LIB_DIR)dht.cmxa $(LIB_DIR)libdht.a $(LIB_DIR)dht.cmi $(LIB_DIR)dht.cmti $(LIB_DIR)dht.cmt

uninstall:
	$(OCAMLFIND) remove dht

test_lib: $(LIBTEST_DIR)find_ih $(LIBTEST_DIR)find_ih.opt

find_ih: $(LIBTEST_DIR)find_ih
	LD_LIBRARY_PATH=$(LIB_DIR):$LD_LIBRARY_PATH $^

pull_jech_dht:
	git subtree pull --prefix dht https://github.com/jech/dht master --squash

doc: $(LIB_DIR)dht.mli
	$(OCAMLFIND) ocamldoc -d $(DOC_DIR) -html -colorize-code -css-style style.css $^

gh-pages: doc
	git clone `git config --get remote.origin.url` .gh-pages --reference .
	git -C .gh-pages checkout --orphan gh-pages
	git -C .gh-pages reset
	git -C .gh-pages clean -dxf
	cp $(DOC_DIR)* .gh-pages/
	git -C .gh-pages add .
	git -C .gh-pages commit -m "Update Pages"
	git -C .gh-pages push origin gh-pages -f
	rm -rf .gh-pages

clean:
	rm -f $(LIB_DIR)*.[oa] $(LIB_DIR)*.cm* $(LIB_DIR)*.so $(DHT_DIR)*.o
	rm -f $(LIBTEST_DIR)find_ih.cm* $(LIBTEST_DIR)find_ih $(LIBTEST_DIR)find_ih.o*
	rm -f $(DOC_DIR)*.html

.PHONY: clean pull_jech_dht doc uninstall
