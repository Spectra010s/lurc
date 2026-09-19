import 'package:flutter/material.dart';
import 'package:lurc/theme/lurc_theme.dart';

/// Keeps editing and inspecting usable without allocating a fixed screen share.
class RequestWorkspace extends StatefulWidget {
  const new({
    required this.requestBar,
    required this.editor,
    required this.response,
    required this.loading,
    required this.result,
    super.key,
  });

  final Widget requestBar;
  final Widget editor;
  final Widget response;
  final bool loading;
  final Object? result;

  @override
  State<RequestWorkspace> createState() => _RequestWorkspaceState();
}

class _RequestWorkspaceState extends State<RequestWorkspace> {
  bool _showResponse = false;
  final GlobalKey<State<StatefulWidget>> _barKey = GlobalKey();
  final GlobalKey<State<StatefulWidget>> _editorKey = GlobalKey();
  final GlobalKey<State<StatefulWidget>> _responseKey = GlobalKey();

  @override
  void didUpdateWidget(covariant RequestWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((!oldWidget.loading && widget.loading) ||
        (widget.result != null && widget.result != oldWidget.result)) {
      _showResponse = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _showResponse) FocusScope.of(context).unfocus();
      });
    }
  }

  void _selectPanel(bool response) {
    if (response) FocusScope.of(context).unfocus();
    setState(() => _showResponse = response);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // A landscape keyboard can leave less space than the request bar itself.
      // Let the whole workspace scroll in that case instead of overflowing.
      final minimumHeight = 320 * MediaQuery.textScalerOf(context).scale(1);
      if (constraints.maxHeight < minimumHeight) {
        return SingleChildScrollView(
          child: SizedBox(height: minimumHeight, child: _panels(wide: false)),
        );
      }
      return _panels(wide: constraints.maxWidth >= 840);
    },
  );

  Widget _panels({required bool wide}) => Column(
    children: [
      KeyedSubtree(key: _barKey, child: widget.requestBar),
      const SizedBox(height: LurcSpacing.xs),
      Expanded(
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _panel('Request', _editor)),
                  const VerticalDivider(width: 1),
                  Expanded(child: _panel('Response', _response)),
                ],
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      LurcSpacing.lg,
                      0,
                      LurcSpacing.lg,
                      LurcSpacing.sm,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<bool>(
                        showSelectedIcon: false,
                        segments: [
                          const ButtonSegment(
                            value: false,
                            icon: Icon(Icons.edit_outlined),
                            label: Text('Request'),
                          ),
                          ButtonSegment(
                            value: true,
                            icon: widget.loading
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.data_object_rounded),
                            label: Text(
                              widget.loading ? 'Sending…' : 'Response',
                            ),
                          ),
                        ],
                        selected: {_showResponse},
                        onSelectionChanged: (selection) =>
                            _selectPanel(selection.single),
                      ),
                    ),
                  ),
                  Expanded(
                    // Both panels stay mounted so tabs, drafts, and scroll
                    // positions survive switching between request and response.
                    child: IndexedStack(
                      index: _showResponse ? 1 : 0,
                      children: [_editor, _response],
                    ),
                  ),
                ],
              ),
      ),
    ],
  );

  Widget get _editor => KeyedSubtree(key: _editorKey, child: widget.editor);

  Widget get _response =>
      KeyedSubtree(key: _responseKey, child: widget.response);

  Widget _panel(String title, Widget child) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          LurcSpacing.lg,
          LurcSpacing.sm,
          LurcSpacing.lg,
          LurcSpacing.sm,
        ),
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      const Divider(height: 1),
      Expanded(child: child),
    ],
  );
}
