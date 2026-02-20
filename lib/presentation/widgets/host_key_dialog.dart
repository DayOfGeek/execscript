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

/// Trust level for host keys
enum HostKeyTrust { once, always, never }

/// Dialog for host key verification
class HostKeyDialog extends StatelessWidget {
  final String fingerprint;
  final String serverName;
  final bool isNewKey;
  final String? expectedFingerprint;

  const HostKeyDialog({
    super.key,
    required this.fingerprint,
    required this.serverName,
    required this.isNewKey,
    this.expectedFingerprint,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CyberTermColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(
          color: isNewKey ? CyberTermColors.warning : CyberTermColors.error,
          width: 1,
        ),
      ),
      title: Row(
        children: [
          Icon(
            isNewKey ? Icons.warning : Icons.error,
            color: isNewKey ? CyberTermColors.warning : CyberTermColors.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            isNewKey ? '[NEW HOST KEY]' : '[HOST KEY CHANGED]',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isNewKey ? CyberTermColors.warning : CyberTermColors.error,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Server: $serverName',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              color: CyberTermColors.textColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CyberTermColors.background,
              border: Border.all(color: CyberTermColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '[FINGERPRINT]',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: CyberTermColors.primaryDim,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  fingerprint,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: CyberTermColors.textColor,
                  ),
                ),
              ],
            ),
          ),
          if (!isNewKey && expectedFingerprint != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CyberTermColors.background,
                border: Border.all(color: CyberTermColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '[EXPECTED]',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: CyberTermColors.primaryDim,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    expectedFingerprint!,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: CyberTermColors.textMuted,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'WARNING: Fingerprint mismatch detected!',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: CyberTermColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This may indicate a man-in-the-middle attack.',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: CyberTermColors.textDim,
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Text(
              'Do you want to trust this host key?',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                color: CyberTermColors.textDim,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, HostKeyTrust.never),
          child: Text(
            '[CANCEL]',
            style: GoogleFonts.jetBrainsMono(
              color: CyberTermColors.textDim,
              fontSize: 12,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, HostKeyTrust.once),
          child: Text(
            '[TRUST ONCE]',
            style: GoogleFonts.jetBrainsMono(
              color: CyberTermColors.warning,
              fontSize: 12,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, HostKeyTrust.always),
          child: Text(
            '[TRUST ALWAYS]',
            style: GoogleFonts.jetBrainsMono(
              color: CyberTermColors.success,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
