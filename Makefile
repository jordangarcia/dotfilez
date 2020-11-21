root_dir := $(shell pwd)
vim_bundle_dir = $(HOME)/.vim/bundle
vundle = $(HOME)/.vim/bundle/vundle
dotfiles = $(HOME)/.dotfiles
vimrc = $(HOME)/.vimrc

vimbundles: $(vimrc) $(vundle)
	vim +BundleInstall! +BundleClean +qall

symlinks: $(dotfiles)
	$(root_dir)/scripts/symlink_dotfiles

$(dotfiles): $(root_dir)
	rm -rf $(dotfiles)
	ln -s $(root_dir) $(dotfiles)

$(vim_bundle_dir):
	mkdir -p $(vim_bundle_dir)

$(vundle): $(vim_bundle_dir)
	git clone http://github.com/gmarik/vundle.git $(vundle)

$(vimrc): symlinks
