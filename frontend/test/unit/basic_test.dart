import 'package:flutter_test/flutter_test.dart';

void main() {
  test('String split test', () {
    var string = 'foo,bar,baz';
    expect(string.split(','), equals(['foo', 'bar', 'baz']));
  });

  test('String trim test', () {
    var string = '  foo ';
    expect(string.trim(), equals('foo'));
  });
}
