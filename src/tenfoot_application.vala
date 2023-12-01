namespace Fabric.Tenfoot {
	public class Application : Fabric.UI.Application {
		protected ContextualActionGroup application_actions;
		protected Fabric.UI.PagedWindow window;
		protected Gtk.Widget? contextual_focus_override;
		private Gtk.Window? _previous_window = null;

		public Gtk.Widget focus_widget {
			owned get { return active_window.focus_widget; }
		}

		/**
		 * Triggered when any widget is focused.
		 *
		 * (Used by BottomBar to update the contextual actions.)
		 */
		public signal void focus_widget_changed();

		construct {
			_page_focus_target_stack = new Queue<Gtk.Widget>();
			_widget_focus_for_target_stack = new Queue<Gtk.Widget>();
			application_actions = new ContextualActionGroup();
		}

		// Contextual actions handling {{{

		public void override_contextual_focus(Gtk.Widget? target) {
			if (contextual_focus_override != target) {
				contextual_focus_override = target;
				focus_widget_changed();
			}
		}

		/**
		 * Generally equal to current focus, except for specific modal
		 * "transformations", namely the on-screen keyboard.
		 */
		public Gtk.Widget get_contextual_focus() {
			return
				contextual_focus_override != null
				? contextual_focus_override
				: window.focus_widget
			;
		}

		/**
		 * Activates the action of the focused context, or the application action.
		 */
		public bool activate_contextual_action(string name) {
			var action = get_contextual_action(name);
			if (action == null) { return false; }
			action.activate();
			return true;
		}

		/**
		 * For our own widgets, we'll check for ContextualWidget mixin.
		 */
		public ContextualAction? get_contextual_action(string name, bool skip_disabled = false) {
			ContextualAction action = null;

			var widget = get_contextual_focus();
			while (widget != null) {
				if (widget.get_type().is_a(typeof (ContextualWidget))) {
					var sensitive = (ContextualWidget)widget;
					action = sensitive.contextual_action_for(name);
					if (action != null && !(skip_disabled && !action.enabled)) {
						return action;
					}
				}
				widget = widget.get_parent();
			}

			// No contextual action?
			// Try an application action.
			action = application_actions.lookup(name);

			return action;
		}

		// }}}

		// Keyboard input handling {{{

		private void setup_keyboard() {
			var hotkeys = new Gtk.EventControllerKey();
			hotkeys.key_pressed.connect((keyval, keycode, state) => {
				// TODO: Notify global gamepad to change type (to keyboard)
				switch (keyval) {
					case 0xfe20: // Shift-tab
					case Gdk.Key.Tab:
						/* No-op, since it breaks our focus model */
						break;
					case Gdk.Key.BackSpace:
						activate_contextual_action("gamepad.menu");
						break;
					case Gdk.Key.F3:
						activate_contextual_action("gamepad.options");
						break;
					case Gdk.Key.F4:
						activate_contextual_action("gamepad.overview");
						break;
					case Gdk.Key.Return:
						// XXX might actually be slightly broken, still directly activates focused widgets?
						activate_contextual_action("gamepad.primary");
						break;
					case Gdk.Key.F1:
						activate_contextual_action("gamepad.secondary");
						break;
					case Gdk.Key.F2:
						activate_contextual_action("gamepad.tertiary");
						break;
					case Gdk.Key.Escape:
						activate_contextual_action("gamepad.back");
						break;
					case Gdk.Key.Up:
						activate_contextual_action("gamepad.up");
						break;
					case Gdk.Key.Down:
						activate_contextual_action("gamepad.down");
						break;
					case Gdk.Key.Left:
						activate_contextual_action("gamepad.left");
						break;
					case Gdk.Key.Right:
						activate_contextual_action("gamepad.right");
						break;
					default:
						return false;
				}
				GamepadController.instance.check_gamepad_change(null);
				return true;
			});
			Fabric.UI.PagesContainer.instance.add_controller(hotkeys);
		}

		// }}}

		// Focus handling {{{

		/**
		 * The widget under which focus navigation is currently happening.
		 */
		public Gtk.Widget page_focus_target {
			get;
			private set;
		}

		/**
		 * Stack of widgets where focus was happening.
		 */
		protected Queue<Gtk.Widget> _page_focus_target_stack;
		protected Queue<Gtk.Widget> _widget_focus_for_target_stack;

		/**
		 * Skips some rude widgets from being themselves focused.
		 * Their child will be tried to be focused, still.
		 */
		private bool widget_allowed_for_focus(Gtk.Widget widget) {
			if (widget.get_type().is_a(typeof (Gtk.ScrolledWindow))) {
				return false;
			}
			return true;
		}

		/**
		 * Tries focusing anything on the given widget
		 */
		private bool try_focusing_child(Gtk.Widget widget) {
			if (!widget.visible || !widget.sensitive) {
#if DEBUG_FOCUS
				debug("Not a usable child %s", widget.get_type().name());
#endif
				return false;
			}
			if (widget.grab_focus() && widget_allowed_for_focus(widget)) {
#if DEBUG_FOCUS
				debug("Found a child to focus! %s", widget.get_type().name());
#endif
				return true;
			}
			for (var child = widget.get_first_child(); child != null; child = child.get_next_sibling()) {
				if (try_focusing_child(child)) {
					return true;
				}
			}
			return false;
		}

		public void move_focus(Gtk.DirectionType direction) {
			page_focus_target.child_focus(direction);
		}

		/**
		 * Adds an item to the focus stack
		 */
		public void page_focus_target_push(Gtk.Widget new_focus_target, bool replace = false) {
			if (replace && _page_focus_target_stack.length > 0) {
				_page_focus_target_stack.pop_head();
			}
			if (_page_focus_target_stack.length > 0) {
				var focus = window.focus_widget;
				_widget_focus_for_target_stack.push_head(focus);
			}

			page_focus_target = new_focus_target;
			_page_focus_target_stack.push_head(new_focus_target);
			GLib.Idle.add_once(() => {
				// Tell the widget to handle initial focus by itself
				if (!try_focusing_child(page_focus_target)) {
#if DEBUG_FOCUS
					debug("Couldn't find something to focus on '%s'; trying something silly.", page_focus_target.get_type().name());
#endif
					// Last ditch effort at gettiny anything focused...
					page_focus_target.child_focus(Gtk.DirectionType.TAB_FORWARD);
					page_focus_target.child_focus(Gtk.DirectionType.TAB_BACKWARD);
				}
			});
		}
		/**
		 * Removes an item from the focus stack
		 */
		public void page_focus_target_pop(Gtk.Widget widget) {
			if (page_focus_target != widget) {
				error("Error: popping wrong widget from focus target!");
			}
			_page_focus_target_stack.pop_head();
			page_focus_target = _page_focus_target_stack.peek_head();
			// TODO: Restore saved focus location
			GLib.Idle.add_once(() => {
				var previous = _widget_focus_for_target_stack.pop_head();
				if (previous != null) {
					window.focus_widget = previous;
				}
			});
		}
		/**
		 * Replace the current top of the focus stack
		 */
		public void page_focus_target_replace(Gtk.Widget widget) {
			page_focus_target_push(widget, true);
		}

		/**
		 * Goes through viewports and ensures the focused widget is visible.
		 */
		public void ensure_visible(Gtk.Widget focus_widget) {
			var widget = focus_widget;
			while (widget != null) {
				if (widget.get_type().is_a(typeof (Gtk.Viewport))) {
					var viewport = (Gtk.Viewport)widget;
					Graphene.Rect bounds = {};
					if (focus_widget.compute_bounds(viewport.get_child(), out bounds)) {
						Graphene.Point point = {};
						if (focus_widget.compute_point(viewport, point, out point)) {
							if (point.y < 0) {
								viewport.vadjustment.value = bounds.origin.y;
							}
							else if ((point.y + bounds.size.height) > viewport.vadjustment.get_page_size()) {
								viewport.vadjustment.value = bounds.origin.y - viewport.vadjustment.page_size + bounds.size.height;
							}
						}
					}
				}
				widget = widget.get_parent();
			}
		}

		// }}}

		// Logical actions {{{

		/**
		 * Adds logical controller actions.
		 *
		 * Not tied to a specific button position, but to logical use.
		 */
		private ContextualAction get_gamepad_action(string key) {
			var _key = "gamepad.%s".printf(key);

			var action = application_actions.lookup(_key);
			if (action == null) {
				action = new ContextualAction(_key, null);
				application_actions.insert(_key, action);
#if 0
				action.activate.connect(() => {
					debug("GAMEPAD ACTION: %s", key);
				});
#endif
			}

			return action;
		}

		private void setup_controller_actions() {
			Fabric.UI.PagesContainer.instance.notify["current"].connect(() => {
				page_focus_target_replace(Fabric.UI.PagesContainer.instance.current);
			});
			get_gamepad_action("up").activate.connect(() => {
// TODO: if window.focus_widget is the same, try to scroll up the first of its parent that can be
//  -> -1*minimum_increment
				page_focus_target.child_focus(Gtk.DirectionType.UP);
			});
			get_gamepad_action("down").activate.connect(() => {
// TODO: if window.focus_widget is the same, try to scroll down the first of its parent that can be
//  -> +1*minimum_increment
				page_focus_target.child_focus(Gtk.DirectionType.DOWN);
			});
			get_gamepad_action("left").activate.connect(() => {
				page_focus_target.child_focus(Gtk.DirectionType.LEFT);
			});
			get_gamepad_action("right").activate.connect(() => {
				page_focus_target.child_focus(Gtk.DirectionType.RIGHT);
			});

			// Activate button
			var gamepad_primary = get_gamepad_action("primary");
			gamepad_primary.label = "Select";
			notify["active-window"].connect(() => {
				if (_previous_window != null) {
					_previous_window.notify["focus-widget"].disconnect(application_action_focused_widget_handler);
				}
				active_window.notify["focus-widget"].connect(application_action_focused_widget_handler);
				_previous_window = active_window;
			});
			gamepad_primary.activate.connect(() => {
				var widget = active_window.focus_widget;
				if (widget != null) {
					if (widget.get_type().is_a(typeof (Gtk.Button))) {
						((Gtk.Button)widget).clicked();
					}
					else {
						widget.activate_default();
					}
				}
			});

			// Default back button handling
			var gamepad_back = get_gamepad_action("back");
			gamepad_back.enabled = false;
			gamepad_back.label = "Back";

			// Menu button
			var button_menu = get_gamepad_action("menu");
			button_menu.label = "Menu";
			button_menu.enabled = true;
			button_menu.activate.connect(() => {
				GlobalMenu.activate_menu_action("_toggle");
			});
		}

		private void application_action_focused_widget_handler() {
			var gamepad_select = get_gamepad_action("select");
			var widget = active_window.focus_widget;
			if (widget != null) {
				gamepad_select.enabled = widget.sensitive;
			}
			focus_widget_changed();
		}

		// }}}

		protected override void activate() {
			add_styles_from_resource("/Fabric/Tenfoot/styles.css");

			setup_controller_actions();
			setup_keyboard();
			GamepadController.instance.application = this;

			var container = Fabric.UI.PagesContainer.instance;
			container.orientation = Gtk.Orientation.VERTICAL;
			OnScreenKeyboard.instance.application = this;
			container.append(OnScreenKeyboard.instance);
			container.append(BottomBar.instance);
			container.add_overlay(GlobalMenu.instance);
			container.add_overlay(ModalLayer.instance);
		}
	}
}
