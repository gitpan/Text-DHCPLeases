use Module::Build;
my $build = Module::Build->new
    (
     module_name => 'Text::DHCPLeases',
     license     => 'perl',
     requires    => {
	 'perl'          => '5.8.0',
	 'Class::Struct' => '0.63',
	 'Test::More'    => '0',
     },
     );
$build->create_build_script;
