import 'dart:io';

void main() async {
  print('Running dart analyze...');
  final result = await Process.run('dart', ['analyze', '--format=machine']);
  final file = File('analyze_results.txt');
  await file.writeAsString(result.stdout.toString() + '\n' + result.stderr.toString());
  print('Done.');
}
