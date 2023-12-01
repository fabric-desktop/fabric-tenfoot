sources += files(
  'contextual_action.vala',
  'contextual_widget.vala',
  'tenfoot_application.vala',
  'vapi/event_code.vapi',
  'vapi/fixups.vapi',
)

subdir('components')
subdir('controllers')

fabric_tenfoot_lib = shared_library(
  meson.project_name(),
  [resources, sources],
  dependencies: dependencies,
  c_args: [
    '-include', 'config.h'
  ],
  vala_args: [
    '--vapidir', join_paths(meson.current_source_dir(), 'vapi'),
  ],
  install: true,
  install_dir: [true, true, true]
)

fabric_tenfoot_dep = declare_dependency(
  link_with: fabric_tenfoot_lib,
  include_directories: include_directories('.'),
)

pkgg = import('pkgconfig')
pkgg.generate(
  libraries: fabric_tenfoot_lib,
  version: meson.project_version(),
  name: meson.project_name(),
  description: 'Building blocks for Fabric Tenfoot applications',
)
