import 'dart:io';

void main() async {
  print('Génération des fichiers Hive...');
  
  // Générer les adaptateurs Hive
  final result = await Process.run(
    'flutter',
    ['packages', 'pub', 'run', 'build_runner', 'build', '--delete-conflicting-outputs'],
    workingDirectory: Directory.current.path,
  );
  
  if (result.exitCode == 0) {
    print('✅ Génération des fichiers Hive réussie !');
    print(result.stdout);
  } else {
    print('❌ Erreur lors de la génération des fichiers Hive :');
    print(result.stderr);
    exit(1);
  }
}
