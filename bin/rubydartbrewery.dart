import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:ruby_dart_brewery/ruby_dart_brewery.dart';

StringBuffer versionsFile = new StringBuffer();

void main(List<String> arguments) {

  var parser = new ArgParser();
  parser.addOption('output-path', defaultsTo: './');

  var results = parser.parse(arguments);
  Directory outputDirectory = new Directory(results['output-path']);

  var client = new http.Client();

  writeCask(outputDirectory, "DartEditorDev", "dart-editor-dev.rb", client, devRootUrl, "editor/darteditor-macos-x64.zip", '''
# conflicts_with 'dart-editor-edge', :because => 'installation of dart-dsk tools in path'
# conflicts_with 'dart-editor-edge-cs', :because => 'installation of dart-dsk tools in path'
# conflicts_with 'dart-editor-stable', :because => 'installation of dart-dsk tools in path'
''' + DART_INSTALL_SECTION, "[Changes](https://storage.googleapis.com/dart-archive/channels/dev/release/latest/changelog.html)")
    .catchError((e, stack) {
        print("DartEditorDev: ${e} ${stack}");     // Finally, callback fires.
        exitCode = 2;
        return -1;
      })
    .then((_) => writeCask(outputDirectory, "DartEditorEdge", "dart-editor-edge.rb", client, rawRootUrl, "editor/darteditor-macos-x64.zip",  '''
# conflicts_with 'dart-editor-dev', :because => 'installation of dart-dsk tools in path'
# conflicts_with 'dart-editor-edge-cs', :because => 'installation of dart-dsk tools in path'
# conflicts_with 'dart-editor-stable', :because => 'installation of dart-dsk tools in path'
        ''' + DART_INSTALL_SECTION, "-"))
    .catchError((e, stack) {
        print("DartEditorEdge: ${e} ${stack}");     // Finally, callback fires.
        exitCode = 2;
        return -1;
      })
    .then((_) => writeCaskWithCs(outputDirectory, "DartEditorEdgeCs", "dart-editor-edge-cs.rb", client, rawRootUrl, "editor/darteditor-macos-x64.zip",  '''
# conflicts_with 'dart-editor-dev', :because => 'installation of dart-dsk tools in path'
# conflicts_with 'dart-editor-edge', :because => 'installation of dart-dsk tools in path'
# conflicts_with 'dart-editor-stable', :because => 'installation of dart-dsk tools in path'
        ''' + DART_INSTALL_SECTION, "-"))
    .catchError((e, stack) {
        print("DartEditorEdgeCs: ${e} ${stack}");     // Finally, callback fires.
        exitCode = 2;
        return -1;
      })
    .then((_) => writeCask(outputDirectory, "DartEditorStable", "dart-editor-stable.rb", client, stableRootUrl, "editor/darteditor-macos-x64.zip",  '''
# conflicts_with 'dart-editor-dev', :because => 'installation of dart-dsk tools in path'
# conflicts_with 'dart-editor-edge', :because => 'installation of dart-dsk tools in path'
# conflicts_with 'dart-editor-edge-cs', :because => 'installation of dart-dsk tools in path'
        ''' + DART_INSTALL_SECTION, "[Changes](https://storage.googleapis.com/dart-archive/channels/stable/release/latest/changelog.html)"))
    .catchError((e, stack) {
        print("DartEditorStable: ${e} ${stack}");     // Finally, callback fires.
        exitCode = 2;
        return -1;
      })
    .then((_) => writeCask(outputDirectory, "DartContentShellDev", "dart-content-shell-dev.rb", client, devRootUrl, "dartium/content_shell-macos-ia32-release.zip",  '''
# conflicts_with 'dart-content-shell-edge', :because => 'installation of dart-dsk tools in path'
# conflicts_with 'dart-content-shell-stable', :because => 'installation of dart-dsk tools in path'
        ''' + CS_INSTALL_SECTION, "-"))
    .catchError((e, stack) {
        print("DartContentShellDev: ${e} ${stack}");     // Finally, callback fires.
        exitCode = 2;
        return -1;
      })
    .then((_) => writeCaskWithCs(outputDirectory, "DartContentShellEdge", "dart-content-shell-edge.rb", client, rawRootUrl, "dartium/content_shell-macos-ia32-release.zip",  '''
# conflicts_with 'dart-content-shell-dev', :because => 'installation of dart-dsk tools in path'
# conflicts_with 'dart-content-shell-stable', :because => 'installation of dart-dsk tools in path'
        ''' + CS_INSTALL_SECTION, "-"))
    .catchError((e, stack) {
        print("DartContentShellEdge: ${e} ${stack}");     // Finally, callback fires.
        exitCode = 2;
        return -1;
      })
    .then((_) => writeCask(outputDirectory, "DartContentShellStable", "dart-content-shell-stable.rb", client, stableRootUrl, "dartium/content_shell-macos-ia32-release.zip",  '''
# conflicts_with 'dart-content-shell-dev', :because => 'installation of dart-dsk tools in path'
# conflicts_with 'dart-content-shell-edge', :because => 'installation of dart-dsk tools in path'
        ''' + CS_INSTALL_SECTION, "-"))
    .catchError((e, stack) {
        print("DartContentShellStable: ${e} ${stack}");     // Finally, callback fires.
        exitCode = 2;
        return -1;
      })
    .then((_) {
      File outputFile = new File(outputDirectory.path + "/dart_versions.txt");
      return outputFile.create(recursive: true);
    })
    .then((file){
      return file.writeAsString('''| Edition | Version | Revision | Archive | MD5 | Notes |
| ------- | ------- | -------- | ------- | --- | ----- |
''');
    })
    .then((file){
      String verBody = versionsFile.toString();
      if (verBody != null && verBody != "")
        file.writeAsString(verBody, mode: FileMode.APPEND);
  });
}

Future writeCask(Directory outputDirectory, String caskClassName,
                 String caskFileName, http.Client client, String rootUrl,
                 String zipPath, String installSection, String notes) {
  String releaseVersionFileUrl = "${rootUrl}/latest/VERSION";
  String release_version, release_revision, base_url, url, md5FileUrl, md5, csMd5FileUrl, cs_md5, cs_url;
  bool isRawCsAvailable = false;

  return client.read(releaseVersionFileUrl).then((String body) {
    release_version = versionRegex.firstMatch(body).group(1);
    release_revision = revisionRegex.firstMatch(body).group(1);
    base_url = "${rootUrl}/${release_revision}";
    url = "${base_url}/${zipPath}";
    md5FileUrl = "${url}.md5sum";
    csMd5FileUrl = "${base_url}/dartium/content_shell-macos-ia32-release.zip.md5sum";

    return client.read(md5FileUrl);
  }).then((String body) {
    if (body == null) return null;
    md5 = md5Regex.firstMatch(body).group(1);

    return client.read(csMd5FileUrl);
  }).then((String body) {
    if (body == null) return null;
    cs_md5 = md5Regex.firstMatch(body).group(1);

    isRawCsAvailable = cs_md5 != "xml";

    // Torn between using release_revision and release_version for cask version :/
    versionsFile.write("| ${caskClassName} | ${release_version} | ${release_revision} | [Zip](${url}) | [md5]($md5FileUrl) | ${notes} |\n");
    String cask = createDartEditorCask(caskClassName, url, release_revision, md5, isRawCsAvailable, installSection);
    File outputFile = new File(outputDirectory.path + '/' + caskFileName);
    return outputFile.create(recursive: true).then((file) {
      outputFile.writeAsString(cask);
      return null;
    });
  });
}

Future writeCaskWithCs(Directory outputDirectory, String caskClassName,
                       String caskFileName, http.Client client, String rootUrl,
                       String zipPath, String installSection, String notes) {
  String releaseVersionFileUrl = "${rootUrl}/latest/VERSION";
  String release_version, release_revision, base_url, url, md5FileUrl, md5, csMd5FileUrl, cs_md5, cs_url;
  bool isRawCsAvailable = false;

  return client.read(releaseVersionFileUrl).then((String body) {
    release_version = versionRegex.firstMatch(body).group(1);
    release_revision = revisionRegex.firstMatch(body).group(1);
    base_url = "${rootUrl}/${release_revision}";
    url = "${base_url}/${zipPath}";
    md5FileUrl = "${url}.md5sum";
    csMd5FileUrl = "${base_url}/dartium/content_shell-macos-ia32-release.zip.md5sum";

    return client.read(md5FileUrl);
  }).then((String body) {
    if (body == null) return null;
    md5 = md5Regex.firstMatch(body).group(1);

    return client.read(csMd5FileUrl);
  }).then((String body) {
    if (body == null) return null;
    cs_md5 = md5Regex.firstMatch(body).group(1);
    int revision = int.parse(release_revision);
    isRawCsAvailable = cs_md5 != "xml";

    if (isRawCsAvailable) {
      // Torn between using release_revision and release_version for cask version :/
      versionsFile.write("| ${caskClassName} | ${release_version} | ${release_revision} | [Zip](${url}) | [md5]($md5FileUrl) | ${notes} |\n");
      String cask = createDartEditorCask(caskClassName, url, release_revision, md5, isRawCsAvailable, installSection);
      File outputFile = new File(outputDirectory.path + '/' + caskFileName);
      return outputFile.create(recursive: true).then((file) {
        outputFile.writeAsString(cask);
        return null;
      });
    } else {
      revision--;
      return writeCaskWithCsRevision(revision, outputDirectory, caskClassName, caskFileName, client, rootUrl, zipPath, installSection, notes);
    }
  });
}

Future writeCaskWithCsRevision(int revision, Directory outputDirectory, String cask_class_name, String cask_file_name, http.Client client, String rootUrl, String zipPath, String installSection, String notes) {
  var releaseVersionFileUrl = "${rootUrl}/$revision/VERSION";
  String release_version, release_revision, base_url, url, md5FileUrl, md5, csMd5FileUrl, cs_md5, cs_url;
  bool isRawCsAvailable = false;

  return client.read(releaseVersionFileUrl).then((String body) {
    if (body == null || body == "" || body.startsWith("<?xml version='1.0' encoding='UTF-8'?><Error>", 0)) {
      // No version with this revision
      // Really gross way of doing recursion with futures.
      revision--;
      return writeCaskWithCsRevision(revision, outputDirectory, cask_class_name, cask_file_name, client, rootUrl, zipPath, installSection, notes);
    }

    release_version = versionRegex.firstMatch(body).group(1);
    release_revision = revisionRegex.firstMatch(body).group(1);
    base_url = "${rootUrl}/${release_revision}";
    url = "${base_url}/${zipPath}";
    md5FileUrl = "${url}.md5sum";
    csMd5FileUrl = "${base_url}/dartium/content_shell-macos-ia32-release.zip.md5sum";

    return client.read(md5FileUrl);
  })
  .then((String body) {
    if (body == null) return null;
    md5 = md5Regex.firstMatch(body).group(1);

    return client.read(csMd5FileUrl);
  })
  .then((String body) {
    if (body == null) return null;
    cs_md5 = md5Regex.firstMatch(body).group(1);

    isRawCsAvailable = cs_md5 != "xml";

    if (isRawCsAvailable) {
      // Torn between using release_revision and release_version for cask version :/
      versionsFile.write("| ${cask_class_name} | ${release_version} | ${release_revision} | [Zip](${url}) | [md5]($md5FileUrl) | ${notes} |\n");
      String cask = createDartEditorCask(cask_class_name, url, release_revision, md5, isRawCsAvailable, installSection);
      File outputFile = new File(outputDirectory.path + '/' + cask_file_name);
      return outputFile.create(recursive: true).then((file) {
        outputFile.writeAsString(cask);
        return null;
      });
    } else {
      revision--;
      return writeCaskWithCsRevision(revision, outputDirectory, cask_class_name, cask_file_name, client, rootUrl, zipPath, installSection, notes);
    }
  });
}

String createDartEditorCask(String class_name, String url, String version,
                            String md5, bool is_cs_available,
                            String installSection) {
  return '''require "formula"

class ${class_name} < Formula
  url "${url}"
  homepage "https://www.dartlang.org/tools/editor/"
  version "${version}"
  md5 "${md5}"

${installSection}
end
''';
}
