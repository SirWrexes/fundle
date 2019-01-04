source $DIRNAME/helper.fish

function setup
	__fundle_common_setup
	cp -r $path/fixtures/foo $path/fundle/foo
	__fundle_plugin 'foo/with_dependency' # this should recursively load 'foo/with_init'
	__fundle_plugin 'foo/without_init'
	__fundle_plugin 'foo/subfolder' --path 'plugin'
	set -g output (__fundle_init)
	set -g code $status
end

function teardown
	__fundle_clean_tmp_dir
end

test "$TESTNAME: fails when no plugin registered"
	(__fundle_cleanup_plugins; and __fundle_init > /dev/null 2>&1) 1 -eq $status
end

test "$TESTNAME: does not fail when plugin not installed"
	0 -eq $code
end

test "$TESTNAME: outputs a warning when plugin not installed"
	-n (__fundle_plugin 'foo/i_dont_exit'; __fundle_init)
end

test "$TESTNAME: does not output anything when all plugin are present"
	-z "$output"
end

test "$TESTNAME: loads init.fish when present"
	-n "$i_have_init_file"
end

test "$TESTNAME: does not load other .fish files when init.fish present"
	-z "$i_should_be_empty"
end

test "$TESTNAME treats package as function folder when init.fish not present"
	-n (no_init)
end

test "$TESTNAME adds functions directory to fish_function_path"
	"$path/fundle/foo/with_init/functions" \
	"$path/fundle/foo/subfolder/plugin/functions" = $fish_function_path
end

test "$TESTNAME adds completions directory to fish_complete_path"
	"$path/fundle/foo/with_init/completions" \
	"$path/fundle/foo/subfolder/plugin/completions" = $fish_complete_path
end

test "$TESTNAME loads plugin functions"
	(functions -q my_plugin_function my_subfolder_plugin_function) 0 -eq $status
end

test "$TESTNAME with profile outputs profiling info"
	(__fundle_init --profile | grep 'us' > /dev/null) 0 -eq $status
end
