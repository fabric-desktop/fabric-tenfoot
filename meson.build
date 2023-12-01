project(
  'fabric-tenfoot',
  'vala', 'c',
  version: '0.1',
)

vapi_dir = meson.current_source_dir() / 'vapi'
add_project_arguments(['--vapidir', vapi_dir], language: 'vala')

dependencies = [
  meson.get_compiler('vala').find_library('linux'),
  dependency('gtk4'),
  #meson.get_compiler('c').find_library('m'),
  dependency('manette-0.2', fallback:['libmanette', 'libmanette_dep']),
  dependency('fabric-ui', fallback:['fabric-ui', 'fabric_ui_dep']),
]

sources = []

# Add data for use at runtime
conf = configuration_data()
conf.set_quoted('VERSION', meson.project_version())
conf.set_quoted('GDK_PIXBUF_MODULE_FILE', get_option('gdk_pixbuf_module_file'))
conf.set('bindir', join_paths(get_option('prefix'), 'bin'))

configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')

sources += configure_file(
  input: 'src/configuration.vala.in',
  output: 'configuration.vala',
  configuration: conf,
)

# Call subdirs
subdir('resources')
subdir('src')
