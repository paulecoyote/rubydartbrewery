import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';

const String ROOT_URL = "https://storage.googleapis.com/dart-archive/channels";
const String HOMEPAGE_URL = "https://www.dartlang.org/tools/editor/";

const String dart_install_section = '''
# conflicts_with 'dart', :because => 'installation of dart-dsk tools in path'
# conflicts_with 'dart-editor', :because => 'installation of dart-dsk tools in path'
  depends_on :arch => :x86_64

def shim_script target
    <<-EOS.undent
      #!/bin/bash
      export DART_SDK=#{prefix}/dart-sdk
      exec "#{target}" "\$@"
    EOS
  end

def install
    prefix.install Dir['*']

    items = Dir[prefix+'dart-sdk/bin/*'].select { |f| File.file? f }

    items.each do |item|
      name = File.basename item

      if name == 'dart'
        bin.install_symlink item
      else
        (bin+name).write shim_script(item)
      end
    end
  end

  def test
    mktemp do
      (Pathname.pwd+'sample.dart').write <<-EOS.undent
      import 'dart:io';
      void main(List<String> args) {
        if(args.length == 1 && args[0] == 'test message') {
          exit(0);
        } else {
          exit(1);
        }
      }
      EOS

      system "#{bin}/dart sample.dart 'test message'"
    end
  end''';

const String cs_install_section = '''
  conflicts_with 'dart', :because => 'installation of dart-dsk tools in path'
  conflicts_with 'dart-editor', :because => 'installation of dart-dsk tools in path'
  depends_on :arch => :x86_64

  def install
    prefix.install Dir['*']

      content_shell_path = prefix+'chromium/content_shell'
      (content_shell_path).install resource('content_shell')

      item = Dir["#{content_shell_path}/Content Shell.app/Contents/MacOS/Content Shell"]

      bin.install_symlink Hash[item, 'content_shell']
  end''';

final String dev_root_url = "${ROOT_URL}/dev/release";
final String raw_root_url = "${ROOT_URL}/be/raw";
final String stable_root_url = "${ROOT_URL}/stable/release";

final RegExp version_regex = new RegExp(r'\"version\"\s*:\s*\"([\w\.-]+)\"');
final RegExp revision_regex = new RegExp(r'\"revision\"\s*:\s*\"([\w\.-]+)\"');
final RegExp md5_regex = new RegExp(r'([\w]+)');
StringBuffer versions_file = new StringBuffer();

void main(List<String> arguments) {

  var parser = new ArgParser();
  parser.addOption('output-path', defaultsTo: './');

  var results = parser.parse(arguments);
  Directory outputDirectory = new Directory(results['output-path']);

  HttpClient client = new HttpClient();

  writeCask(outputDirectory, "DartEditorDev", "dart-editor-dev.rb", client, dev_root_url, "editor/darteditor-macos-x64.zip", '''
# conflicts_with 'dart-editor-edge', :because => 'installation of dart-dsk tools in path'
# conflicts_with 'dart-editor-edge-cs', :because => 'installation of dart-dsk tools in path'
# conflicts_with 'dart-editor-stable', :because => 'installation of dart-dsk tools in path'
''' + dart_install_section, "[Changes](https://storage.googleapis.com/dart-archive/channels/dev/release/latest/changelog.html)")
    .catchError((e) {
        print("DartEditorDev: ${e} ${e.stackTrace}");     // Finally, callback fires.
        exitCode = 2;
        return -1;
      })
    .then((_) => writeCask(outputDirectory, "DartEditorEdge", "dart-editor-edge.rb", client, raw_root_url, "editor/darteditor-macos-x64.zip",  '''
# conflicts_with 'dart-editor-dev', :because => 'installation of dart-dsk tools in path'
# conflicts_with 'dart-editor-edge-cs', :because => 'installation of dart-dsk tools in path'
# conflicts_with 'dart-editor-stable', :because => 'installation of dart-dsk tools in path'
        ''' + dart_install_section, "-"))
    .catchError((e) {
        print("DartEditorEdge: ${e} ${e.stackTrace}");     // Finally, callback fires.
        exitCode = 2;
        return -1;
      })
    .then((_) => writeCaskWithCs(outputDirectory, "DartEditorEdgeCs", "dart-editor-edge-cs.rb", client, raw_root_url, "editor/darteditor-macos-x64.zip",  '''
# conflicts_with 'dart-editor-dev', :because => 'installation of dart-dsk tools in path'
# conflicts_with 'dart-editor-edge', :because => 'installation of dart-dsk tools in path'
# conflicts_with 'dart-editor-stable', :because => 'installation of dart-dsk tools in path'
        ''' + dart_install_section, "-"))
    .catchError((e) {
        print("DartEditorEdgeCs: ${e} ${e.stackTrace}");     // Finally, callback fires.
        exitCode = 2;
        return -1;
      })
    .then((_) => writeCask(outputDirectory, "DartEditorStable", "dart-editor-stable.rb", client, stable_root_url, "editor/darteditor-macos-x64.zip",  '''
# conflicts_with 'dart-editor-dev', :because => 'installation of dart-dsk tools in path'
# conflicts_with 'dart-editor-edge', :because => 'installation of dart-dsk tools in path'
# conflicts_with 'dart-editor-edge-cs', :because => 'installation of dart-dsk tools in path'
        ''' + dart_install_section, "[Changes](https://storage.googleapis.com/dart-archive/channels/stable/release/latest/changelog.html)"))
    .catchError((e) {
        print("DartEditorStable: ${e} ${e.stackTrace}");     // Finally, callback fires.
        exitCode = 2;
        return -1;
      })
    .then((_) => writeCask(outputDirectory, "DartContentShellDev", "dart-content-shell-dev.rb", client, dev_root_url, "dartium/content_shell-macos-ia32-release.zip",  '''
# conflicts_with 'dart-content-shell-edge', :because => 'installation of dart-dsk tools in path'
# conflicts_with 'dart-content-shell-stable', :because => 'installation of dart-dsk tools in path'
        ''' + cs_install_section, "-"))
    .catchError((e) {
        print("DartContentShellDev: ${e} ${e.stackTrace}");     // Finally, callback fires.
        exitCode = 2;
        return -1;
      })
    .then((_) => writeCaskWithCs(outputDirectory, "DartContentShellEdge", "dart-content-shell-edge.rb", client, raw_root_url, "dartium/content_shell-macos-ia32-release.zip",  '''
# conflicts_with 'dart-content-shell-dev', :because => 'installation of dart-dsk tools in path'
# conflicts_with 'dart-content-shell-stable', :because => 'installation of dart-dsk tools in path'
        ''' + cs_install_section, "-"))
    .catchError((e) {
        print("DartContentShellEdge: ${e} ${e.stackTrace}");     // Finally, callback fires.
        exitCode = 2;
        return -1;
      })
    .then((_) => writeCask(outputDirectory, "DartContentShellStable", "dart-content-shell-stable.rb", client, stable_root_url, "dartium/content_shell-macos-ia32-release.zip",  '''
# conflicts_with 'dart-content-shell-dev', :because => 'installation of dart-dsk tools in path'
# conflicts_with 'dart-content-shell-edge', :because => 'installation of dart-dsk tools in path'
        ''' + cs_install_section, "-"))
    .catchError((e) {
        print("DartContentShellStable: ${e} ${e.stackTrace}");     // Finally, callback fires.
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
      String verBody = versions_file.toString();
      if (verBody != null && verBody != "")
        file.writeAsString(verBody, mode: FileMode.APPEND);
  });
}

Future writeCask(Directory outputDirectory, String caskClassName,
                 String caskFileName, HttpClient client, String rootUrl,
                 String zipPath, String installSection, String notes) {
  String release_version_file_url = "${rootUrl}/latest/VERSION";
  String release_version, release_revision, base_url, url, md5_file_url, md5, cs_md5_file_url, cs_md5, cs_url;
  bool isRawCsAvailable = false;

  return getAsString(Uri.parse(release_version_file_url), client)
      .then((String body) {
        release_version = version_regex.firstMatch(body).group(1);
        release_revision = revision_regex.firstMatch(body).group(1);
        base_url = "${rootUrl}/${release_revision}";
        url = "${base_url}/${zipPath}";
        md5_file_url = "${url}.md5sum";
        cs_md5_file_url = "${base_url}/dartium/content_shell-macos-ia32-release.zip.md5sum";

        return getAsString(Uri.parse(md5_file_url), client);
      })
      .then((String body) {
        if (body == null) return null;
        md5 = md5_regex.firstMatch(body).group(1);

        return getAsString(Uri.parse(cs_md5_file_url), client);
      })
      .then((String body) {
        if (body == null) return null;
        cs_md5 = md5_regex.firstMatch(body).group(1);

        isRawCsAvailable = cs_md5 != "xml";

        // Torn between using release_revision and release_version for cask version :/
        versions_file.write("| ${caskClassName} | ${release_version} | ${release_revision} | [Zip](${url}) | [md5]($md5_file_url) | ${notes} |\n");
        String cask = createDarteditorCask(caskClassName, url, release_revision, md5, isRawCsAvailable, installSection);
        File outputFile = new File(outputDirectory.path + '/' + caskFileName);
        return outputFile.create(recursive: true)
            .then((file) {
                            outputFile.writeAsString(cask);
                            return null;
                          });
      });
}

Future writeCaskWithCs(Directory outputDirectory, String caskClassName,
                       String caskFileName, HttpClient client, String rootUrl,
                       String zipPath, String installSection, String notes) {
  String release_version_file_url = "${rootUrl}/latest/VERSION";
  String release_version, release_revision, base_url, url, md5_file_url, md5, cs_md5_file_url, cs_md5, cs_url;
  bool isRawCsAvailable = false;

  return getAsString(Uri.parse(release_version_file_url), client)
      .then((String body) {
        release_version = version_regex.firstMatch(body).group(1);
        release_revision = revision_regex.firstMatch(body).group(1);
        base_url = "${rootUrl}/${release_revision}";
        url = "${base_url}/${zipPath}";
        md5_file_url = "${url}.md5sum";
        cs_md5_file_url = "${base_url}/dartium/content_shell-macos-ia32-release.zip.md5sum";

        return getAsString(Uri.parse(md5_file_url), client);
      })
      .then((String body) {
        if (body == null) return null;
        md5 = md5_regex.firstMatch(body).group(1);

        return getAsString(Uri.parse(cs_md5_file_url), client);
      })
      .then((String body) {
        if (body == null) return null;
        cs_md5 = md5_regex.firstMatch(body).group(1);
        int revision = int.parse(release_revision);
        isRawCsAvailable = cs_md5 != "xml";

        if (isRawCsAvailable)
        {
          // Torn between using release_revision and release_version for cask version :/
          versions_file.write("| ${caskClassName} | ${release_version} | ${release_revision} | [Zip](${url}) | [md5]($md5_file_url) | ${notes} |\n");
          String cask = createDarteditorCask(caskClassName, url, release_revision, md5, isRawCsAvailable, installSection);
          File outputFile = new File(outputDirectory.path + '/' + caskFileName);
          return outputFile.create(recursive: true)
            .then((file) {
            outputFile.writeAsString(cask);
            return null;
          });
        }
        else
        {
          revision--;
          return writeCaskWithCsRevision(revision, outputDirectory, caskClassName, caskFileName, client, rootUrl, zipPath, installSection, notes);
        }
      });
}

Future writeCaskWithCsRevision(int revision, Directory outputDirectory, String cask_class_name, String cask_file_name, HttpClient client, String rootUrl, String zipPath, String installSection, String notes)
{
  String release_version_file_url = "${rootUrl}/$revision/VERSION";
    String release_version, release_revision, base_url, url, md5_file_url, md5, cs_md5_file_url, cs_md5, cs_url;
    bool isRawCsAvailable = false;

  return getAsString(Uri.parse(release_version_file_url), client)
        .then((String body) {
          if (body == null || body == "" || body.startsWith("<?xml version='1.0' encoding='UTF-8'?><Error>", 0))
          {
            // No version with this revision
            // Really gross way of doing recursion with futures.
            revision--;
            return writeCaskWithCsRevision(revision, outputDirectory, cask_class_name, cask_file_name, client, rootUrl, zipPath, installSection, notes);
          }

          release_version = version_regex.firstMatch(body).group(1);
          release_revision = revision_regex.firstMatch(body).group(1);
          base_url = "${rootUrl}/${release_revision}";
          url = "${base_url}/${zipPath}";
          md5_file_url = "${url}.md5sum";
          cs_md5_file_url = "${base_url}/dartium/content_shell-macos-ia32-release.zip.md5sum";

          return getAsString(Uri.parse(md5_file_url), client);
        })
        .then((String body) {
          if (body == null) return null;
          md5 = md5_regex.firstMatch(body).group(1);

          return getAsString(Uri.parse(cs_md5_file_url), client);
        })
        .then((String body) {
          if (body == null) return null;
          cs_md5 = md5_regex.firstMatch(body).group(1);

          isRawCsAvailable = cs_md5 != "xml";

          if (isRawCsAvailable)
          {
            // Torn between using release_revision and release_version for cask version :/
            versions_file.write("| ${cask_class_name} | ${release_version} | ${release_revision} | [Zip](${url}) | [md5]($md5_file_url) | ${notes} |\n");
            String cask = createDarteditorCask(cask_class_name, url, release_revision, md5, isRawCsAvailable, installSection);
            File outputFile = new File(outputDirectory.path + '/' + cask_file_name);
            return outputFile.create(recursive: true)
              .then((file) {
                outputFile.writeAsString(cask);
                return null;
              });
          }
          else
          {
            revision--;
            return writeCaskWithCsRevision(revision, outputDirectory, cask_class_name, cask_file_name, client, rootUrl, zipPath, installSection, notes);
          }
        });
}

String createDarteditorCask(String class_name, String url, String version,
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

Future<String> getAsString(Uri uri, [HttpClient client = null]) {
  if (client == null) client = new HttpClient();
 return client.getUrl(uri)
     .then((HttpClientRequest request) => request.close())
     .then((HttpClientResponse resp) => resp.transform(UTF8.decoder).fold(new StringBuffer(), (buf, next) {
       buf.write(next);
       return buf;
     }))
     .then((StringBuffer buf) => buf.toString());
}
