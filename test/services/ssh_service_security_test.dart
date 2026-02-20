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


import 'package:flutter_test/flutter_test.dart';
import 'package:execscript/services/ssh_service.dart';

void main() {
  group('HostKeyVerificationException', () {
    test('formats message correctly', () {
      final exception = HostKeyVerificationException(
        expected: 'aa:bb:cc:dd:ee:ff',
        received: '11:22:33:44:55:66',
      );

      expect(exception.message, contains('HOST KEY VERIFICATION FAILED'));
      expect(exception.message, contains('aa:bb:cc:dd:ee:ff'));
      expect(exception.message, contains('11:22:33:44:55:66'));
      expect(exception.message, contains('MITM'));
    });

    test('toString returns message', () {
      final exception = HostKeyVerificationException(
        expected: 'aa:bb:cc',
        received: 'dd:ee:ff',
      );

      expect(exception.toString(), equals(exception.message));
    });

    test('stores expected and received fingerprints', () {
      final exception = HostKeyVerificationException(
        expected: 'expected-fingerprint',
        received: 'received-fingerprint',
      );

      expect(exception.expected, 'expected-fingerprint');
      expect(exception.received, 'received-fingerprint');
    });
  });

  group('NewHostKeyException', () {
    test('formats message correctly', () {
      final exception = NewHostKeyException(
        fingerprint: 'aa:bb:cc:dd:ee:ff',
        serverName: 'TestServer',
        hostKeyType: 'ssh-rsa',
      );

      expect(exception.toString(), contains('New host key for TestServer'));
      expect(exception.toString(), contains('aa:bb:cc:dd:ee:ff'));
      expect(exception.toString(), contains('ssh-rsa'));
    });

    test('stores fingerprint and server name', () {
      final exception = NewHostKeyException(
        fingerprint: 'fingerprint-data',
        serverName: 'MyServer',
        hostKeyType: 'ssh-ed25519',
      );

      expect(exception.fingerprint, 'fingerprint-data');
      expect(exception.serverName, 'MyServer');
      expect(exception.hostKeyType, 'ssh-ed25519');
    });
  });
}
