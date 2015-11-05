set dir (dirname (status -f))

function test___fundle_plugins_dir
	set -e fundle_plugins_dir
	if test (__fundle_plugins_dir) != "$HOME/.config/fish/fundle"
		echo "__fundle_plugins_dir should eq $HOME/.config/fish/fundle when no arg passed"
		return 1
	end

	set -g fundle_plugins_dir $dir/fundle
	if test (__fundle_plugins_dir) != "$dir/fundle"
		echo '__fundle_plugins_dir should eq $fundle_plugins_dir when set'
		return 1
	end
end

function test___fundle_no_git
	if test (__fundle_no_git)
		echo '__fundle_no_git should return 1 when git present'
		return 1
	end
end

function test___fundle_get_url
	set -l plugin tuvistavie/fish-fastdir
	if test (__fundle_get_url $plugin) != "https://github.com/$plugin.git"
		echo '__fundle_get_url should return the github repository url'
		return 1
	end
end

function test___fundle_install_plugin
	set -g fundle_plugins_dir $dir/fundle
	set -l plugin tuvistavie/fish-fastdir
	set -l repo $dir/fixtures/fish-fastdir

	set -l res (__fundle_install_plugin $plugin /bad/path 2>&1 > /dev/null)
	if test $status -eq 0
		echo '__fundle_install_plugin should fail when plugin does not exist'
		return 1
	end

	set -l res (__fundle_install_plugin $plugin $repo 2>&1 > /dev/null)
	if test $status -ne 0
		echo '__fundle_install_plugin should not fail when plugin exists'
		return 1
	end

	rm -rf $dir/fundle
end

function test___fundle_update_plugin
	set -g fundle_plugins_dir $dir/fundle
	set -l plugin tuvistavie/fish-fastdir
	set -l repo $dir/fixtures/fish-fastdir

	# ignore output
	set -l res (__fundle_update_plugin $plugin $repo 2>&1 > /dev/null)
	if test $status -eq 0
		echo '__fundle_update_plugin should fail when plugin not present'
		return 1
	end

	set -l res (__fundle_install_plugin $plugin $repo 2>&1 > /dev/null)
	set -l res (__fundle_update_plugin $plugin $repo 2>&1 > /dev/null)
	if test $status -eq 0
		echo '__fundle_update_plugin should succeed when plugin is present'
		return 1
	end

	rm -rf $dir/fundle
end

function test___fundle_plugin_path
	set -g fundle_plugins_dir $dir/fundle
	if test (__fundle_plugin_path 'tuvistavie/fish-fastdir') != "$fundle_plugins_dir/tuvistavie/fish-fastdir"
		echo '__fundle_plugin_path should return plugin path in $fundle_plugins_dir'
		return 1
	end

	if test (__fundle_plugin_path 'tuvistavie/fish-fastdir' 'init.fish') != "$fundle_plugins_dir/tuvistavie/fish-fastdir/init.fish"
		echo '__fundle_plugin_path should return plugin file path in $fundle_plugins_dir'
		return 1
	end
end

function test___fundle_plugin
	set -e __fundle_plugin_names
	set -e __fundle_plugin_urls

	__fundle_plugin 'foo/bar'
	__fundle_plugin 'foo/baz' '/path/to/baz'

	echo (count $__fundle_plugin_names)
	if test (count $__fundle_plugin_names) -ne 2
		echo '__fundle_plugin should add plugins to $__fundle_plugin_names'
		return 1
	end

	if test (count $__fundle_plugin_urls) -ne 2
		echo '__fundle_plugin should add plugins to $__fundle_plugin_urls'
		return 1
	end

	if test $__fundle_plugin_names[1] != 'foo/bar'
		echo '__fundle_plugin should add names in order'
		return 1
	end

	if test $__fundle_plugin_urls[1] != (__fundle_get_url 'foo/bar')
		echo '__fundle_plugin should add urls in order and use default url when not given'
		return 1
	end

	if test $__fundle_plugin_urls[2] != '/path/to/baz'
		echo '__fundle_plugin should use given url'
		return 1
	end
end

function test___fundle_init
	set -e __fundle_plugin_names
	set -e __fundle_plugin_urls
	set -g fundle_plugins_dir $dir/fundle

	set -l res (__fundle_init)
	if test $status -eq 0
		echo '__fundle_init should fail when no plugin registered'
		return 1
	end

	set -l res (__fundle_init)
	__fundle_plugin 'foo/bar'
	if test $status -ne 0
		echo '__fundle_init should not fail when plugin is not installed'
		return 1
	end

	if test -z "$res"
		echo '__fundle_init should output a warning when plugin not installed'
		return 1
	end

	set -e __fundle_plugin_names
	set -e __fundle_plugin_urls

	mkdir -p $dir/fundle
	cp -r $dir/fixtures/foo $dir/fundle/foo
	__fundle_plugin 'foo/with_init'
	__fundle_plugin 'foo/without_init'

	set -l res (__fundle_init)
	if test -n "$res"
		echo '__fundle_init should not output anything when all plugin are present'
		echo "Output: $res"
		return 1
	end

	if test -z "$i_have_init_file"
		echo '__fundle_init should load init.fish when present'
		return 1
	end
	if test -z "$i_do_have_init_file"
		echo '__fundle_init should load all .fish files when init.fish not present'
		return 1
	end
	if test -n "$i_should_be_empty"
		echo '__fundle_init should not load othr .fish files when init.fish present'
		return 1
	end

	if not functions -q my_plugin_function
		echo '__fundle_init should load plugin functions'
		return 1
	end

	rm -rf $dir/fundle
end

function test_fundle
	set -g fundle_plugins_dir $dir/fundle
	set -e __fundle_plugin_names
	set -e __fundle_plugin_urls

	fundle plugin 'tuvistavie/fish-fastdir' $dir/fixtures/fish-fastdir
	if test $status -ne 0
		echo 'fundle plugin should not fail with correct arguments'
		return 1
	end
	if test $__fundle_plugin_names[1] != 'tuvistavie/fish-fastdir'
		echo 'fundle plugin should add the repository to $__fundle_plugin_names'
		return 1
	end

	set -l res (fundle install 2>&1 > /dev/null)
	if test $status -ne 0
		echo 'fundle install should not fail with existing plugins'
		return 1
	end
	if not test -d $fundle_plugins_dir/tuvistavie/fish-fastdir
		echo 'fundle install should install registered plugins'
		return 1
	end

	cp -r $dir/fixtures/foo $dir/fundle/foo
	fundle plugin 'foo/with_init'
	fundle init
	if test $status -ne 0
		echo 'fundle init should not fail when plugin registered'
		return 1
	end
	if not functions -q my_plugin_function
		echo 'fundle init should load plugin functions'
		return 1
	end

	rm -rf $dir/fundle
end