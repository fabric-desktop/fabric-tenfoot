namespace Fabric.Tenfoot {
	/**
	 * Massages weirdnesses out of Gtk.Entry...
	 */
	public class TextInput : Gtk.Entry, ContextualWidget {
		construct {
			var text = get_first_child();
			// Ensures text is not selected on focus navigation.
			// It would be fine in a normal keyboard-based focus (TAB)
			// situation, but with up/down controller it's not good.
			text.notify["has-focus"].connect(() => {
				GLib.Idle.add_once(() => {
					select_region(this.text.length, this.text.length);
				});
			});

			contextual_action_add("gamepad.primary", "Edit").activate.connect(() => {
				OnScreenKeyboard.instance.show(true);
			});

			var touch_handler = new Gtk.GestureClick();
			touch_handler.propagation_phase = Gtk.PropagationPhase.CAPTURE;
			touch_handler.touch_only = true;
			touch_handler.released.connect(() => {
				OnScreenKeyboard.instance.show(false);
			});
			add_controller(touch_handler);
		}
	}

	/**
	 * Same as TextInput, but for Gtk.PasswordEntry
	 *
	 * (Since PasswordEntry is sealed, we have to re-implement it badly...)
	 */
	public class PasswordInput : TextInput {
		construct {
			buffer = new Gtk.PasswordEntryBuffer();
			visibility = false;

			contextual_action_add("gamepad.overview", "Reveal").activate.connect(() => {
				visibility = !visibility;
			});
		}
	}
}
