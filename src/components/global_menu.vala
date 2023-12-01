namespace Fabric.Tenfoot {
	public class GlobalMenu : Gtk.Box, ContextualWidget {
		private static GLib.Once<GlobalMenu> _instance;
		public static unowned GlobalMenu instance {
			get { return _instance.once(() => { return new GlobalMenu(); }); }
		}

		// Actions {{{

		protected ContextualActionGroup menu_actions;

		public static bool activate_menu_action(string name) {
			var action = instance.get_menu_action(name);
			if (action == null) { return false; }
			action.activate();
			return true;
		}

		private ContextualAction? get_menu_action(string name) {
			return menu_actions.lookup(name);
		}

		private ContextualAction? add_menu_action(string name) {
			var action = new ContextualAction(name, null);
			menu_actions.insert(name, action);
			return action;
		}

		// }}}

		private GlobalMenu() {}

		protected Gtk.Box menu_well;
		protected Gtk.Box well_items;
		protected Gtk.Widget last_focus;

		/**
		 * Menu items
		 */
		public HashTable<string, MenuItem> menu_items;

		construct {
			menu_items = new HashTable<string, MenuItem>(str_hash, str_equal);
			menu_actions = new ContextualActionGroup();

			contextual_action_add("gamepad.back", "Close")
				.activate.connect(() => {
					activate_menu_action("_hide");
				})
			;

			add_css_class("global-menu");

			orientation = Gtk.Orientation.VERTICAL;
			hexpand = true;
			halign = Gtk.Align.FILL;

			menu_well = new Gtk.Box(Gtk.Orientation.VERTICAL, 0) {
				vexpand = true,
				valign = Gtk.Align.FILL,
				hexpand = false,
				halign = Gtk.Align.START,
			};
			menu_well.add_css_class("well");
			append(menu_well);

			well_items = new Gtk.Box(Gtk.Orientation.VERTICAL, 0) {
				vexpand = true,
				valign = Gtk.Align.CENTER,
				hexpand = false,
				halign = Gtk.Align.START,
			};
			menu_well.append(well_items);

			// Add globally available actions to toggle/show/hide
			add_menu_action("_toggle").activate.connect(() => {
				GlobalMenu.instance.toggle();
			});
			add_menu_action("_show").activate.connect(() => {
				GlobalMenu.instance.show();
			});
			add_menu_action("_hide").activate.connect(() => {
				GlobalMenu.instance.hide();
			});

			_hide();
		}

		public ContextualAction add_item(string key, string label) {
			var action = add_menu_action(key);
			var button = new MenuItem();
			button.label = label;
			menu_items.insert(key, button);
			well_items.append(button);

			button.clicked.connect(() => {
				action.activate();
			});

			button.sensitive = action.enabled;
			action.notify["enabled"].connect(() => {
				button.sensitive = action.enabled;
			});
			button.notify["has-focus"].connect(() => {
				if (button.has_focus) {
					last_focus = button;
				}
			});

			if (last_focus == null) {
				last_focus = button;
			}

			return action;
		}

		private void _hide() {
			set_sensitive(false);
			remove_css_class("-is-shown");
			// Ensure the CSS-based animation has ran.
			GLib.Timeout.add_once((uint)(0.15 * 1000), () => {
				// Prevents spamming the button from causing issues.
				if (!this.sensitive) {
					set_visible(false);
				}
			});
		}

		public new void hide() {
			var application = (Application)GLib.Application.get_default();
			application.page_focus_target_pop(this);
			_hide();
		}

		public new void show() {
			var application = (Application)GLib.Application.get_default();
			application.page_focus_target_push(this);
			set_sensitive(true);
			add_css_class("-is-shown");
			set_visible(true);
		}

		public void toggle() {
			if (sensitive) {
				hide();
			}
			else {
				show();
			}
		}

		public override bool grab_focus() {
			last_focus.grab_focus();

			return true;
		}
	}
}
