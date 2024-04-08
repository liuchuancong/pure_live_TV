import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/plugins/file_recover_utils.dart';
import 'package:pure_live/modules/auth/utils/constants.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  final settings = Get.find<SettingsService>();
  late String backupDirectory = settings.backupDirectory.value;
  late String m3uDirectory = settings.m3uDirectory.value;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          SectionTitle(title: S.of(context).backup_recover),
          ListTile(
            title: const Text('网络'),
            subtitle: const Text('导入M3u直播源'),
            onTap: () => showImportSetDialog(),
          ),
          ListTile(
            title: Text(S.of(context).create_backup),
            subtitle: Text(S.of(context).create_backup_subtitle),
            onTap: () async {
              final selectedDirectory = await FileRecoverUtils().createBackup(backupDirectory);
              if (selectedDirectory != null) {
                setState(() {
                  backupDirectory = selectedDirectory;
                });
              }
            },
          ),
          ListTile(
            title: Text(S.of(context).recover_backup),
            subtitle: Text(S.of(context).recover_backup_subtitle),
            onTap: () => FileRecoverUtils().recoverBackup(),
          ),
          SectionTitle(title: S.of(context).auto_backup),
          ListTile(
            title: Text(S.of(context).backup_directory),
            subtitle: Text(backupDirectory),
            onTap: () async {
              final selectedDirectory = await FileRecoverUtils().selectBackupDirectory(backupDirectory);
              if (selectedDirectory != null) {
                setState(() {
                  backupDirectory = selectedDirectory;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  void showImportSetDialog() {
    List<String> list = ["本地导入", "网络导入"];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('导入M3u直播源'),
          children: list.map<Widget>((name) {
            return RadioListTile<String>(
              activeColor: Theme.of(context).colorScheme.primary,
              groupValue: '',
              value: name,
              title: Text(name),
              onChanged: (value) {
                importFile(value!);
              },
            );
          }).toList(),
        );
      },
    );
  }

  Future<String?> showEditTextDialog() async {
    final TextEditingController urlEditingController = TextEditingController();
    final TextEditingController textEditingController = TextEditingController();
    var result = await Get.dialog(
        AlertDialog(
          title: const Text('请输入下载地址'),
          content: SizedBox(
            width: 400.0,
            height: 300.0,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: [
                  TextField(
                    controller: urlEditingController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      //prefixText: title,
                      contentPadding: EdgeInsets.all(12),
                      hintText: '下载地址',
                    ),
                    autofocus: true,
                  ),
                  spacer(12.0),
                  TextField(
                    controller: textEditingController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      //prefixText: title,
                      contentPadding: EdgeInsets.all(12),
                      hintText: '文件名',
                    ),
                    autofocus: false,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: Get.back,
              child: const Text("取消"),
            ),
            TextButton(
              onPressed: () async {
                if (urlEditingController.text.isEmpty) {
                  SmartDialog.showToast('请输入下载链接');
                  return;
                }
                bool validate = FileRecoverUtils.isUrl(urlEditingController.text);
                if (!validate) {
                  SmartDialog.showToast('请输入正确的下载链接');
                  return;
                }
                if (textEditingController.text.isEmpty) {
                  SmartDialog.showToast('请输入文件名');
                  return;
                }
                await FileRecoverUtils()
                    .recoverNetworkM3u8Backup(urlEditingController.text, textEditingController.text);
                Get.back();
              },
              child: const Text("确定"),
            ),
          ],
        ),
        barrierDismissible: false);
    return result;
  }

  importFile(String value) {
    if (value == '本地导入') {
      FileRecoverUtils().recoverM3u8Backup();
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pop(false);
      showEditTextDialog();
    }
  }
}
