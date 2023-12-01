gnome = import('gnome')

lessc = find_program('lessc')
css_output = custom_target(
  'styles',
  input:   ['index.less'],
  output:  ['styles.css'],
  command: [
    lessc,
    '--math=always',
    '--verbose',
    '@INPUT@',
    '@OUTPUT@',
  ]
)

resources = gnome.compile_resources(
  'resources', 'resources.gresource.xml',
  dependencies: [css_output],
  source_dir: '.',
  c_name: 'fabric_tenfoot_resources'
)
