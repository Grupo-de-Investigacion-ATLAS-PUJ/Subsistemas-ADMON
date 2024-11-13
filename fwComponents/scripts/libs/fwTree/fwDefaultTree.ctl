// node clicked on editor Tree
void DEFAULT_editor_selected(string node, string parent)
{
}

// node right-clicked on editor Tree
void DEFAULT_editor_entered(string node, string parent)
{
	fwTreeDisplay_editorStd(node, parent);
}

// node clicked on navigator Tree
void DEFAULT_navigator_selected(string node, string parent)
{
}

// node right-clicked on navigator Tree
void DEFAULT_navigator_entered(string node, string parent)
{
	fwTreeDisplay_navigatorStd(node, parent);
}

// "Seetings" button selected on editor Tree
// Please add the opening of your "settings" panel
void DEFAULT_nodeSettings(string node, string parent)
{
}

// "View" button selected on navigator Tree
// Please add the opening of your "view" panel
void DEFAULT_nodeView(string node, string parent)
{
}

// The following routines are available in case of need
void DEFAULT_nodeAdded(string new_node, string parent)
{
	DebugTN("Added "+new_node+" to "+parent);
}

void DEFAULT_nodeRemoved(string node, string parent)
{
	DebugTN("Removed "+node+" from "+parent);
}

void DEFAULT_nodeCut(string node, string parent)
{
	DebugTN("Cut "+node+" from "+parent);
}

void DEFAULT_nodePasted(string node, string parent)
{
	DebugTN("Pasted "+node+" to "+parent);
}

void DEFAULT_nodeRenamed(string old_node, string new_node)
{
	DebugTN("Renamed "+old_node+" to "+new_node);
}

void DEFAULT_nodeReordered(string node)
{
	DebugTN("Reordered "+node);
}
