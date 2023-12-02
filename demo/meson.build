project(
  'fabric-tenfoot-demo',
  'vala', 'c',
  version: '0.1'
)

vapi_dir = meson.current_source_dir() / 'vapi'
add_project_arguments(['--vapidir', vapi_dir], language: 'vala')

dependencies = [
  meson.get_compiler('vala').find_library('linux'),
  dependency('gtk4'),
  dependency('fabric-ui', fallback:['fabric-ui', 'fabric_ui_dep']),
  dependency('fabric-tenfoot', fallback:['fabric-tenfoot', 'fabric_tenfoot_dep']),
]

sources = []

# Add data for use at runtime
conf = configuration_data()
conf.set_quoted('VERSION', meson.project_version())
conf.set('bindir', join_paths(get_option('prefix'), 'bin'))

configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')

# Call subdirs
subdir('src')
