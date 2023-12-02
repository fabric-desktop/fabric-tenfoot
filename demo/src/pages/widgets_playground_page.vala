using Fabric.Tenfoot;
using Fabric.UI.Helpers;

namespace FabricDemo.Tenfoot.Pages {
	class WidgetsPlayground : Base {
		const string[] numbers = { // {{{
			"zero",
			"one",
			"two",
			"three",
			"four",
			"five",
			"six",
			"seven",
			"eight",
			"nine",
			"ten",
			"eleven",
			"twelve",
			"thirteen",
			"fourteen",
			"fifteen",
			"sixteen",
			"seventeen",
			"eighteen",
			"nineteen",
			"twenty",
			"twenty-one",
			"twenty-two",
			"twenty-three",
			"twenty-four",
			"twenty-five",
			"twenty-six",
			"twenty-seven",
			"twenty-eight",
			"twenty-nine",
			"thirty",
			"thirty-one",
			"thirty-two",
			"thirty-three",
			"thirty-four",
			"thirty-five",
			"thirty-six",
			"thirty-seven",
			"thirty-eight",
			"thirty-nine",
			"forty",
			"forty-one",
			"forty-two",
			"forty-three",
			"forty-four",
			"forty-five",
			"forty-six",
			"forty-seven",
			"forty-eight",
			"forty-nine",
			"fifty",
			"fifty-one",
			"fifty-two",
			"fifty-three",
			"fifty-four",
			"fifty-five",
			"fifty-six",
			"fifty-seven",
			"fifty-eight",
			"fifty-nine",
			"sixty",
			"sixty-one",
			"sixty-two",
			"sixty-three",
			"sixty-four",
			"sixty-five",
			"sixty-six",
			"sixty-seven",
			"sixty-eight",
			"sixty-nine",
			"seventy",
			"seventy-one",
			"seventy-two",
			"seventy-three",
			"seventy-four",
			"seventy-five",
			"seventy-six",
			"seventy-seven",
			"seventy-eight",
			"seventy-nine",
			"eighty",
			"eighty-one",
			"eighty-two",
			"eighty-three",
			"eighty-four",
			"eighty-five",
			"eighty-six",
			"eighty-seven",
			"eighty-eight",
			"eighty-nine",
			"ninety",
			"ninety-one",
			"ninety-two",
			"ninety-three",
			"ninety-four",
			"ninety-five",
			"ninety-six",
			"ninety-seven",
			"ninety-eight",
			"ninety-nine",
			"one hundred",
		}; // }}}

		// {{{
		/**
		 * Holds a number for ListStore and DropDown usage...
		 * Ugh...
		 */
		private class NumberHolder : Object {
			public uint number { get; set; }
			public NumberHolder(uint i) {
				number = i;
			}
		}

		/**
		 * Maps from NumberHolder to a string.
		 */
		static string num_to_string(NumberHolder num) {
//debug("#num_to_string %u", num.number);
			if (num.number > 100) {
				return "Way too big...";
			}
			return numbers[num.number];
		}
		// }}}

		private Gtk.Separator make_separator() {
			var sep = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
			append(sep);

			return sep;
		}

		private DropDown make_demo_dropdown(string label, uint max) {
			var row = new InputRow(label);
			append(row);
			var model = new ListStore(typeof (NumberHolder));
			for (int i = 1; i <= max; i++) {
				model.append(new NumberHolder(i));
			}
			var expr = new Gtk.CClosureExpression(
				typeof (string)
				, null, {}
				, (Callback) num_to_string
				, null, null
				);
			var dropdown = new DropDown(model, expr);
			row.widget = dropdown;

			return dropdown;
		}

		construct {
			add_css_class("page-test");
			add_css_class("form-container");

			append(make_subheading("Nulla a justo ac elit pellentesque"));
			append(make_text("Curabitur sit amet orci maximus magna tincidunt malesuada sit amet ac lorem."));
			make_separator();

			// Shows text input usage
			append(make_text("Fusce malesuada sem."));
			{
				var row = new InputRow("Vivamus commodo");
				append(row);
				var entry = new TextInput();
				row.widget = entry;
			}

			make_separator();

			// Shows password input usage
			append(make_text("Ut id augue mauris. Curabitur nulla urna."));
			{
				var row = new InputRow("Curabitur");
				append(row);
				var entry = new PasswordInput();
				row.widget = entry;
			}
			{
				var row = new InputRow("Curabitur sit");
				append(row);
				var entry = new PasswordInput();
				row.widget = entry;
			}

			make_separator();

			// Shows switch usage.
			append(make_text("Suspendisse ullamcorper nisi id luctus commodo."));
			{
				var row = new InputRow("Aenean porttitor");
				append(row);
				Gtk.Switch toggle = new Gtk.Switch();
				row.widget = toggle;
			}

			make_separator();

			// Shows dropdown usage.
			make_demo_dropdown("Quisque vitae (3)", 3);
			make_demo_dropdown("Quisque vitae scelerisque", 100).selected = 50;

			make_separator();

			// Shows showing a dialog box.
			append(make_text("Donec vestibulum ipsum eu nulla interdum, at consectetur urna porta."));
			{
				var row = new InputRow("Praesent non nibh eget");
				var button = new Button() {
					halign = Gtk.Align.END,
				};
				button.label = "Show";
				button.clicked.connect(() => {
					var dialog = new Dialog();
					dialog.set_title("Aliquam ornare augue");

					var label = new Gtk.Label("Duis semper nunc sit amet lobortis lobortis. Praesent non nibh eget est maximus imperdiet et id ligula. Sed ut porta elit. Proin fringilla, magna a laoreet sodales, purus neque aliquam risus, sit amet porttitor odio lorem ut mauris. Vivamus sed purus eros. Donec interdum augue eget sollicitudin ultricies. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas.");
					label.wrap = true;
					dialog.append(label);

					// The cancel button will hook to the back button correctly.
					dialog.add_cancel_button();
					dialog.cancel.connect(dialog.close);

					// The ok button will hook to the primary button correctly.
					dialog.add_ok_button(true).clicked.connect(() => {
						dialog.close();
					});

					// Show the dialog.
					dialog.show_modal();
				});
				row.widget = button;
				append(row);
			}

			make_separator();

			// Shows mapping additional actions to a widget.
			append(make_text("In efficitur, enim eget hendrerit volutpat."));
			{
				var row = new InputRow("Phasellus auctor metus");
				var button = new Button() {
					halign = Gtk.Align.END,
				};
				button.label = "Actions";

				button.clicked
					.connect(() => { debug("Button clicked..."); })
				;
				// You generally would add them to a full page, or an intermediary context (e.g. a list of things).
				// Adding this on buttons means they won't be visible in touch or click scenarios, until focused.
				button.contextual_action_add("gamepad.secondary", "Delete").activate
					.connect(() => { debug("Delete action..."); })
				;
				button.contextual_action_add("gamepad.tertiary", "Filter").activate
					.connect(() => { debug("Filter action..."); })
				;
				row.widget = button;
				append(row);
			}
		}
	}
}
