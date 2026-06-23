import os

def generate_dart_export(target_dir: str, output_name: str = "index.dart", recursive: bool = True):
    exports = []
    # 遍历目录
    for root, _, files in os.walk(target_dir):
        for file in files:
            if file.endswith(".dart") and file != output_name:
                # 相对路径，适配dart export语法
                rel_path = os.path.relpath(os.path.join(root, file), target_dir)
                rel_path = rel_path.replace(os.sep, "/")
                exports.append(f"export '{rel_path}';")
        # 不递归就跳出第一层
        if not recursive:
            break

    out_path = os.path.join(target_dir, output_name)
    content = "\n".join(exports)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"✅ 生成完成：{out_path}，共 {len(exports)} 条导出")

if __name__ == "__main__":
    # ========== 这里改你的目录 ==========
    target_folder = r"C:\Users\XA-158\projects\flutter\pure_live_TV\lib\utils"
    # ===================================
    generate_dart_export(target_dir=target_folder, recursive=True)