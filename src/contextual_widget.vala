namespace Fabric.Tenfoot {
	private class ContextualActionGroups : HashTable<weak Gtk.Widget, ContextualActionGroup> {
		public ContextualActionGroups() {
			base(direct_hash, direct_equal);
		}
	}

	/**
	 * Lookup table for our mixin-owned variables.
	 * (Interface/Mixins can't add new members to classes)
	 */
	private ContextualActionGroups _contextual_action_groups;

	/**
	 * Add to the hierarchy of new widgets to allow attaching
	 * context-sensitive actions to the widget, which will be exposed via
	 * the bottom bar to the end-user.
	 */
	public interface ContextualWidget : Gtk.Widget {
		private ContextualActionGroup? get_action_group_for_this(bool create = false) {
			if (_contextual_action_groups == null) {
				_contextual_action_groups = new ContextualActionGroups();
			}
			var group = _contextual_action_groups.lookup(this);
			if (group == null && create) {
				group = new ContextualActionGroup();
				_contextual_action_groups.insert(this, group);
				this.destroy.connect(dispose_of_group);
			}

			return group;
		}
		private ContextualAction? _contextual_action_for(string name, bool create = false) {
			var group = get_action_group_for_this(create);
			if (group == null) { return null; }
			var action = (ContextualAction)group.lookup(name);
			if (action == null && create) {
				action = new ContextualAction(name, null);
				group.insert(name, action);
			}
			return action;
		}

		/**
		 * Create a new contextual action assigned to this widget,
		 * for the given name, and assign the given label.
		 */
		public ContextualAction contextual_action_add(string name, string label) {
			var action = _contextual_action_for(name, true);
			action.label = label;
			return action;
		}

		/**
		 * Returns the contextual action this widget, for the given name, if
		 * it exists, otherwise null.
		 */
		public ContextualAction contextual_action_for(string name) {
			return _contextual_action_for(name);
		}

		/**
		 * Activates the contextual action for this widget, for the given
		 * name, if it exists.
		 *
		 * Returns true if an action was activated, otherwise false.
		 */
		public bool activate_contextual_action(string name) {
			var action = _contextual_action_for(name);
			if (action == null) { return false; }
			action.activate();

			return true;
		}

		private void dispose_of_group() {
			_contextual_action_groups.remove(this);
		}
	}
}
