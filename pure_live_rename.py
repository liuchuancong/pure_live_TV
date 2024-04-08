import os
import shutil
import time
source_dir_name = 'E:/project/pure_live_release/'
# target_win_app_name  = 'E:/project/pure_live/build/windows/x64/runner/Release/'
# target_apk_dir_name = 'E:/project/pure_live/build/app/outputs/flutter-apk/'
target_files = ['app-arm64-v8a-release.apk','app-armeabi-v7a-release.apk','app-release.apk','app-x86_64-release.apk','pure_live.msix']
build_path = []
buildcellctions = []
target_win_app_name = 'D:/flutter/pure_live/build/windows/x64/runner/Release/'
target_apk_dir_name = 'D:/flutter/pure_live/build/app/outputs/flutter-apk/'
files = []
dirArr = ['安卓_手机高版本.apk','安卓_手机低版本或电视.apk','不知道就下载这个.apk','模拟器.apk','win10以上系统下载.msix']
def traversal_dirs(path):
    for item in os.scandir(path):
        if item.is_dir():
            shutil.rmtree(item.path)
        else:
            os.remove(item.path)
            
def traversal_files(path):
    for item in os.scandir(path):
        if item.is_file():
            fileName = item.path.split('/')[-1].split('\\')[-1]
            if fileName in target_files:
                buildcellctions.append(item.path)
    
def traversal_target_files(path,version):
    if (len(buildcellctions)!=len(dirArr)):
      print('请全部打包')
      return
    for i in range(0,len(dirArr)):
            src = os.path.join(path,version + '-' +dirArr[i])
            source = buildcellctions[i]
            shutil.copy(source, src)
def zip_dirs(path):
    for file in os.listdir(path):
        file_path = os.path.join(path, file)
        if os.path.isdir(file_path):
           shutil.make_archive(file_path, 'zip', file_path)

def main():
        version = str(input("请输入你想发布的版本："))
        # 先改名字12
        traversal_dirs(source_dir_name)
        
        
        # 复制文件
        
        traversal_files(target_apk_dir_name)
        traversal_files(target_win_app_name)
        traversal_target_files(source_dir_name,version)
        # print(buildcellctions)
        # 压缩为zip
        # zip_dirs(source_dir_name)
        # 12
if __name__ == '__main__':
     main()