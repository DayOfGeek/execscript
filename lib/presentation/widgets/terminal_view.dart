// ExecScript - Mobile SSH Script Execution
// Copyright (C) 2026 DayOfGeek.com
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../services/ssh_service.dart';

/// Widget for displaying terminal output with horizontal scrolling
class TerminalView extends StatefulWidget {
  final List<SSHOutput> outputs;
  final bool isRunning;
  final ScrollController? scrollController;
  final VoidCallback? onScrollToBottom;

  const TerminalView({
    super.key,
    required this.outputs,
    this.isRunning = false,
    this.scrollController,
    this.onScrollToBottom,
  });

  @override
  State<TerminalView> createState() => _TerminalViewState();
}

class _TerminalViewState extends State<TerminalView> {
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<CyberTermThemeExtension>();
    final background = colors?.background ?? CyberTermColors.background;
    final primary = colors?.primary ?? CyberTermColors.primary;
    final surface = colors?.surface ?? CyberTermColors.surface;

    return Container(
      color: background,
      child: ScrollbarTheme(
        data: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(primary.withAlpha(128)),
          trackColor: WidgetStateProperty.all(surface),
          thickness: WidgetStateProperty.all(6),
          radius: Radius.zero, // Sharp corners for terminal aesthetic
          minThumbLength: 40,
        ),
        child: Scrollbar(
          controller: _horizontalScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 2000, // Large width to accommodate long lines
              child: ListView.builder(
                controller: widget.scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: widget.outputs.length + (widget.isRunning ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= widget.outputs.length) {
                    return _buildCursor(colors);
                  }
                  return _buildOutputLine(
                    context,
                    widget.outputs[index],
                    colors,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutputLine(
    BuildContext context,
    SSHOutput output,
    CyberTermThemeExtension? colors,
  ) {
    final timestamp = _formatTimestamp(output.timestamp);
    final textMuted = colors?.textMuted ?? CyberTermColors.textMuted;
    final error = colors?.error ?? CyberTermColors.error;
    final primaryDim = colors?.primaryDim ?? CyberTermColors.primaryDim;
    final textColor = colors?.textColor ?? CyberTermColors.textColor;
    final surface = colors?.surface ?? CyberTermColors.surface;
    final success = colors?.success ?? CyberTermColors.success;

    return InkWell(
      onTap: () {
        // Copy line to clipboard (placeholder - clipboard functionality would go here)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '[COPIED]',
              style: GoogleFonts.jetBrainsMono(color: success),
            ),
            backgroundColor: surface,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Timestamp
            Text(
              timestamp,
              style: GoogleFonts.jetBrainsMono(fontSize: 10, color: textMuted),
            ),
            const SizedBox(width: 8),
            // Output indicator
            Text(
              output.isError ? '[ERR]' : '[OUT]',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: output.isError ? error : primaryDim,
              ),
            ),
            const SizedBox(width: 8),
            // Content - NO WRAP, extends horizontally
            Text(
              output.content,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                color: output.isError ? error : textColor,
                height: 1.3,
              ),
              softWrap: false,
              overflow: TextOverflow.visible,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCursor(CyberTermThemeExtension? colors) {
    final textMuted = colors?.textMuted ?? CyberTermColors.textMuted;
    final warning = colors?.warning ?? CyberTermColors.warning;
    final primary = colors?.primary ?? CyberTermColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatTimestamp(DateTime.now()),
            style: GoogleFonts.jetBrainsMono(fontSize: 10, color: textMuted),
          ),
          const SizedBox(width: 8),
          Text(
            '[RUN]',
            style: GoogleFonts.jetBrainsMono(fontSize: 10, color: warning),
          ),
          const SizedBox(width: 8),
          BlinkingCursor(color: primary, fontSize: 12),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final second = timestamp.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}

/// Compact terminal output widget for lists
class TerminalOutputPreview extends StatelessWidget {
  final String? output;
  final int maxLines;

  const TerminalOutputPreview({super.key, this.output, this.maxLines = 3});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<CyberTermThemeExtension>();
    final textMuted = colors?.textMuted ?? CyberTermColors.textMuted;
    final background = colors?.background ?? CyberTermColors.background;
    final border = colors?.border ?? CyberTermColors.border;
    final textDim = colors?.textDim ?? CyberTermColors.textDim;

    if (output == null || output!.isEmpty) {
      return Text(
        '[NO OUTPUT]',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          color: textMuted,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final lines = output!.split('\n');
    final displayLines = lines.take(maxLines).join('\n');
    final hasMore = lines.length > maxLines;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayLines,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: textDim,
              height: 1.3,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
          if (hasMore)
            Text(
              '... ${lines.length - maxLines} more lines',
              style: GoogleFonts.jetBrainsMono(fontSize: 9, color: textMuted),
            ),
        ],
      ),
    );
  }
}
